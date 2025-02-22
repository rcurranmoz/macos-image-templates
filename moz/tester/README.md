# macOS Packer Build Process

## Overview
This repository contains Packer templates to automate the provisioning of macOS virtual machines using [Tart](https://github.com/cirruslabs/tart). The process is split into three main phases:

1. **Create the Base macOS Image**: Installs a fresh macOS from an IPSW file and configures an admin account.
2. **Disable System Integrity Protection (SIP)**: Boots into macOS Recovery Mode and disables SIP.
3. **Run Puppet & Provision System**: Configures the system, installs necessary software, and applies Puppet manifests.

---

## **🛠 Prerequisites**
### **1️⃣ Install Packer**
Ensure you have **Packer installed**:
```sh
brew install hashicorp/tap/packer
```

### **2️⃣ Install Required Packer Plugins**
Run the following commands to install the necessary **Packer plugins**:
```sh
packer plugins install github.com/hashicorp/ansible
packer plugins install github.com/cirruslabs/tart
```

### **3️⃣ Install Tart**
Tart is required to run macOS virtual machines:
```sh
brew install cirruslabs/cli/tart
```
Ensure **Tart is working**:
```sh
tart --version
```

### **4️⃣  Prepare Vault Configuration**
For security reasons, you **must manually provide a `vault.yaml` file**:
```sh
cp /path/to/your/vault.yaml ~/Downloads/vault.yaml
```
✅ **Ensure `vault.yaml` is placed in `/Users/admin/Downloads/` before running Packer.**

---

## 🛠 Setup Instructions

### 1️⃣ **Create Base macOS Image**
Run the following command to create a fresh macOS image:

```sh
packer build moz/tester/create-base.pkr.hcl
```

This step:
✅ Installs macOS from an IPSW file  
✅ Configures the initial admin account  
✅ Prepares the system for SIP disabling  

---

### 2️⃣ **Disable SIP (System Integrity Protection)**
Once the base image is created, disable SIP using:

```sh
packer build -var="vm_name=sonoma-base" moz/tester/disable-sip.pkr.hcl
```

This step:  
✅ Boots into macOS Recovery Mode  
✅ Runs `csrutil disable`  
✅ Shuts down the system  

⚠ **Known Issue**: This step currently requires manual intervention. The VM may hang on a black screen. If this happens, give the vm about a minute and try to click to 'wake' it up

---

### 3️⃣ **Run Puppet & Fully Provision the System**
After disabling SIP, run Puppet to apply system configurations:

```sh
packer build -force -var="vm_name=sonoma-base" moz/tester/puppet-setup.pkr.hcl
```

This step:  
✅ Ensures `Rosetta 2` is installed  
✅ Installs Command Line Tools  
✅ Downloads and installs `Puppet` from S3  
✅ Clones the `ronin_puppet` repository  
✅ Runs `bootstrap_mojave_tester.sh` to apply configurations  
✅ Reboots if necessary to finalize the setup  

---

## 🐛 **Known Bugs & Issues**
1. **Disabling SIP Requires Manual Intervention**  
   - The VM may hang during the SIP step. You may need to manually "wake" it up.

2. **Puppet Does Not Apply All Role Configurations**  
   - `ronin_puppet/data/roles/gecko_t_osx_1400_r8_staging.yaml` is not fully applied.  
   - Some configurations and packages are not getting picked up correctly.  

---

## ✅ **Next Steps**
- Automate SIP disabling to eliminate manual intervention.  
- Ensure Puppet applies all role configurations and package installations.  
- Implement additional validation steps for package installation.  

---

### **🔧 Debugging**
To manually check SIP status, SSH into the VM and run:

```sh
csrutil status
```

To manually run Puppet:

```sh
sudo /opt/puppetlabs/bin/puppet apply --modulepath=/Users/admin/Desktop/puppet/ronin_puppet/modules:/etc/puppetlabs/code/environments/production/modules --hiera_config=/Users/admin/Desktop/puppet/ronin_puppet/hiera.yaml --logdest=console --color=false --detailed-exitcodes /Users/admin/Desktop/puppet/ronin_puppet/manifests/
```

---

## 🚀 **Conclusion**
This process automates macOS VM creation, SIP disabling, and provisioning with Puppet. While functional, improvements are needed to eliminate manual intervention and ensure all role configurations are properly applied.

 d