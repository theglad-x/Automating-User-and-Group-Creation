

## Streamlining User and Group Management with a Bash Script
This Bash script automates the process of creating users and groups, setting up home directories, generating random passwords, and logging all actions for easy auditing. It is designed to simplify user and group management in a Linux environment.

- **Root Privileges**: This script must be run as root.
- **Input File**: A text file containing usernames and group names in the format `user;groups`.

## Usage

1. **Ensure the script is executable**:
    ```bash
    chmod +x create_users.sh
    ```

2. **Run the script with `sudo`**:
    ```bash
    sudo ./create_users.sh <input_file>
    ```

   Replace `<input_file>` with the path to input file.

## Input File Format

The input file should contain usernames and group names separated by semicolons (`;`). Multiple group names separated by comma (`,`). Each user to be on a new line. 
For example:

  glad;admin,devops

  urunna;dev,sysops

  micah;architect

## Script Details

The script performs the following tasks:

1. **Checks for Root Privileges**: Ensures the script is run as root.
2. **Validates Input File**: Checks if the input file is provided and exists.
3. **Sets Up Log and Password Files**: Creates log and password files if they do not exist and sets appropriate permissions.
4. **Generates a Random Password**: Uses OpenSSL to generate a random password.
5. **Processes the Input File**: Reads the input file line by line, creates the necessary groups, adds users to the specified groups, generates passwords, sets up home directories, and logs all actions.
6. **Verifies Group Membership**: Ensures users are added to all specified groups even if they already exist.
7. **Creates Groups if Not Exist**: Creates groups that do not exist before adding users to them.
   
## Logging

- Actions are logged to `/var/log/user_management.log`.
- Generated passwords are stored in `/var/secure/user_passwords.txt`.

## Example

To run the script with an input file named `users.txt`:

```bash
sudo ./create_users.sh users.txt
```
