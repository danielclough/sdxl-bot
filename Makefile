help:
	@echo "Make Commands:"
	@echo "make help\n\tThis menu"
	@echo "make up\n\tStart Docker or LXC"
	@echo "make down\n\tStop Docker or LXC"
	@echo "make clone\n\tClone Huggingface Repos"
	@echo "make nvidia-install\n\tInstall Nvidia"
	@echo "make lxc-build\n\tBuild Linux Container"
	@echo "make lxc-purge\n\tPurge LXD/LXD from system"
	@echo "make docker-install\n\tInstall Docker"
	@echo "make docker-nvidia-install\n\tInstall Nvidia Container Toolkit"
	@echo "make docker-build\n\tBuild Dockerfile and start container"
	@echo "make docker-purge\n\tPurge Docker From System"

up:
	@sh -c "[ -z \"$$(docker image ls | grep sdxl-bot-sdxl)\" ] \
		&& docker compose up -d \
		|| lxc exec sdxl --user 1000 -- bash -c \"cd /sdxl && /home/ubuntu/.nvm/versions/node/v18.17.1/bin/node /sdxl/index.js\""

down:
	@sh -c "[ -z \"$$(docker image ls | grep sdxl-bot-sdxl)\" ] \
		&& docker compose down \
		|| lxc stop sdxl"

clone:
	@sudo apt update && sudo apt upgrade -y
	@sudo apt install -y git git-lfs
	@read -p "Enter SDXL_HOME: (default: $$(pwd)): " SDXL_HOME \
		&& SDXL_HOME=$${SDXL_HOME:-$$(pwd)} \
		&& echo $$SDXL_HOME \
		&& cd $$SDXL_HOME/sdxl-bot \
		&& mkdir $$SDXL_HOME/sdxl-bot/images \
		&& mkdir $$SDXL_HOME/sdxl-bot/models/ && cd $$SDXL_HOME/sdxl-bot/models/ \
		&& git clone https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0 \
		&& git clone https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0


# Nvidia
nvidia-install:
	@sudo apt update && sudo apt upgrade -y && sudo apt install -y wget
	@wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
	@sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
	@wget https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda-repo-ubuntu2204-12-2-local_12.2.1-535.86.10-1_amd64.deb
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
	@read -p "Enter SDXL_HOME: (default: $$(pwd)): " SDXL_HOME \
		&& SDXL_HOME=$${SDXL_HOME:-$$(pwd)} \
		&& echo $$SDXL_HOME \
		&& lxc config device add sdxl disk disk \
    		path=/sdxl source=$$SDXL_HOME/sdxl-bot \
		&& sudo chown 1001000:1000 -R $$SDXL_HOME/sdxl-bot
	@lxc exec sdxl --user 1000 -- bash -c "sudo apt update && sudo apt upgrade -y"
	@lxc exec sdxl --user 1000 -- bash -c "sudo apt install -y python3 python3-pip python-is-python3"
	@lxc exec sdxl --user 1000 -- bash -c "pip install diffusers torch transformers accelerate"
	@lxc exec sdxl --user 1000 -- bash -c "echo 'export HOME=/home/ubuntu' >> ~/.bashrc"
	@lxc exec sdxl --user 1000 -- bash -c "export HOME=/home/ubuntu && wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash"
	@lxc exec sdxl --user 1000 -- bash -c ". /home/ubuntu/.nvm/nvm.sh  && nvm install 18 && nvm use 18"
	@lxc exec sdxl --user 1000 -- bash -c ". /home/ubuntu/.nvm/nvm.sh && cd /sdxl && npm i"
	@echo -e "\\nn\nExecute:\nlxc exec sdxl --user 1000 -- bash -c \"cd /sdxl && /home/ubuntu/.nvm/versions/node/v18.17.1/bin/node /sdxl/index.js\"\n"

lxc-purge:
	@sudo snap remove --purge lxd

# DOCKER
docker-install:
	# @sh -c "curl https://get.docker.com | sh && sudo systemctl --now enable docker"
	@sh -c "sudo apt update && sudo apt upgrade -y && sudo apt install -y  ca-certificates curl gnupg lsb-release"
	@sh -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
	@sh -c "echo \"deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $$(lsb_release -cs) stable\" \
		| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
	@sh -c "sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io"
	@sh -c "sudo usermod -aG docker $$USER"
	@echo "Install Complete"

docker-nvidia-install:
	@sh -c "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
		&& curl -s -L https://nvidia.github.io/libnvidia-container/ubuntu22.04/libnvidia-container.list \
		| sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
		| sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"
	@sh -c "sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit"
	@sudo nvidia-ctk runtime configure --runtime=docker
	@sudo systemctl restart docker
	@echo "Docker Restarted"
	@sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
	@nvidia-ctk --version
	@grep "  name:" /etc/cdi/nvidia.yaml

docker-build:
	@docker compose up --build

docker-purge:
	@sh -c "sudo apt -y purge `echo $$(dpkg -l | grep -i docker | tr -s " " | cut -f 2 -d " " | xargs)`"
	@sudo apt -y autoremove
	@sudo rm -fr /etc/docker
	@sudo systemctl stop docker
	@sudo systemctl disable docker
	@sudo rm /usr/share/keyrings/docker-archive-keyring.gpg
	# @sudo rm /usr/bin/docker*
	# @sudo rm /etc/apt/sources.list.d/docker.list
	@echo "Succsessful"