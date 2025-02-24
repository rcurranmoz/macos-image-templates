packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "vm_name" {
  type    = string
  default = "sonoma-base"
}

source "tart-cli" "puppet-setup-phase2" {
  vm_name      = "${var.vm_name}"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 100
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
}

build {
  name    = "puppet-setup-phase2"
  sources = ["source.tart-cli.puppet-setup-phase2"]

  provisioner "file" {
  source      = "set_hostname.sh"
  destination = "/tmp/set_hostname.sh"
}

  provisioner "file" {
    source      = "com.mozilla.sethostname.plist"
    destination = "/tmp/com.mozilla.sethostname.plist"
  }

  provisioner "shell" {
    inline = [

      "echo 'Setting up hostname auto-config at startup...'",

      # Move the script and set permissions
      "echo admin | sudo -S mv /tmp/set_hostname.sh /usr/local/bin/set_hostname.sh",
      "echo admin | sudo -S chmod +x /usr/local/bin/set_hostname.sh",

      # Move the launch daemon file and set permissions
      "echo admin | sudo -S mv /tmp/com.mozilla.sethostname.plist /Library/LaunchDaemons/com.mozilla.sethostname.plist",
      "echo admin | sudo -S chmod 644 /Library/LaunchDaemons/com.mozilla.sethostname.plist",
      "echo admin | sudo -S chown root:wheel /Library/LaunchDaemons/com.mozilla.sethostname.plist",

      # Load the daemon so it runs on startup
      "echo admin | sudo -S launchctl load /Library/LaunchDaemons/com.mozilla.sethostname.plist",

      "echo 'Hostname configuration is now active.'",

      "echo 'Ensuring /etc/puppet_role exists before running Puppet...'",
      "if [ ! -f /etc/puppet_role ]; then",
      "  echo 'Restoring Puppet role to gecko_t_osx_1400_m_vms...'",
      "  echo 'gecko_t_osx_1400_m_vms' | sudo tee /etc/puppet_role",
      "  echo admin | sudo -S chmod 644 /etc/puppet_role",
      "fi",

      "echo 'Ensuring bootstrap_mojave_tester.sh exists...'",
      "if [ ! -f /tmp/bootstrap_mojave_tester.sh ]; then",
      "  echo 'Re-downloading bootstrap_mojave_tester.sh from S3...'",
      "  curl -o /tmp/bootstrap_mojave_tester.sh https://ronin-puppet-package-repo.s3.us-west-2.amazonaws.com/macos/public/common/bootstrap_mojave_tester.sh",
      "  chmod +x /tmp/bootstrap_mojave_tester.sh",
      "fi",

      "echo 'Restoring macos_tcc_perms, safaridriver, and macos_directory_cleaner in role manifest...'",
      "sudo sed -i '.bak' '/#.*macos_tcc_perms/s/^#//' /Users/admin/Desktop/puppet/ronin_puppet/modules/roles_profiles/manifests/roles/gecko_t_osx_1400_m_vms.pp",
      "sudo sed -i '.bak' '/#.*safaridriver/s/^#//' /Users/admin/Desktop/puppet/ronin_puppet/modules/roles_profiles/manifests/roles/gecko_t_osx_1400_m_vms.pp",
      "sudo sed -i '.bak' '/#.*macos_directory_cleaner/s/^#//' /Users/admin/Desktop/puppet/ronin_puppet/modules/roles_profiles/manifests/roles/gecko_t_osx_1400_m_vms.pp",
      
      "echo 'Re-running bootstrap_mojave_tester.sh (second attempt after reboot)...'",
      "echo admin | sudo -S /tmp/bootstrap_mojave_tester.sh || echo 'Puppet run completed with errors, but continuing...'",

      "echo 'Finalizing setup. Ensuring clean exit...'",
      "exit 0"
    ]
  }
}