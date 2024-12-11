#!/bin/bash

# Setup a scheduled system update script execution on your Raspberry Pi

# Create a script to update the system
echo "Creating update script..."
cat > update_script.sh <<EOF
#!/bin/bash

# Update package list
sudo apt update

# Upgrade packages
sudo apt full-upgrade -y

# Clean up
sudo apt autoremove -y
sudo apt autoclean -y
EOF

# Make the script executable
echo "Making script executable..."
chmod +x update_script.sh

# Add the script to cron
echo "Adding script to cron..."
CRON_PATH=$(pwd)/update_script.sh
crontab -l > cron_backup
echo "0 0 * * 0 $CRON_PATH" >> cron_backup
crontab cron_backup
rm cron_backup

# Print success message
echo "System update script scheduled successfully!"
