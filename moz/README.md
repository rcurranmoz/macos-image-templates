# **macOS Image Builder using Packer, Tart, and Cilicon**
This repository provides an automated way to **build macOS virtual machine images** using **Packer, Tart, and Cilicon**. It provisions a macOS VM with **Xcode, Puppet, and SignerBootstrap**, installs dependencies from **AWS S3**, and runs **bootstrap_mojave.sh** for further system setup.

## **🚀 Features**
✅ **Uses Packer + Tart to create macOS VM images**  
✅ **Automates macOS Setup Assistant screens**  
✅ **Installs Xcode, Puppet, and SignerBootstrap from S3**  
✅ **Clones the `ronin_puppet` repository from the `macos-signer-latest` branch**  
✅ **Supports Rosetta 2 for Apple Silicon compatibility**  
✅ **Runs `bootstrap_mojave.sh` to finalize system configuration**  

---

## **🛠 Prerequisites**
### **1️⃣ Install Packer**
Ensure you have **Packer installed**:
```sh
brew install packer
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
brew install tart
```
Ensure **Tart is working**:
```sh
tart --version
```

### **4️⃣ Install Cilicon (Optional)**
If using **Cilicon for managing Tart images**, install it:
```sh
brew install cirruslabs/cli/cilicon
```

### **5️⃣ Prepare Vault Configuration**
For security reasons, you **must manually provide a `vault.yaml` file**:
```sh
cp /path/to/your/vault.yaml ~/Downloads/vault.yaml
```
✅ **Ensure `vault.yaml` is placed in `/Users/admin/Downloads/` before running Packer.**

---

## **📦 Building the macOS VM**
### **Run Packer to Build the Image**
```sh
packer build -force templates/vanilla-sonoma.pkr.hcl
```
✅ **This will download necessary files, set up the VM, and run the provisioning steps.**

---

## **💻 Running the VM**
### **1️⃣ Start the VM with Tart**
```sh
tart run sonoma-signer
```
### **2️⃣ Find the VM’s IP Address**
```sh
tart ip sonoma-signer
```
### **3️⃣ SSH into the VM**
```sh
ssh admin@<VM_IP>
```
✅ You can now access the fully provisioned macOS VM.

---

## **📂 VM Artifacts & Storage**
Your Tart VM is stored in:
```sh
~/.tart/vms/sonoma-signer/
```
To **export the VM** for portability:
```sh
tart export sonoma-signer sonoma-signer.tar
```

---

## **🔄 Running Multiple VM Instances**
To **run multiple instances of the VM**, **clone it** before launching:
```sh
tart clone sonoma-signer sonoma-signer-2
tart run sonoma-signer-2
```

---

## **🛠 Debugging & Troubleshooting**
### **Check Packer Logs**
```sh
PACKER_LOG=1 packer build -force templates/vanilla-sonoma.pkr.hcl | tee packer-debug.log
```

### **Check the `vault.yaml` Placement**
```sh
ls -l /var/root/vault.yaml
```

### **Verify Xcode Installation**
```sh
xcode-select -p  # Should return: /Applications/Xcode.app/Contents/Developer
```

### **Check Puppet Installation**
```sh
puppet --version
```

---

## **🎯 Next Steps**
- ✅ Automate VM instance creation using **Cilicon**  
- ✅ Integrate the VM into **Taskcluster** for CI/CD workflows  
- ✅ Explore moving to **QEMU or another virtualization platform**  

---

## **🚀 Summary**
This setup allows you to **automatically build macOS VM images** with Packer and **deploy them using Tart**. It ensures **Xcode, Puppet, and SignerBootstrap are installed from S3**, runs **bootstrap_mojave.sh**, and provides **a fully automated macOS VM provisioning workflow**.

🚀 **You're now set up with a production-ready macOS CI/CD system!** Let me know if you need any refinements. 🎉
