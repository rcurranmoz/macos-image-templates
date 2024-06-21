#!/bin/bash

# Run as root

# GitHub repository information
REPO="taskcluster/taskcluster"

# Asset names to download
ASSETS=(
  "generic-worker-multiuser-darwin-arm64"
  "livelog-darwin-arm64"
  "start-worker-darwin-arm64"
  "taskcluster-proxy-darwin-arm64"
)

# Directory to place the binaries
TARGET_DIR="/usr/local/bin"

# Ensure the target directory exists
mkdir -p "$TARGET_DIR"

# Add /usr/local/bin to the macOS PATH if not already present
if ! echo "$PATH" | grep -q "$TARGET_DIR"; then
  echo "export PATH=$TARGET_DIR:\$PATH" >> /etc/profile
  echo "export PATH=$TARGET_DIR:\$PATH" >> /etc/paths
  export PATH=$TARGET_DIR:$PATH
  echo "Added $TARGET_DIR to the PATH."
fi

# Get the latest release information from the GitHub API
latest_release_info=$(curl -s https://api.github.com/repos/$REPO/releases/latest)

for asset in "${ASSETS[@]}"; do
  # Extract the download URL for the asset
  download_url=$(echo "$latest_release_info" | grep 'browser_download_url' | grep "$asset" | awk -F '"' '{print $4}')

  # Check if the download URL was found
  if [[ -z "$download_url" ]]; then
    echo "Error: Could not find the $asset asset in the latest release."
    continue
  fi

  # Determine the target filename by removing the -arm64 and -darwin suffixes
  target_filename=$(echo "$asset" | sed 's/-darwin-arm64//;s/-amd64//;s/-darwin//')

  # Download the asset to the target directory
  curl -L -o "$TARGET_DIR/$target_filename" "$download_url"

  # Make the binary executable
  chmod +x "$TARGET_DIR/$target_filename"

  echo "Downloaded and installed $target_filename to $TARGET_DIR successfully."
done

# Generate a key for signing artifacts. The private key will be written to the file 
# /etc/generic-worker/ed25519_key, and the public key will be written to standard out. 
# Keep a copy of the public key if you wish to validate artifact signatures.
mkdir -p /etc/generic-worker
/usr/local/bin/generic-worker new-ed25519-keypair --file /etc/generic-worker/ed25519_key

# Create the /usr/local/bin/run-generic-worker.sh script
cat << 'EOF' > /usr/local/bin/run-generic-worker.sh
#!/bin/bash

. /etc/rc.common

CheckForNetwork

while [ "${NETWORKUP}" != "-YES-" ]
do
  sleep 5
  NETWORKUP=
  CheckForNetwork
done

cd ~

/usr/local/bin/start-worker /etc/generic-worker/runner.yml
EOF

# Make the run-generic-worker.sh script executable
chmod +x /usr/local/bin/run-generic-worker.sh

echo "Created and made /usr/local/bin/run-generic-worker.sh executable."

# Create /etc/generic-worker/runner.yml with the specified configuration
cat << 'EOF' > /etc/generic-worker/runner.yml
getSecrets: false
provider:
  clientID: project/releng/generic-worker/datacenter-gecko-t-osx-1400-m2-staging
  providerType: standalone
  rootURL: "https://firefox-ci-tc.services.mozilla.com"
  providerID: standalone
  accessToken: "********************************************"
  workerPoolID: releng-hardware/gecko-t-osx-1400-m2-staging
  workerGroup: macstadium-vegas
  workerID: moz-runner-multi-1
  workerLocation:
    host: macstadium
worker:
  implementation: generic-worker
  path: /usr/local/bin/generic-worker
  configPath: /etc/generic-worker/config
workerConfig:
  cachesDir: "/Library/Caches/generic-worker/caches"
  cleanUpTaskDirs: true
  disableReboots: false
  downloadsDir: "/Library/Caches/generic-worker/downloads"
  ed25519SigningKeyLocation: "/etc/generic-worker/ed25519_key"
  livelogExecutable: "/usr/local/bin/livelog"
  publicIP: "192.168.5.174"
  requiredDiskSpaceMegabytes: 20480
  runTasksAsCurrentUser: true
  sentryProject: "generic-worker"
  shutdownMachineOnIdle: false
  shutdownMachineOnInternalError: false
  taskclusterProxyExecutable: "/usr/local/bin/taskcluster-proxy"
  taskclusterProxyPort: 8080
  tasksDir: "/Users"
  wstAudience: "firefoxcitc"
  wstServerURL: "https://firefoxci-websocktunnel.services.mozilla.com/"
EOF

echo "Created /etc/generic-worker/runner.yml with the specified configuration."

# Create the /Library/LaunchDaemons/com.mozilla.genericworker.plist file
cat << 'EOF' > /Library/LaunchDaemons/com.mozilla.genericworker.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.mozilla.genericworker</string>
        <key>Program</key>
        <string>/usr/local/bin/run-generic-worker.sh</string>
        <key>StandardOutPath</key>
        <string>/var/log/genericworker/stdout.log</string>
        <key>StandardErrorPath</key>
        <string>/var/log/genericworker/stderr.log</string>
        <key>RunAtLoad</key>
        <true/>
        <key>UserName</key>
        <string>root</string> <!-- (for multiuser build) -->
        <string>genericworker</string> <!-- (for insecure build) -->
    </dict>
</plist>
EOF

echo "Created /Library/LaunchDaemons/com.mozilla.genericworker.plist with the specified configuration."

# Load the LaunchDaemon to start the generic worker at boot
# sudo launchctl load -w /Library/LaunchDaemons/com.mozilla.genericworker.plist

# echo "Loaded the LaunchDaemon to start the generic worker at boot."