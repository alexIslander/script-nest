#!/bin/bash

# The script combines the steps to install Docker and Docker Compose 
# and puts them into one script to make it easier to run 
# and takes care about the user groups

# Install Docker
echo "Installing Docker..."
curl -sSL https://get.docker.com | sh

# Add current user to Docker group
echo "Adding current user to Docker group..."
sudo usermod -aG docker $USER

# Install Docker Compose
echo "Installing Docker Compose..."
sudo apt install docker-compose

# Print success message
echo "Docker and Docker Compose installed successfully!"
