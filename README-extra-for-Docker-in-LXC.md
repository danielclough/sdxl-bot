# Docker in LXC
```sh
lxc profile create nvidia

cat << EOF | lxc profile edit nvidia
config:
  nvidia.driver.capabilities: all
  nvidia.runtime: "true"
description: ""
devices:
  mygpu:
    type: gpu
name: nvidia
used_by: []
EOF

lxc launch ubuntu:22.04 docker --profile default --profile nvidia
lxc config device add docker gpu gpu
lxc config device add docker docker-var disk pool=docker-usb source=docker path=/var/lib/docker

### Doesn't help
# lxc config device add docker nvidia-proc disk pool=docker-usb source=docker path=/proc/driver/nvidia/gpus/0000:01:00.0:

lxc config set docker security.nesting=true security.syscalls.intercept.mknod=true security.syscalls.intercept.setxattr=true

lxc config device add docker disk disk path=/docker source=/docker
sleep 3
export alias lxcdock=lxc exec docker  -- sudo --user ubuntu --login -- 


lxcdock git clone -b progress https://github.com/danielclough/sdxl-bot.git

lxcdock sudo apt -y install make

lxcdock sh -c "cd sdxl-bot \
    make docker-install \
    make docker-nvidia-install \
    sudo sed -i 's/^#no-cgroups = false/no-cgroups = true/;' /etc/nvidia-container-runtime/config.toml \
    make docker-build"
```

Error:
```sh
Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: error running hook #0: error running hook: exit status 1, stdout: , stderr: Auto-detected mode as 'legacy'
nvidia-container-cli: mount error: stat failed: /proc/driver/nvidia/gpus/0000:01:00.0: no such file or directory: unknown
```