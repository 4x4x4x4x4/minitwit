# -*- mode: ruby -*-
# vi: set ft=ruby :

$ip_file = "db_ip.txt"

Vagrant.configure("2") do |config|
  config.vm.box = "digital_ocean"
  config.vm.box_url = "https://github.com/devopsgroup-io/vagrant-digitalocean/raw/master/box/digital_ocean.box"
  config.ssh.private_key_path = "~/.ssh/id_rsa"
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  #########################
  # Database Server Setup #
  #########################
  config.vm.define "dbserver", primary: true do |db|
    db.vm.provider :digital_ocean do |provider|
      provider.ssh_key_name = ENV["SSH_KEY_NAME"]
      provider.token = ENV["DIGITAL_OCEAN_TOKEN"]
      provider.image = "ubuntu-22-04-x64"
      provider.region = "nyc3"
      provider.size = "s-1vcpu-1gb"
      provider.privatenetworking = true
    end

    db.vm.hostname = "dbserver"

    db.trigger.after :up do |trigger|
      trigger.info = "Writing dbserver's IP to file..."
      trigger.ruby do |env, machine|
        remote_ip = machine.instance_variable_get(:@communicator).instance_variable_get(:@connection_ssh_info)[:host]
        File.write($ip_file, remote_ip)
      end
    end

    db.vm.provision "shell", inline: <<-SHELL
      while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
        echo "Waiting for dpkg lock to be released..."
        sleep 5
      done
      sudo apt-get update -y
      sudo apt-get install -y sqlite3 libsqlite3-dev
      echo "SQLite setup complete on dbserver"
    SHELL
  end

  ##########################
  # Web Application Server #
  ##########################
  config.vm.define "webserver", primary: false do |web|
    web.vm.provider :digital_ocean do |provider|
      provider.ssh_key_name = ENV["SSH_KEY_NAME"]
      provider.token = ENV["DIGITAL_OCEAN_TOKEN"]
      provider.image = "ubuntu-22-04-x64"
      provider.region = "nyc3"
      provider.size = "s-1vcpu-1gb"
      provider.privatenetworking = true
    end

    web.vm.hostname = "webserver"

    web.trigger.before :up do |trigger|
      trigger.info = "Waiting for dbserver's IP..."
      trigger.ruby do |env, machine|
        ip_file = "db_ip.txt"
        until File.exist?(ip_file)
          sleep 1
        end
        db_ip = File.read(ip_file).strip
        puts "dbserver IP is #{db_ip}"
      end
    end

    web.vm.provision "shell", inline: <<-SHELL
      # Wait for apt-get lock to be released
      while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
        echo "Waiting for dpkg lock to be released..."
        sleep 5
      done

      # Install dependencies
      sudo apt-get update -y
      sudo apt-get install -y curl gnupg

      # Install Docker
      curl -fsSL https://get.docker.com -o get-docker.sh
      sudo sh get-docker.sh
      sudo usermod -aG docker $USER

      # Install Docker Compose
      sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      docker-compose --version

      # Navigate to the synced project folder
      cd /vagrant

      # Build and start the Docker container
      sudo docker-compose up -d --build
    SHELL

    web.trigger.after :provision do |trigger|
      trigger.ruby do |env, machine|
        File.delete($ip_file) if File.exist?($ip_file)
      end
    end
  end
end
