#!/bin/bash
# This script creates a cloned user from the pi user or a specified user

# Read the username to create
read -p "Enter the username to create: " USERNAME

# Read the username to copy (default to pi)
read -p "Enter the username to copy (default: pi): " COPY_USERNAME
COPY_USERNAME=${COPY_USERNAME:-pi}

# Try to execute the commands
if ! (
  # Create a new user
  sudo adduser $USERNAME
  # Add the new user to the sudo group
  sudo adduser $USERNAME sudo
  # Get the groups that the copy user belongs to, excluding the copy user
  COPY_GROUPS=$(groups $COPY_USERNAME | cut -d: -f2- | tr ' ' '\n' | grep -v "^$COPY_USERNAME$" | tr '\n' ' ')
  # Add ssh group to the list
  ALL_GROUPS="ssh $COPY_GROUPS"
  # Add the new user to all groups
  sudo usermod -a -G $ALL_GROUPS $USERNAME
); then
  # Print error message if something went wrong
  echo "Error: Failed to create and configure user $USERNAME"
  exit 1
else
  # Print success message if everything went well
  echo "User $USERNAME created and configured successfully!"
fi