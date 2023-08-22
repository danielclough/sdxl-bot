If you are using the `Server Edition` of Ubuntu skip this step:

At login screen (with monitor + keyboard plugged in): `Ctrl` + `Alt` + `F1` to enter `tty1`

```sh
# Login

# After Login
sudo apt update && sudo apt -y upgrade

# [Learn more about the openssh server](https://ubuntu.com/server/docs/service-openssh)
sudo apt -y install openssh-server
sudo systemctl restart sshd.service

exit
```

Find your server IP Address from your router and use that in place of `remote` below.

On Client (primary computer):
```sh
# use defaults (no password)
ssh-keygen -t ed25519 -C "homeserver"
# copy to remote
ssh-copy-id -o PreferredAuthentications=password -o PubkeyAuthentication=no $USER@remote
# log in to remote
ssh $USER@remote
```

Now, On Remote:
```sh
# remove any keys you don't want on remote
vi ~/.ssh/authorized_keys

# Clean up apt
sudo apt -y autoremove

# Do not boot to graphical target.
# [Learn more about startup targets](https://www.redhat.com/sysadmin/configure-systemd-startup-targets)
sudo systemctl isolate multi-user.target
sudo systemctl set-default multi-user.target

# Blacklist Nouveau opensource driver
echo '
blacklist amd76x_edac #this might not be required for x86 32 bit users.
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv' | sudo tee /etc/modprobe.d/blacklist.conf

sudo reboot -h now
```

Log back into Remote with `ssh $USER@remote`
```sh

# Check for latest and adjust
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2204-12-2-local/cuda-*-keyring.gpg /usr/share/keyrings/

# sudo ubuntu-drivers autoinstall
sudo reboot -h now
```

Log back into Remote with `ssh $USER@remote`
```sh

sudo apt-get update

# I found that installing toolkit first avoids errors
sudo apt-get -y install nvidia-cuda-toolkit
sudo apt-get -y install cuda

# Confirm Installation
/usr/local/cuda-12.2/bin/nvcc -V

sudo reboot -h now
```

Log back into Remote with `ssh $USER@remote`
```sh
sudo snap install lxd

# init with BTRS
lxd init
# Would you like to use LXD clustering? (yes/no) [default=no]: 
# Do you want to configure a new storage pool? (yes/no) [default=yes]: 
# Name of the new storage pool [default=default]: 
# Name of the storage backend to use (lvm, zfs, btrfs, ceph, dir) [default=zfs]: btrfs
# Create a new BTRFS pool? (yes/no) [default=yes]: 
# Would you like to use an existing empty block device (e.g. a disk or partition)? (yes/no) [default=no]: 
# Size in GiB of the new loop device (1GiB minimum) [default=30GiB]: 300
# Would you like to connect to a MAAS server? (yes/no) [default=no]: 
# Would you like to create a new local network bridge? (yes/no) [default=yes]: 
# What should the new bridge be called? [default=lxdbr0]: 
# What IPv4 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: 
# What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: 
# Would you like the LXD server to be available over the network? (yes/no) [default=no]: 
# Would you like stale cached images to be updated automatically? (yes/no) [default=yes]: 

# Launch and configure for Cuda
lxc launch ubuntu:22.04 docker-cuda -c nvidia.runtime=true
lxc config device add docker-cuda gpu gpu
# test
lxc exec docker-cuda -- nvidia-smi
# Install Nvidia on container
lxc exec docker-cuda -- bash -c "wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin"
lxc exec docker-cuda -- bash -c "sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600"
lxc exec docker-cuda -- bash -c "wget https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb"
lxc exec docker-cuda -- bash -c "sudo dpkg -i cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb"
lxc exec docker-cuda -- bash -c "sudo cp /var/cuda-repo-ubuntu2204-12-2-local/cuda-*-keyring.gpg /usr/share/keyrings/"

# Install Docker on Container
lxc storage volume create default docker-cuda
lxc config device add docker-cuda docker disk pool=default source=docker-cuda path=/var/lib/docker
lxc config device add docker-cuda nvidia disk source=/proc/driver/nvidia path=/proc/driver/nvidia


lxc config set docker-cuda security.nesting=true security.syscalls.intercept.mknod=true security.syscalls.intercept.setxattr=true

lxc restart docker-cuda

lxc exec docker-cuda -- bash -c "sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get install ca-certificates curl gnupg lsb-release"

lxc exec docker-cuda -- bash -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"

lxc exec docker-cuda -- bash -c "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"

lxc exec docker-cuda -- bash -c "sudo apt-get update"
lxc exec docker-cuda -- bash -c "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"

# Nvidia Container Toolkit
lxc exec docker-cuda -- bash -c "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/ubuntu22.04/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"

lxc exec docker-cuda -- bash -c "sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit"

lxc exec docker-cuda -- bash -c "sudo nvidia-ctk runtime configure --runtime=docker"

lxc exec docker-cuda -- bash -c "sudo systemctl restart docker"

lxc exec docker-cuda -- bash -c "sed -i 's/    }/    },\\n\"exec-opts\": [\"native.cgroupdriver=cgroupfs\"]/' /etc/docker/daemon.json"

lxc exec docker-cuda -- bash -c "cat /etc/docker/daemon.json"

lxc exec docker-cuda -- bash -c "sed -i 's/#no-cgroups = false/no-cgroups = true/' /etc/nvidia-container-runtime/config.toml"

lxc exec docker-cuda -- bash -c "sudo systemctl restart docker"

# test nvidia-smi in docker
lxc exec docker-cuda -- bash -c "docker run --rm --runtime=nvidia --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi"
```