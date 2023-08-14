# SDXL Discord Bot

## Create Discord App and Bot

### Discord Developer (Website)

Goto [https://discord.com/developers/applications](https://discord.com/developers/applications)
Click `New Application`
Create Bot

### ENV (local)

Copy `example.env` to `.env`
Copy `Name`, `CLIENT ID`, and `TOKEN` from Discord Developer into `.env`

### Invite Bot to Server (Browser)

https://discord.com/api/oauth2/authorize?client_id=`CLIENT_ID`&permissions=8&scope=bot%20applications.commands

> e.g.
> `https://discord.com/api/oauth2/authorize?client_id=932143312054411335&permissions=8&scope=bot%20applications.commands`

## Clone Repo (local)

```sh
cd ~
mkdir git && cd git

git clone https://github.com/danielclough/sdxl-bot
cd sdxl-bot


cd models
git clone https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0
git clone https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0
cd ..

```

## Linux Containers (LXC) for Security

> **You can skip this part if you are not worried about Malware in custom models.**
> Safetensor files have no "High Severity" issues and should always be preferred over pickle files. ([citation](https://huggingface.co/blog/safetensors-security-audit))

Read about the difference between LXC and Docker Security [here](https://earthly.dev/blog/lxc-vs-docker/#security).

### Prerequisites

LXD is the app which controls LXC.

[Install LXD](https://ubuntu.com/lxd/install)

CUDA allows ML computation on Nvidia GPUs.

[Install CUDA and Toolkit](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html).

### Setup

```sh
# CUDA-12.x and Toolkit must be installed on host!
lxc launch ubuntu:22.04 sdxl -c nvidia.runtime=true
lxc config device add sdxl gpu gpu

lxc config device set sdxl gpu uid 1000
lxc config device set sdxl gpu gid 1000

# confirm nvidia-smi is working
lxc exec sdxl -- nvidia-smi

# confirm cuda is working
lxc file push /usr/local/cuda-12.1/extras/demo_suite/bandwidthTest sdxl/root/
lxc exec sdxl -- /root/bandwidthTest

# share dir
lxc config device add sdxl disk disk \
    path=/sdxl source=/home/$USER/git/sdxl-bot

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
source ~/.bashrc
nvm install 18 && nvm use 18

npm i

exit
```

### Run

`lxc exec sdxl --user 1000 -- bash -c "cd /sdxl && /.nvm/versions/node/v18.17.1/bin/node /sdxl/index.js"`


## Learn More (Everyday)

[DiscordJS Guide](https://discordjs.guide/)

## Shout Out

Thanks to the [Blackcoin Community](https://discord.blackcoin.nl) for helping to fund the GPU that I used for this project!