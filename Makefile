help:
	@echo "Make Commands: \n  make clone\n  make lxc-init\n  make purge-docker"

clone:
	@sudo apt update && sudo apt upgrade -y
	@sudo apt install -y git git-lfs
	@GIT_HOME=$HOME/git \
		&& cd $GIT_HOME \
		&& git clone https://github.com/danielclough/sdxl-bot \
		&& cd $GIT_HOME/sdxl-bot \
		&& mkdir $GIT_HOME/sdxl-bot/images \
		&& mkdir $GIT_HOME/sdxl-bot/models/ && cd $GIT_HOME/sdxl-bot/models/ \
		&& git clone https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0 \
		&& git clone https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0

lxc-init:
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

docker:
	@docker compose up -d

docker-purge:
	@sudo apt -y purge `echo $(dpkg -l | grep -i docker | tr -s " " | cut -f 2 -d " " | xargs)
	@sudo apt autoremove
	@sudo rm -fr /etc/docker