#!/bin/bash
# This script creates a cloned user from the pi user or a specified user

# Read the username to create
while true; do
  read -p "Enter the username to create: " USERNAME
  if [[ $USERNAME =~ ^[a-zA-Z0-9_][a-zA-Z0-9_-]{1,31}$ ]]; then
    break
  else
    echo "Error: Invalid username. Please enter a username with only letters, numbers, underscores, and hyphens, and between 3 and 32 characters long."
  fi
done

# Check if the username already exists
if getent passwd "$USERNAME" &>/dev/null; then
  echo "Error: The selected username '$USERNAME' already exists. Please choose a different username."
  exit 1
fi

# Read the username to copy (default to pi)
while true; do
  read -p "Enter the username to copy (default: pi): " COPY_USERNAME
  if [[ -z "$COPY_USERNAME" ]]; then
    COPY_USERNAME="pi"
  fi

  if [[ $COPY_USERNAME =~ ^[a-zA-Z0-9_][a-zA-Z0-9_-]{1,31}$ ]]; then
    break
  else
    echo "Error: Invalid username. Please enter a username with only letters, numbers, underscores, and hyphens, and between 3 and 32 characters long."
  fi
done

# Check if the COPY_USERNAME exists
if ! getent passwd "$COPY_USERNAME" &>/dev/null; then
  echo "Error: Username '$COPY_USERNAME' does not exist. Please choose a valid username to copy."
  exit 1
fi

# Try to execute the commands
if ! (
  # Create a new user
  sudo adduser $USERNAME
  # Add the new user to the sudo group
  sudo adduser $USERNAME sudo
  # Get the groups that the copy user belongs to, excluding the copy user
  COPY_GROUPS=$(id -nG "$COPY_USERNAME" | tr ' ' ',')

  # Check if there are any groups to add
  if [[ -z "$COPY_GROUPS" ]]; then
    echo "Warning: No additional groups found for $COPY_USERNAME."
  else
  # Add the new user to all groups
  echo "Adding $USERNAME to groups: $COPY_GROUPS"
  sudo usermod -a -G "$COPY_GROUPS" "$USERNAME"
  fi
); then
  # Print error message if something went wrong
  echo "Error: Failed to create and configure user $USERNAME"
  exit 1
else
  # Print success message if everything went well
  echo "User $USERNAME created and configured successfully!"
fi
