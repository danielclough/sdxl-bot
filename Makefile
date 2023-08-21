help:
	@echo "Make Commands: \n  make clone\n  make lxc-build\n  make docker-build\n  make docker-purge"

clone:
	@sudo apt update && sudo apt upgrade -y
	@sudo apt install -y git git-lfs
	@GIT_HOME=$HOME/git \
		&& cd $GIT_HOME/sdxl-bot \
		&& mkdir $GIT_HOME/sdxl-bot/images \
		&& mkdir $GIT_HOME/sdxl-bot/models/ && cd $GIT_HOME/sdxl-bot/models/ \
		&& git clone https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0 \
		&& git clone https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0


# Nvidia
nvidia-install:
	@sh -c "sudo apt update && sudo apt upgrade -y && sudo apt install -y wget"
	@wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
	@sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
	@wget https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb
	@sh -c "[ $(echo `curl https://developer.download.nvidia.com/compute/cuda/12.2.1/docs/sidebar/md5sum.txt | grep cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb | cut -d ' ' -f 1`) = $(echo `md5sum cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb | cut -f1 -d '' '`) ] && echo 'F#ck Yeah! MD5SUM Matches!' || echo 'F#ckd Up! MD5SUM not matching!';"
	@sudo dpkg -i cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb
	@sudo cp /var/cuda-repo-ubuntu2204-12-2-local/cuda-*-keyring.gpg /usr/share/keyrings/
	@sudo apt-get update
	@sudo apt-get -y install cuda


# LXC
lxc-build:
	@lxc launch ubuntu:22.04 sdxl -c nvidia.runtime=true \
		&& lxc config device add sdxl gpu gpu \
		&& lxc config device set sdxl gpu uid 1000 \
		&& lxc config device set sdxl gpu gid 1000
	
	@read -p "Enter GIT_HOME: " GIT_HOME \
		&& lxc config device add sdxl disk disk \
    		path=/sdxl source=$$GIT_HOME/sdxl-bot \
		&& sudo chown 1001000:1000 -R $$GIT_HOME/sdxl-bot
	@lxc exec sdxl --user 1000 -- bash -c "sudo apt update && sudo apt upgrade -y"
	@lxc exec sdxl --user 1000 -- bash -c "sudo apt install -y python3 python3-pip python-is-python3"
	@lxc exec sdxl --user 1000 -- bash -c "pip install diffusers torch transformers accelerate"
	@lxc exec sdxl --user 1000 -- bash -c "echo 'export HOME=/home/ubuntu' >> ~/.bashrc"
	@lxc exec sdxl --user 1000 -- bash -c "export HOME=/home/ubuntu && wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash"
	@lxc exec sdxl --user 1000 -- bash -c ". /home/ubuntu/.nvm/nvm.sh  && nvm install 18 && nvm use 18"
	@lxc exec sdxl --user 1000 -- bash -c ". /home/ubuntu/.nvm/nvm.sh && cd /sdxl && npm i"
	@echo -e "\n\nExecute:\nlxc exec sdxl --user 1000 -- bash -c \"cd /sdxl && /home/ubuntu/.nvm/versions/node/v18.17.1/bin/node /sdxl/index.js\"\n"


# DOCKER
docker-install:
	@sh -c "curl https://get.docker.com | sh && sudo systemctl --now enable docker"
	sh -c "sudo usermod -aG docker $$USER"
	@echo "Exiting to begin a new session..."
	@sleep 3
	@exit

docker-nvidia-install:
	@sh -c "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/ubuntu22.04/libnvidia-container.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"
	@sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit 
	@sudo nvidia-ctk runtime configure --runtime=docker
	@sudo systemctl restart docker
	@echo "Docker Restarted"
	@sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
	@nvidia-ctk --version
	@grep "  name:" /etc/cdi/nvidia.yaml

docker-build:
	@docker compose up -d --build

docker-purge:
	@sudo apt -y purge `echo $(dpkg -l | grep -i docker | tr -s " " | cut -f 2 -d " " | xargs)
	@sudo apt autoremove
	@sudo rm -fr /etc/docker