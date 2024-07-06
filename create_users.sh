#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Ensure input file is provided
USER_LIST=$1

if [ -z "$USER_LIST" ]; then
    echo "Usage: $0 <input_file>" >&2
    exit 1
fi

# Check if input file exists
if [ ! -f "$USER_LIST" ]; then
    echo "Error: file not found: $USER_LIST" >&2
    exit 1
fi

# Check and create the log file if it does not exist
LOG_FILE="/var/log/user_management.log"

if [ ! -f "$LOG_FILE" ]; then
    # Create the log file
    sudo touch "$LOG_FILE"
    echo "$LOG_FILE has been created."
else
    echo "Skipping creation of: $LOG_FILE (Already exists)"
fi

# Create /var/secure directory if it does not exist
PASSWORD_FILE="/var/secure/user_passwords.txt"

if [ ! -d /var/secure ]; then
    sudo mkdir -p /var/secure
    sudo touch "$PASSWORD_FILE"
    # Set ownership permissions for PASSWORD_FILE
    sudo chmod 700 /var/secure
fi

# Function to generate a random password
generate_password() {
    openssl rand -base64 12
}

echo "----------------------------------------"
echo "Generating Users and Groups"
echo "----------------------------------------"

# Read the file line by line and process
while IFS=';' read -r username groups; do
    # Extract the user name and groups, remove leading and trailing whitespaces
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    echo "Processing user: $username" | tee -a $LOG_FILE

    # Create the personal group for the user if it doesn't exist
    if ! getent group "$username" > /dev/null 2>&1; then
        sudo groupadd "$username"
        echo "Group $username created" | tee -a $LOG_FILE
    else
        echo "Group $username already exists" | tee -a $LOG_FILE
    fi

    # Initialize an array to hold the additional groups
    group_array=()
    for group in $(echo "$groups" | tr ',' ' '); do
        group=$(echo "$group" | xargs)  # Remove any extra whitespace

        # Check if the group exists
        if getent group "$group" > /dev/null 2>&1; then
            group_array+=("$group")
        else
            sudo groupadd "$group"
            echo "Group $group created" | tee -a $LOG_FILE
            group_array+=("$group")
        fi
    done

    # Join the group array into a comma-separated string
    more_groups=$(IFS=','; echo "${group_array[*]}")

    # Create the user if it doesn't exist, otherwise ensure they are added to the groups
    if ! id -u "$username" > /dev/null 2>&1; then
        sudo useradd -m -g "$username" -G "$more_groups" "$username" &>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "User $username created and added to groups: $more_groups" | tee -a $LOG_FILE

            # Generate a password for the user
            password=$(generate_password)
            echo "$username:$password" | sudo chpasswd
            if [[ $? -eq 0 ]]; then
                echo "Password for $username set" | tee -a $LOG_FILE

                # Store the password securely
                echo "$username,$password" >> $PASSWORD_FILE
            else
                echo "Failed to set password for user $username" | tee -a $LOG_FILE
            fi

            # Set permissions on the home directory
            sudo chown "$username:$username" "/home/$username"
            sudo chmod 700 "/home/$username"
            echo "Home directory permissions set for $username" | tee -a $LOG_FILE
        else
            echo "Failed to create user $username" | tee -a $LOG_FILE
        fi
    else
        echo "User $username already exists" | tee -a $LOG_FILE
        sudo usermod -aG "$more_groups" "$username"
        echo "User $username added to groups: $more_groups" | tee -a $LOG_FILE
    fi

done < "$USER_LIST"

# Log the script execution to standard output
echo "User creation process completed. Logs can be found at $LOG_FILE."
