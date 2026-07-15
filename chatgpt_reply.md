The most important Codex-specific file to create is **`AGENTS.md` at the repository root**. You do not need a large Codex scaffold before starting.

## Recommended repository structure

```text
your-project/
├── AGENTS.md                    # Codex/team instructions
├── README.md                    # Project overview and basic usage
├── CONTRIBUTING.md              # Human contribution workflow
├── .gitignore
├── .editorconfig
├── .env.example                 # Variable names only; no secrets
├── Makefile                     # Or Taskfile/package scripts
├── docs/
│   ├── architecture.md
│   └── development.md
├── .codex/
│   ├── config.toml              # Optional shared Codex settings
│   └── rules/
│       └── default.rules        # Optional; currently experimental
├── .agents/
│   └── skills/                  # Optional reusable project workflows
│       └── release/
│           └── SKILL.md
├── src/
├── tests/
└── language-specific files...
```

## What should be checked into version control

| File                               |                    Check in? | Purpose                                            |
| ---------------------------------- | ---------------------------: | -------------------------------------------------- |
| `AGENTS.md`                        |                      **Yes** | Persistent project instructions for Codex          |
| Nested `AGENTS.md`                 |             Yes, when needed | Package/service-specific instructions              |
| Nested `AGENTS.override.md`        | Yes, if intentionally shared | Replaces the normal instructions in that directory |
| `.codex/config.toml`               |                     Optional | Safe, project-specific Codex configuration         |
| `.codex/rules/*.rules`             |                     Optional | Command approval rules; currently experimental     |
| `.agents/skills/<skill>/SKILL.md`  |                     Optional | Reusable project workflows                         |
| `README.md`, `CONTRIBUTING.md`     |                          Yes | Project and contribution documentation             |
| Build, test and lint configuration |                      **Yes** | Makes validation deterministic                     |
| Dependency lockfiles               |                      **Yes** | Gives Codex reproducible dependency versions       |
| `.env.example`                     |                          Yes | Documents required variables without values        |
| `.env`, credentials and API keys   |                       **No** | Secrets must remain outside Git                    |
| `~/.codex/*`                       |                       **No** | Personal configuration and local Codex state       |

Codex reads repository guidance from the Git root down to the working directory. Instructions closer to the current directory take precedence. At each directory level, it checks `AGENTS.override.md` before `AGENTS.md`. ([ChatGPT Learn][1])

## 1. Create a useful `AGENTS.md`

Keep it short, concrete and executable. It should tell Codex how to work in the repository—not repeat the entire architecture documentation.

````markdown
# AGENTS.md

## Project overview

This repository contains <brief description>.

Important directories:

- `src/`: application source
- `tests/`: automated tests
- `docs/`: architecture and operational documentation
- `scripts/`: development and maintenance scripts

## Environment setup

Run:

```sh
make bootstrap
````

Do not install dependencies with a different package manager.

## Required validation

Before declaring a task complete, run:

```sh
make format-check
make lint
make typecheck
make test
```

For changes affecting the build or deployment configuration, also run:

```sh
make build
```

## Coding conventions

* Follow the existing module and naming structure.
* Prefer small, focused changes.
* Do not introduce a new production dependency unless the task requires it.
* Add or update tests whenever behavior changes.
* Do not suppress lint or type-checking errors without documenting the reason.

## Architecture constraints

* Domain logic must not import infrastructure implementations directly.
* Database access belongs under `src/repositories/`.
* Public API behavior must remain backward-compatible unless the task explicitly
  requires a breaking change.
* See `docs/architecture.md` for component boundaries.

## Security

* Never commit secrets, tokens, credentials or real customer data.
* Use environment variables for sensitive values.
* Do not weaken authentication, authorization or TLS validation to make tests pass.

## Definition of done

A change is complete only when:

1. The relevant tests pass.
2. Formatting, linting and type checks pass.
3. New behavior is covered by tests.
4. Documentation is updated when interfaces or operations change.
5. The final response summarizes changed files and validation performed.

````

OpenAI recommends putting build commands, test commands, review expectations and repository conventions in `AGENTS.md`, while keeping the file small and practical. :contentReference[oaicite:1]{index=1}

### For a monorepo

Use nested instruction files when different components have different commands:

```text
AGENTS.md
services/
├── billing/
│   └── AGENTS.md
├── identity/
│   └── AGENTS.md
└── frontend/
    └── AGENTS.md
````

The root file contains organization-wide rules. Each nested file contains only the differences for that component.

## 2. Provide deterministic commands

Codex performs best when it can run a small, obvious command set:

```sh
make bootstrap
make format
make lint
make typecheck
make test
make build
```

These can be implemented through a `Makefile`, `Taskfile.yml`, package-manager scripts, or equivalent tooling.

For example:

```makefile
.PHONY: bootstrap format format-check lint typecheck test build check

bootstrap:
	./scripts/bootstrap.sh

format:
	./scripts/format.sh

format-check:
	./scripts/format.sh --check

lint:
	./scripts/lint.sh

typecheck:
	./scripts/typecheck.sh

test:
	./scripts/test.sh

build:
	./scripts/build.sh

check: format-check lint typecheck test build
```

This is generally preferable to making Codex discover several unrelated commands across documentation and CI files.

For Codex cloud, common package managers can be installed automatically. Complex projects can use a cloud setup script; the checked-in project should still expose reproducible setup and validation commands. Codex cloud also uses `AGENTS.md` to locate project-specific lint and test commands. ([OpenAI Developers][2])

## 3. Project `.codex/config.toml`

A repository-level `.codex/config.toml` is **optional**. Codex supports it for settings that should apply to that repository or a subtree. Project configurations load only after the project is trusted. ([ChatGPT Learn][3])

Start without one unless you have an actual shared requirement.

Good candidates for checked-in configuration include:

* Project-specific MCP server definitions that contain no credentials
* Consistent sandbox or approval defaults
* Project instruction discovery settings
* Project hooks or other shared integrations

Avoid checking in:

* API tokens
* OAuth credentials
* Personal filesystem paths
* Personal model preferences
* Machine-specific executable locations
* Environment-specific credentials

I would also avoid pinning a model in the repository unless the project has a tested reason to require one. Model choice is normally better left in each developer’s `~/.codex/config.toml`.

Codex resolves CLI options first, then project `.codex/config.toml`, profile configuration, user configuration and system defaults. ([ChatGPT Learn][3])

## 4. Personal Codex files—not repository files

These belong on each developer’s machine:

```text
~/.codex/
├── AGENTS.md
├── config.toml
├── deep-review.config.toml
└── rules/
    └── default.rules
```

Typical use:

```markdown
# ~/.codex/AGENTS.md

- Use concise implementation summaries.
- Do not commit or push unless explicitly requested.
- Prefer reviewing the existing implementation before editing.
- Explain any validation that could not be run.
```

Use global instructions for personal behavior and communication preferences. Use repository `AGENTS.md` for rules that all contributors and Codex sessions should follow. OpenAI explicitly separates global developer guidance from checked-in repository guidance. ([OpenAI Developers][4])

## 5. Optional `.codex/rules`

Rules control commands that Codex may execute outside its sandbox. Project rules live under:

```text
.codex/rules/*.rules
```

For example:

```python
prefix_rule(
    pattern = ["terraform", "apply"],
    decision = "forbidden",
    justification = "Infrastructure changes must be applied manually.",
)

prefix_rule(
    pattern = ["kubectl", "delete"],
    decision = "forbidden",
    justification = "Destructive cluster operations are not delegated.",
)
```

Project-local rules are loaded only for trusted projects. OpenAI currently labels rules as experimental, so they should complement—not replace—CI controls, permissions and code-review policies. ([ChatGPT Learn][5])

## 6. Optional project skills

Use a skill when your repository has a repeatable multi-step workflow that is too detailed for `AGENTS.md`, such as:

* Creating database migrations
* Preparing a release
* Updating generated API clients
* Reviewing Terraform changes
* Producing deployment manifests
* Running a prescribed security review

Store project skills here:

```text
.agents/skills/<skill-name>/SKILL.md
```

Example:

```markdown
---
name: database-migration
description: Create and validate a database migration for this project.
---

1. Read `docs/database-migrations.md`.
2. Generate the migration using `make migration name=<name>`.
3. Never edit an already-applied migration.
4. Run `make database-reset`.
5. Run the repository test suite.
6. Report the upgrade and rollback behavior.
```

Repository skills under `.agents/skills` can be checked in and shared with the team. Codex initially reads their metadata and loads the full instructions when the workflow is relevant. ([OpenAI Developers][4])

## Non-Codex files that materially improve results

Before delegating substantial work, I recommend having these in place:

* **A lockfile:** `package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`, `uv.lock`, `Cargo.lock`, and so on.
* **A runtime-version file:** `.python-version`, `.nvmrc`, `.tool-versions`, or an equivalent.
* **Formatter configuration:** Prettier, Ruff, Black, gofmt expectations, rustfmt, etc.
* **Lint and type-check configuration:** ESLint, Ruff, mypy, Pyright, Clippy, golangci-lint, etc.
* **A test command:** preferably one top-level command.
* **CI configuration:** validating the same commands Codex is instructed to run.
* **`.env.example`:** variable names and harmless example values.
* **Architecture boundaries:** a concise `docs/architecture.md`.
* **Bootstrap automation:** `scripts/bootstrap.sh`, `Makefile`, container setup or devcontainer configuration.

Codex should not be asked to infer conventions that can be encoded in formatters, linters, type checkers, tests and CI. OpenAI similarly recommends pairing `AGENTS.md` guidance with enforceable infrastructure such as pre-commit hooks, linters and type checkers. ([OpenAI Developers][4])

## Recommended `.gitignore` policy

Your `.gitignore` should exclude secrets and generated state, but it should **not** ignore the shared Codex files.

```gitignore
# Secrets
.env
.env.*
!.env.example
*.pem
*.key

# Local dependencies and environments
node_modules/
.venv/
venv/

# Build and test output
dist/
build/
coverage/
.pytest_cache/
.mypy_cache/
.ruff_cache/
__pycache__/

# Local logs and temporary files
*.log
tmp/
.cache/

# Editor-local settings
.idea/
.vscode/*
!.vscode/extensions.json
!.vscode/settings.json
```

Do not add these to `.gitignore` when they are team-owned:

```text
AGENTS.md
.codex/config.toml
.codex/rules/
.agents/skills/
```

## Minimum viable setup

For an existing project, create these first:

```text
AGENTS.md
README.md
.gitignore
.env.example
Makefile or equivalent command runner
formatter/linter/test configuration
dependency lockfile
```

Then start Codex with a read-only orientation task:

```text
Read AGENTS.md and README.md. Inspect the repository without modifying files.
Report:

1. The architecture you infer.
2. The setup, build, lint, type-check and test commands.
3. Any contradictions or missing instructions.
4. Files that should be added or corrected before implementation work begins.
```

You can verify instruction discovery with:

```sh
codex --ask-for-approval never "Summarize the current instructions."
```

OpenAI documents this as a way to confirm which global and project instructions Codex loaded. ([ChatGPT Learn][1])

The practical rule is: **check in project knowledge and enforceable conventions; keep identity, credentials, personal preferences and local Codex state outside the repository.**

[1]: https://learn.chatgpt.com/codex/agent-configuration/agents-md "
  Custom instructions with AGENTS.md | ChatGPT Learn
"
[2]: https://developers.openai.com/codex/cloud/environments.md?utm_source=chatgpt.com "developers.openai.com"
[3]: https://learn.chatgpt.com/codex/config-file/config-basic "
  Config basics | ChatGPT Learn
"
[4]: https://developers.openai.com/codex/concepts/customization "
  Customization | ChatGPT Learn
"
[5]: https://learn.chatgpt.com/codex/agent-configuration/rules "
  Rules | ChatGPT Learn
"
