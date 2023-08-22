# SDXL Discord Bot

## Prerequisites

### GNU Make (optional)

If you want to use `make`

```sh
sudo apt install -y make

# Read Help
make help
```

### Cuda + Cuda Toolkit

Cuda allows ML computation on Nvidia GPUs.

[Install Cuda and Toolkit](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html).

<details>

<summary>Example Install on Ubuntu 22.04</summary>

The following comes from from [this link](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_local).

Same as `make nvidia-install` (other than md5 sum check)

```sh
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb

# This code not included in link above! 
# It checks the md5sum of .deb file against record on website.
[ $(echo `curl https://developer.download.nvidia.com/compute/cuda/12.2.1/docs/sidebar/md5sum.txt | grep cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb | cut -d " " -f 1`) = $(echo `md5sum cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb | cut -f1 -d " "`) ] \
  && echo 'F#ck Yeah! MD5SUM Matches!' || echo 'F#ckd Up! MD5SUM not matching!'

# cont. code from link above
sudo dpkg -i cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2204-12-2-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda
```

Check if Cuda works:

`nvidia-smi`

Check if Cuda Toolkit is installed:

`dpkg -l | grep cuda-toolkit`

</details>

### LXC vs Docker

> Read about the difference between LXC and Docker Security [here](https://earthly.dev/blog/lxc-vs-docker/#security).

<details>

<summary>Install Linux Containers</summary>

#### LXD / LXC

> LXD is the app which controls LXC.

[Install LXD](https://ubuntu.com/lxd/install)

`lxc --version`

</details>

<details>

<summary>Install Docker</summary>

#### Docker

[Install Docker](https://docs.docker.com/get-docker/)

##### Example Install

Same as `make docker-install`

```sh
sudo apt update && sudo apt upgrade -y && sudo apt install -y  \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg \
    --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Install Docker repo
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io

#  Modify user group.
sudo usermod -aG docker $USER
```

#### Nvidia Container Toolkit

Same as `make docker-nvidia-install`

```sh
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update \
    && sudo apt-get install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker

sudo systemctl restart docker

# test nvidia-smi in docker
docker run --rm --runtime=nvidia --gpus all nvidia/cuda:12.2.0-base-ubuntu20.04 nvidia-smi
```

</details>


## Clone Repos (local)

Same as `make clone` (other than sdxl-bot repo clone)

```sh
# Update/Upgrade system
sudo apt update && sudo apt upgrade -y

# `git-lfs`` is required for HuggingFace repos!
sudo apt install -y git git-lfs

# Change this to where you keep your git files.
GIT_HOME=$HOME/git

cd $GIT_HOME

# Clone Project Repo (not included in make)
git clone https://github.com/danielclough/sdxl-bot
cd $GIT_HOME/sdxl-bot

# A place to put new images
mkdir $GIT_HOME/sdxl-bot/images

# Clone models from HuggingFace (very slow)
mkdir $GIT_HOME/sdxl-bot/models/ && cd $GIT_HOME/sdxl-bot/models/
git clone https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0
git clone https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0
```

## Create Discord App and Bot

### Discord Developer (Website)

Goto [https://discord.com/developers/applications](https://discord.com/developers/applications)

Click `New Application` (top right corner)

Create Bot

### Invite Bot to Server (Browser)

`https://discord.com/api/oauth2/authorize?client_id=CLIENT_ID&permissions=8&scope=bot%20applications.commands`

### ENV (local)

Copy `example.env` to `.env`

Copy `TOKEN` from Discord Developer into `.env`

Fill in the rest of the environment variables.

### Setup and Run

<details>

<summary>LXC</summary>

#### Setup

Same as `make lxc-build`

```sh
# Cuda-12.x and Toolkit must be installed on host!
lxc launch ubuntu:22.04 sdxl -c nvidia.runtime=true
lxc config device add sdxl gpu gpu

lxc config device set sdxl gpu uid 1000
lxc config device set sdxl gpu gid 1000

# confirm nvidia-smi is working
lxc exec sdxl -- nvidia-smi

# confirm Cuda is working
lxc file push /usr/local/cuda-12.2/extras/demo_suite/bandwidthTest sdxl/root/
lxc exec sdxl -- /root/bandwidthTest

# share dir
lxc config device add sdxl disk disk \
    path=/sdxl source=$GIT_HOME/sdxl-bot

# Change Ownership to share files between Host and LXC
# 1001000 for LXD installed w/ snap - 101000 for LXD installed w/ apt
sudo chown 1001000:1000 -R $GIT_HOME/sdxl-bot

# Enter Container
lxc exec sdxl --user 1000 bash
```

```sh
# Install Python Dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-pip python-is-python3
pip install diffusers torch transformers accelerate

# Install Javascript Dependencies

# Export HOME as ~ for script
cat << EOF >> ~/.bashrc
export HOME=~
EOF

# source changes to .bashrc
source ~/.bashrc

# Check NVM Release and adjust if needed: https://github.com/nvm-sh/nvm/releases
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash

# source changes to .bashrc
source ~/.bashrc

# install and use 18
nvm install 18 && nvm use 18

# install package.json and node_modules
npm i

exit
```

#### Start Bot!

```sh
lxc exec sdxl --user 1000 -- bash -c "cd /sdxl && /home/ubuntu/.nvm/versions/node/v18.17.1/bin/node /sdxl/index.js"
```

Or, launch from `make up`

</details>


<details>

<summary>Docker</summary>

#### Setup and Run!

`docker-compose up`

Or, launch from `make up`

</details>


### Bonus (Backup with Rsync)

```sh
# Configure `backupLocation` by adding your Host in `~/.ssh/config`

Host backupLocation
  HostName <yourdomain.tld OR ip (e.g. 8.8.8.8)>
  User username
  IdentityFile ~/.ssh/id_ed25519

```

```sh
sudo apt install rsync
rsync -avh $GIT_HOME/sdxl-bot/images backupLocation:/some_dir/
```

## Troubleshooting

### Purge Docker

LXC and Docker don't play well together...

Same as `make docker-purge`

```sh
sudo apt -y purge `echo $(dpkg -l | grep -i docker | tr -s " " | cut -f 2 -d " " | xargs)
sudo apt autoremove
sudo rm -fr /etc/docker
```

## Learn More (Everyday)

> **You can skip this part if you are not worried about Malware in custom models.**
> Safetensor files have no "High Severity" issues and should always be preferred over pickle files. ([citation](https://huggingface.co/blog/safetensors-security-audit))

[DiscordJS Guide](https://discordjs.guide/)

## Shout Out

Thanks to the [Blackcoin Community](https://discord.blackcoin.nl) for donating towards the GPU that I used for this project!
