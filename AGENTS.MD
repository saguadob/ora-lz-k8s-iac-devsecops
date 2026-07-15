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
