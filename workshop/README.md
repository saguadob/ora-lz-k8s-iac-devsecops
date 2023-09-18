# 1. :man_teacher: :woman_teacher: Intro & _Pitch_ of OCI :o2: :cloud: and its differenciators
<!-- This part is meant to be presented orally by one of the instructors -->
Let's hear from one of your instructors Oracle Cloud Journey :o2: :cloud: :compass:
- [Top 10 Reasons to Adopt Oracle Cloud](https://www.oracle.com/a/ocom/docs/oracle-cloud-infrastructure-ten-reasons.pdf)
- [Off-box virtualization](https://www.oracle.com/uk/security/cloud-security/isolated-network-virtualization/#isolate)
- [Flexible Compute Shapes](https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm)
- [Friendly pricing](https://www.oracle.com/cloud/economics/#pricing-features)

## 2. :tv: OKE Use case and discussions
We are going to watch Trygg's improvement using OKE
#TODO

## 3. :man_technologist: :woman_technologist: Hands-on Go-through
Let's simulate the journey of a team that is going to deploy a workload in a [Greenfield project](https://en.wikipedia.org/wiki/Greenfield_project) :national_park:.

### Preparing your work surface :toolbox: 
1. In your web browser open the following websites:
    - :o2: :cloud: [OCI Cloud Shell](https://cloud.oracle.com/?bdcstate=maximized&cloudshell=true)
    - :octocat: This repo in [Github](https://github.com/saguadob/ora-lz-k8s-iac-devsecops)
2. Pin them in your browser for ease of use `↖ right click -> Pin tab`
3. Setting up an ephemeral workspace
    - More advanced tools
        - Github Codespaces
        - GitPod
        - Dev Containers
    - Explore the [OCI Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm) and [how to use it](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellgettingstarted.htm)  
      ```sh
      # See what OCI related variables are available in the cloud shell
      env | grep 'OCI_'
      ```
    - Install and configure the [:octocat: Github CLI](https://cli.github.com/)(GH CLI) in the cloud shell using this :page_with_curl: [script in Gist](https://gist.github.com/saguadob/a8588a6f95b69e7085bba31d6d82d626)
      ```sh
      source <(curl -fsSL "https://gist.githubusercontent.com/saguadob/a8588a6f95b69e7085bba31d6d82d626/raw/configure-gh-in-oci-shell.sh")
      ```
      Let's analyze the script:
      ```sh
      #!/bin/sh
      ghcli_version="2.32.1"
      os_arch="linux_386"

      if (command gh);
      then 
          echo "GH CLI already installed ✅";
      else 
          echo "GH CLI not found 🚫  Downloading"; 
          #Download and install GH CLI
          wget "https://github.com/cli/cli/releases/download/v${ghcli_version}/gh_${ghcli_version}_${os_arch}.tar.gz" -O /usr/tmp/gh.tar.gz
          mkdir -p /usr/tmp/gh && tar xf /usr/tmp/gh.tar.gz -C /usr/tmp/gh --strip-components 1 --overwrite
          mkdir -p ~/tools && mv -n /usr/tmp/gh ~/tools/gh
          grep -qxF 'export PATH="$HOME/tools/gh/bin/:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/tools/gh/bin/:$PATH"' >> ~/.bashrc
          export PATH="$HOME/tools/gh/bin/:$PATH"
          echo "GH CLI installed ✅"
      fi
      ```
    - After installing the CLI, let's authenticate to Github
        - Run the command below and go through the authorization flow:
          ```sh
          gh auth login -s user -h github.com -p https -w
          ```
        - If you don't like the scopes asked by the CLI, you can create your own token and use it with this command
          ```sh
          # Authenticate against github.com by reading the token from a file
          $ gh auth login -h github.com -p https --with-token < mytoken.txt
          ```
    - Configure your working directory in git
      ```sh
      gh repo fork saguadob/ora-lz-k8s-iac-devsecops --fork-name ora-lz-k8s-iac-devsecops --clone --remote=true --remote-name=origin
      cd ora-lz-k8s-iac-devsecops

      git config user.name "$(gh api user -q .login)"
      git config user.email "$(gh api user/public_emails -q first.email)"
      gh repo set-default "$(gh api user -q .login)/ora-lz-k8s-iac-devsecops"
      git remote rm upstream
      ```
    - Configure your OCI variables.
      ```sh
      echo $OCI_CS_USER_OCID
      ```
      If the value is different from the format `ocid1.user.oc1..xyz` the go to the OCI Cloud Console and copy the value from `Upper right corner :bust_in_silhouette: -> Your profile -> OCID -> Copy`, and set it in your Cloud Shell profile
      ```sh
      echo 'export OCI_CLI_USER="<your-ocid>"' >> ~/.bashrc
      export OCI_CLI_USER="<your-ocid>"
      ```
    