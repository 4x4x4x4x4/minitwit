# -*- mode: ruby -*-
# vi: set ft=ruby :

$ip_file = "db_ip.txt"

Vagrant.configure("2") do |config|
  # Use the DigitalOcean box provided by the vagrant-digitalocean plugin
  config.vm.box = "digital_ocean"
  config.vm.box_url = "https://github.com/devopsgroup-io/vagrant-digitalocean/raw/master/box/digital_ocean.box"
  config.ssh.private_key_path = "~/.ssh/id_rsa"   # Adjust if needed
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  #########################
  # Database Server Setup #
  #########################
  config.vm.define "dbserver", primary: true do |db|
    db.vm.provider :digital_ocean do |provider|
      provider.ssh_key_name = ENV["SSH_KEY_NAME"]
      provider.token = ENV["DIGITAL_OCEAN_TOKEN"]
      provider.image = "ubuntu-22-04-x64"
      provider.region = "nyc3"  # Change region if needed
      provider.size = "s-1vcpu-1gb"
      provider.privatenetworking = true
    end

    db.vm.hostname = "dbserver"

    # Trigger: After the server is up, write its public IP to db_ip.txt
    db.trigger.after :up do |trigger|
      trigger.info = "Writing dbserver's IP to file..."
      trigger.ruby do |env, machine|
        remote_ip = machine.instance_variable_get(:@communicator).instance_variable_get(:@connection_ssh_info)[:host]
        File.write($ip_file, remote_ip)
      end
    end

    # Provisioning: Install SQLite (if needed) or perform any database-related setup.
    # For now, we assume SQLite is just a file, but you can install other software if needed.
    db.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      # Install SQLite if you need the CLI tools, etc.
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
      provider.region = "nyc3"  # Must be same region as dbserver for private networking
      provider.size = "s-1vcpu-1gb"
      provider.privatenetworking = true
    end

    web.vm.hostname = "webserver"

    # Wait for the dbserver's IP file before proceeding
    web.trigger.before :up do |trigger|
      trigger.info = "Waiting for dbserver's IP..."
      trigger.ruby do |env, machine|
        ip_file = "db_ip.txt"
        until File.exist?(ip_file)
          sleep 1
        end
        db_ip = File.read(ip_file).strip
        puts "dbserver IP is #{db_ip}"
        # Optionally, write this IP to a configuration file your app can use.
      end
    end

    # Provisioning: Install Ruby and start your web app
    web.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      sudo apt-get install -y ruby-full build-essential

      cd /vagrant
      gem install bundler
      bundle install

      # If your app requires any migrations or setup, run them here
      # Example: bundle exec rake db:migrate

      # Export the DB server IP for your application
      export DB_HOST=$(cat /vagrant/db_ip.txt)

      # Start your Ruby web application (adjust the command to suit your app)
      nohup bundle exec rackup --host 0.0.0.0 --port 8080 > /tmp/app.log 2>&1 &
      echo "Web server is starting on port 8080..."
    SHELL

    # Cleanup: Remove the temporary db_ip.txt after provisioning
    web.trigger.after :provision do |trigger|
      trigger.ruby do |env, machine|
        File.delete($ip_file) if File.exist?($ip_file)
      end
    end
  end

  # Optional global provisioning for all machines (update package lists)
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    sudo apt-get update -y
  SHELL
end
