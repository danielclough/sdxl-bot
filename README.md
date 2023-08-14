# SDXL Discord Bot

## Prerequisites

LXD is the app which controls LXC.

[Install LXD](https://ubuntu.com/lxd/install)

CUDA allows ML computation on Nvidia GPUs.

[Install CUDA and Toolkit](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html).

Check if CUDA works:

`nvidia-smi`

Check if Cuda Toolkit is installed:

`dpkg -l | grep cuda-toolkit`

## Create Discord App and Bot

### Discord Developer (Website)

Goto [https://discord.com/developers/applications](https://discord.com/developers/applications)
Click `New Application` (top right corner)
Create Bot

### ENV (local)

Copy `example.env` to `.env`
Copy `TOKEN` from Discord Developer into `.env`

Fill in the rest of the environment variables.

### Invite Bot to Server (Browser)

https://discord.com/api/oauth2/authorize?client_id=CLIENT_ID&permissions=8&scope=bot%20applications.commands

## Clone Repos (local)

```sh
# Update/Upgrade system
sudo apt update && sudo apt upgrade -y

# `git-lfs`` is required for HuggingFace repos!
sudo apt install -y git git-lfs

# Change this to where you keep your git files.
GIT_HOME=$HOME/git

cd $GIT_HOME

# Clone Project Repo
git clone https://github.com/danielclough/sdxl-bot
cd $GIT_HOME/sdxl-bot

# A place to put new images
mkdir $GIT_HOME/sdxl-bot/images

# Clone models from HuggingFace (very slow)
mkdir $GIT_HOME/sdxl-bot/models/ && cd $GIT_HOME/sdxl-bot/models/
git clone https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0
git clone https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0
```

## Linux Containers (LXC) for Security

> **You can skip this part if you are not worried about Malware in custom models.**
> Safetensor files have no "High Severity" issues and should always be preferred over pickle files. ([citation](https://huggingface.co/blog/safetensors-security-audit))

Read about the difference between LXC and Docker Security [here](https://earthly.dev/blog/lxc-vs-docker/#security).

### Setup

```sh
# CUDA-12.x and Toolkit must be installed on host!
lxc launch ubuntu:22.04 sdxl -c nvidia.runtime=true
lxc config device add sdxl gpu gpu

lxc config device set sdxl gpu uid 1000
lxc config device set sdxl gpu gid 1000

# confirm nvidia-smi is working
lxc exec sdxl -- nvidia-smi

# confirm CUDA is working
lxc file push /usr/local/cuda-12.1/extras/demo_suite/bandwidthTest sdxl/root/
lxc exec sdxl -- /root/bandwidthTest

# share dir
lxc config device add sdxl disk disk \
    path=/sdxl source=/home/$USER/git/sdxl-bot

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
# Check NVM Release and adjust if needed: https://github.com/nvm-sh/nvm/releases
sudo mkdir /.nvm && sudo chown 1000:1000 /.nvm
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash

cat << EOF >> ~/.bashrc
export NVM_DIR="/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
EOF

source ~/.bashrc
nvm install 18 && nvm use 18

npm i

exit
```

### Start Bot!

```sh
lxc exec sdxl --user 1000 -- bash -c "cd /sdxl && /.nvm/versions/node/v18.17.1/bin/node /sdxl/index.js"
```

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

## Learn More (Everyday)

[DiscordJS Guide](https://discordjs.guide/)

## Shout Out

Thanks to the [Blackcoin Community](https://discord.blackcoin.nl) for helping to fund the GPU that I used for this project!