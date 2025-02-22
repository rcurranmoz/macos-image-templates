packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

# Define a variable for VM name (allows dynamic selection)
variable "vm_name" {
  type    = string
  default = "sonoma-sip-disabled"  # Default to the SIP-disabled VM
}

source "tart-cli" "puppet-setup" {
  vm_name      = "${var.vm_name}"  # Use dynamic variable instead of hardcoding
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 100
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
}

build {
  name    = "puppet-setup"
  sources = ["source.tart-cli.puppet-setup"]

  provisioner "file" {
    source      = "/Users/admin/Downloads/vault.yaml"
    destination = "/tmp/vault.yaml"
  }

  provisioner "shell" {
    inline = [

      "echo 'Ensuring Rosetta 2 is installed...'",
      "if /usr/bin/pgrep oahd >/dev/null 2>&1; then",
      "  echo 'Rosetta 2 is already installed'",
      "else",
      "  echo 'Installing Rosetta 2...'",
      "  echo admin | sudo -S softwareupdate --install-rosetta --agree-to-license",
      "fi",

      # Ensure vault.yaml is where bootstrap_mojave.sh expects it
      "echo admin | sudo -S mkdir -p /var/root/",
      "echo admin | sudo -S cp /tmp/vault.yaml /var/root/vault.yaml",

      "echo 'Enabling passwordless sudo for admin...'",
      "echo admin | sudo -S sh -c 'mkdir -p /etc/sudoers.d/ && echo \"admin ALL=(ALL) NOPASSWD: ALL\" | tee /etc/sudoers.d/admin-nopasswd'",

      "echo 'Installing Command Line Tools...'",
      "touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress",
      "softwareupdate --list | sed -n 's/.*Label: \\(Command Line Tools for Xcode-.*\\)/\\1/p' | xargs -I {} softwareupdate --install '{}'",
      "rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress",

      # Ensure Puppet is installed before running (download from S3)
      "if ! command -v /opt/puppetlabs/bin/puppet &> /dev/null; then",
      "  echo 'Downloading Puppet from S3...'",
      "  curl -o /tmp/puppet-agent-7.28.0-1-installer.pkg https://ronin-puppet-package-repo.s3.us-west-2.amazonaws.com/macos/public/common/puppet-agent-7.28.0-1-installer.pkg",
      "  echo 'Installing Puppet...'",
      "  echo admin | sudo -S installer -pkg /tmp/puppet-agent-7.28.0-1-installer.pkg -target /",
      "fi",

      # Ensure Puppet is in the PATH
      "export PATH=$PATH:/opt/puppetlabs/bin",

      # Ensure the Puppet repo is cloned from the correct branch
      "if [ ! -d /Users/admin/Desktop/puppet/ronin_puppet ]; then",
      "  echo 'Cloning ronin_puppet repository...'",
      "  git clone --branch master https://github.com/mozilla-platform-ops/ronin_puppet.git /Users/admin/Desktop/puppet/ronin_puppet",
      "fi",

      # Download bootstrap_mojave_tester.sh from S3
      "echo 'Downloading bootstrap_mojave.sh from S3...'",
      "curl -o /tmp/bootstrap_mojave_tester.sh https://ronin-puppet-package-repo.s3.us-west-2.amazonaws.com/macos/public/common/bootstrap_mojave_tester.sh",

      # Ensure the script is executable
      "chmod +x /tmp/bootstrap_mojave_tester.sh",

      # Set Puppet role to gecko_t_osx_1400_r8_staging
      "sudo mkdir -p /etc/facter/facts.d/",
      "echo 'gecko_t_osx_1400_r8_staging' | sudo tee /etc/facter/facts.d/puppet_role.txt",
      "echo 'gecko_t_osx_1400_r8_staging' | sudo tee /etc/puppet_role",
      "sudo chmod 644 /etc/puppet_role",

      # Fix 2: Ensure /usr/local/bin/ Exists Before Puppet Runs
      "sudo mkdir -p /usr/local/bin/",
      "sudo chmod 755 /usr/local/bin/",

      "echo 'Ensuring pip3 is correctly linked...'",
      "sudo mkdir -p /Library/Frameworks/Python.framework/Versions/3.11/bin/",
      "sudo ln -sf /usr/bin/pip3 /Library/Frameworks/Python.framework/Versions/3.11/bin/pip3",

      "echo 'Ensuring /usr/local/bin/ exists...'",
      "sudo mkdir -p /usr/local/bin/",
      "sudo chmod 755 /usr/local/bin/",

      "echo 'Removing broken symlinks from /usr/local/bin/...'",
      "sudo find -L /usr/local/bin -type l -exec rm -f {} \\;",

      # Run Puppet the First Time
      "echo 'Running bootstrap_mojave_tester.sh (first attempt)...'",
      "if ! (echo admin | sudo -S /tmp/bootstrap_mojave_tester.sh); then",
      "  echo 'First Puppet run failed. Scheduling reboot...'",

      # Schedule reboot to finalize user creation
      "  sudo shutdown -r now",
      "  exit 0",
      "fi",

      # Wait for reboot & rerun Puppet
      "echo 'Waiting for reboot to complete...'",
      "sleep 120",

      "echo 'Re-running bootstrap_mojave_tester.sh (second attempt after reboot)...'",
      "echo admin | sudo -S /tmp/bootstrap_mojave_tester.sh || echo 'Puppet run completed with errors, but continuing...'",

      # Ensure clean exit
      "echo 'Ensuring clean exit...'",
      "exit 0"
    ]
  }
}