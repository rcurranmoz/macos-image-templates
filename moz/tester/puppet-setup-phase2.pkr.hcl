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

  provisioner "shell" {
    inline = [
      "echo 'Ensuring /etc/puppet_role exists before running Puppet...'",
      "if [ ! -f /etc/puppet_role ]; then",
      "  echo 'Restoring Puppet role to gecko_t_osx_1400_r8_staging...'",
      "  echo 'gecko_t_osx_1400_r8_staging' | sudo tee /etc/puppet_role",
      "  echo admin | sudo -S chmod 644 /etc/puppet_role",
      "fi",

      "echo 'Ensuring bootstrap_mojave_tester.sh exists...'",
      "if [ ! -f /tmp/bootstrap_mojave_tester.sh ]; then",
      "  echo 'Re-downloading bootstrap_mojave_tester.sh from S3...'",
      "  curl -o /tmp/bootstrap_mojave_tester.sh https://ronin-puppet-package-repo.s3.us-west-2.amazonaws.com/macos/public/common/bootstrap_mojave_tester.sh",
      "  chmod +x /tmp/bootstrap_mojave_tester.sh",
      "fi",

      "echo 'Restoring macos_tcc_perms and safaridriver in role manifest...'",
      "sudo mv /Users/admin/Desktop/puppet/ronin_puppet/modules/roles_profiles/manifests/roles/gecko_t_osx_1400_r8_staging.pp.bak /Users/admin/Desktop/puppet/ronin_puppet/modules/roles_profiles/manifests/roles/gecko_t_osx_1400_r8_staging.pp",

      "echo 'Re-running bootstrap_mojave_tester.sh (second attempt after reboot)...'",
      "echo admin | sudo -S /tmp/bootstrap_mojave_tester.sh || echo 'Puppet run completed with errors, but continuing...'",

      "echo 'Finalizing setup. Ensuring clean exit...'",
      "exit 0"
    ]
  }
}