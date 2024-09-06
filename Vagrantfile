# -*- mode: ruby -*-
# vi: set ft=ruby :

# Please don't change it unless you know what you're doing.
# vagrant init
# vagrant plugin install vagrant-reload
# vagrant plugin install dotenv
# vagrant up --provider=hyperv

require 'dotenv'
Dotenv.load('.env')

# Load environment variables from the .env file
node_count = ENV['NODE_COUNT'].to_i
node_box = ENV['NODE_BOX']
node_name = ENV['NODE_NAME']
hpv_switch = ENV['HPV_SWITCH']
vm_gateway = ENV['VM_GATEWAY']
ssh_key_path = ENV['SSH_KEY_PATH']
provider = ENV['PROVIDER']
base_ip_address = ENV['BASE_IP_ADDRESS']
default_username = ENV['DEFAULT_USERNAME']
default_password = ENV['DEFAULT_PASSWORD']

# Read SSH public key once, making it accessible in all blocks
ssh_pub_key = File.readlines(ssh_key_path).first.strip

Vagrant.configure("2") do |config|

	config.trigger.before :up do |trigger|
		trigger.info = "Creating 'NATSwitch' Hyper-V switch if it does not exist..."

		# Execute the PowerShell script to create the Hyper-V switch
		trigger.run = {privileged: "true", powershell_elevated_interactive: "true", path: "./scripts/create-nat-hyperv-switch.ps1"}
	end

	config.trigger.after :destroy do |trigger|
		trigger.info = "Removing 'NATSwitch' Hyper-V switch and associated NAT configuration..."
		
		trigger.run = {privileged: "true", powershell_elevated_interactive: "true", path: "./scripts/remove-vmswitch-nat.ps1"}
	end

	# Loop to define multiple VMs based on the node_count variable
	(1..node_count).each do |i|
		config.vm.define "#{node_name}0#{i}" do |node|
			node.vm.box = node_box
			# Configure the VM's network settings, bridged to the specified Hyper-V switch
			node.vm.network "private_network", bridge: hpv_switch

			# Set the VM's hostname
			node.vm.hostname = "#{node_name}0#{i}"

			# Construct the full IP address for the VM
			ip_address = "#{base_ip_address}.#{i + 1}"

			# Provision the VM with a shell script to configure a static IP
			node.vm.provision "shell", path: "./scripts/configure-static-ip.sh", args: "#{ip_address} #{vm_gateway}"

			# Provision the VM with the user's SSH public key for authentication
			node.vm.provision "shell" do |s|
				s.inline = <<-SHELL
					# Add SSH keys for root, vagrant users
					mkdir -p /root/.ssh
					echo #{ssh_pub_key} >> /root/.ssh/authorized_keys
					echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
					# Change password for the vagrant user
					echo 'vagrant:#{default_password}' | sudo chpasswd
				SHELL
			end

			# Provision the VM to create the default user and set the password
			node.vm.provision "shell", inline: <<-SHELL
				# Create user #{default_username} with the provided password
				sudo useradd -m -s /bin/bash #{default_username}
				echo '#{default_username}:#{default_password}' | sudo chpasswd

				# Add #{default_username} to sudo group
				sudo usermod -aG sudo #{default_username}
				# Set up SSH for #{default_username}
				mkdir -p /home/#{default_username}/.ssh
				echo #{ssh_pub_key} >> /home/#{default_username}/.ssh/authorized_keys
				chown -R #{default_username}:#{default_username} /home/#{default_username}/.ssh
				chmod 600 /home/#{default_username}/.ssh/authorized_keys
			SHELL

			# Reload the VM configuration after provisioning
			node.vm.provision :reload

			# Configure VM settings for the specified provider
			node.vm.provider provider do |h|
				h.vmname = "#{node_name}0#{i}"
				h.memory = 2048
				# h.maxmemory = 4096
				h.cpus = 1
				h.auto_start_action = "StartIfRunning" # (Nothing, StartIfRunning, Start) - Default: Nothing.
			end
		end
	end
end
