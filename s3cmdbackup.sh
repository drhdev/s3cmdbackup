#!/bin/bash

# Name: s3cmdbackup.sh
# Version: 0.3
# Author: drhdev
# Description: This script enables the backup of files from an Ubuntu server to DigitalOcean Spaces using s3cmd. It now exclusively supports 'sync' and 'sync and delete' modes to align backups more closely with user expectations for maintaining remote directories in sync with local directories. The script checks for s3cmd configuration, verifies the existence of specified Spaces and directories before proceeding, and does not create missing elements, emphasizing user control over the backup environment. It features HTTPS transfers, detailed logging, log rotation, backup summaries, and is designed for high configurability, error resilience, and automation compatibility (e.g., via cron).
# License: GNU Public License
# Prerequisites: Ensure 's3cmd' is installed and configured (.s3cfg in the home directory), the target Space and directory exist in DigitalOcean Spaces, and the script has been customized to your backup requirements.
# Installation: Clone or download the script from https://github.com/drhdev/s3cmdbackup. Make the script executable with 'chmod +x s3cmdbackup.sh'. Edit the script to configure your backup settings as per your requirements.
# Usage: Execute './s3cmdbackup.sh' to initiate the backup process. Adjustments to backup settings and modes are documented within the script. For automated backups, add it to your crontab, e.g., '0 2 * * * /path/to/s3cmdbackup.sh', to run daily at 2 AM.

# Configuration
# Setting the system's hostname
HOSTNAME=$(hostname)

# DigitalOcean Spaces configuration
SPACE_NAME="your_space_name"

# Directory in the DigitalOcean Space for backups
DIRECTORY="/${HOSTNAME}_backup"

# Backup type: "sync" or "sync and delete"
BACKUP_TYPE="sync and delete" # Default changed to "sync and delete"

# Paths to backup
INCLUDE_PATHS=()
INCLUDE_PATHS+=("/var/www")
INCLUDE_PATHS+=("/home")
# Uncomment the next line to include /root in the backup
# INCLUDE_PATHS+=("/root")

# Logging
LOG_DIR="/var/log/s3cmd_backup"
LOG_NAME="s3cmd_backup_logfile_$(date +'%Y-%m-%d_%H-%M-%S').log"
MAX_LOG_FILES=10

# Backup message (can be used for notification)
MESSAGE_DIR="/var/log/s3cmd_backup"
MESSAGE_NAME="s3cmd_backup_message_$(date +'%Y-%m-%d_%H-%M-%S').txt"
MAX_MESSAGE_FILES=10

# Send backup message to Telegram
SEND_TO_TELEGRAM="off"

# Show Script Outputs on Screen (on = verbose, off = silent)
SCREEN_OUTPUT="off"

# Ensure necessary directories exist, otherwise create
mkdir -p "$LOG_DIR"
mkdir -p "$MESSAGE_DIR"

# Function to rotate logs and messages
rotate_files() {
    local path="$1"
    local max_files=$2
    local -r files=("$path"/*)
    if (( ${#files[@]} > max_files )); then
        mapfile -t to_delete < <(printf '%s\n' "${files[@]}" | sort | head -n -$max_files)
        rm -f "${to_delete[@]}"
    fi
}

# Function to hand message to totelegram.sh script
send_to_telegram() {
    local message_file="$1"
    if [[ "$SEND_TO_TELEGRAM" == "on" ]]; then
        /usr/local/bin/totelegram.sh -message "$message_file" --verbose
    fi
}

# Function to check prerequisites
check_prerequisites() {
    local log_file="${LOG_DIR}/${LOG_NAME}"

    if ! [ -f "$HOME/.s3cfg" ]; then
        echo "ERROR: .s3cfg configuration file not found in your home directory." | tee -a "$log_file"
        exit 1
    fi

    if ! s3cmd ls "s3://${SPACE_NAME}" --config="$HOME/.s3cfg" &> /dev/null; then
        echo "ERROR: Space '${SPACE_NAME}' does not exist or is not accessible. Please verify your settings." | tee -a "$log_file"
        exit 1
    fi

    if ! s3cmd ls "s3://${SPACE_NAME}${DIRECTORY}" --config="$HOME/.s3cfg" &> /dev/null; then
        echo "ERROR: Directory '${DIRECTORY}' does not exist in the space '${SPACE_NAME}'. Please create it before running this script." | tee -a "$log_file"
        exit 1
    fi
}

# Backup function
do_backup() {
    local paths=("${INCLUDE_PATHS[@]}")
    local log_file="${LOG_DIR}/${LOG_NAME}"
    local message_file="${MESSAGE_DIR}/${MESSAGE_NAME}"
    local backup_cmd="sync"

    if [ "$BACKUP_TYPE" == "sync and delete" ]; then
        backup_cmd="--delete-removed"
    fi

    # Check prerequisites
    check_prerequisites

    s3cmd $backup_cmd --no-progress --config="$HOME/.s3cfg" --recursive "${paths[@]/#/--include=}" --exclude='*' "s3://${SPACE_NAME}${DIRECTORY}" > "$log_file" 2>&1

    # Process log and generate backup message
    # Generate backup message
    {
        echo "Backup @$HOSTNAME"
        if grep -q 'ERROR' "$log_file"; then
            echo "Status: ERROR - Check log at $log_file"
        else
            echo "Status: SUCCESS - Log at $log_file"
        fi

        # Parsing the log file for details
        local total_files=$(grep -o 'Done. Uploaded .* files' "$log_file" | cut -d' ' -f3)
        local up_to_date=$(grep -o 'WARNING: Skipping file .* \(same size and mtime\)' "$log_file" | wc -l)
        local updated_files=$(grep -o 'File .* copied to .*' "$log_file" | wc -l)
        local new_files=$(grep -o 'File .* stored as .*' "$log_file" | wc -l)
        local deleted_files=$(grep -o 'File .* deleted' "$log_file" | wc -l)
        local total_size=$(grep -o 'Total transferred: .*' "$log_file" | cut -d' ' -f3-4)
        local space_used=$(s3cmd du "s3://${SPACE_NAME}${DIRECTORY}" --config=".s3cfg" | awk '{print $1/1024/1024/1024 " GB"}')

        echo "Files considered: $total_files (100%)"
        echo "Files up-to-date: $up_to_date ($(bc <<<"scale=2; $up_to_date/$total_files*100")%)"
        echo "Files updated: $updated_files ($(bc <<<"scale=2; $updated_files/$total_files*100")%)"
        echo "New files: $new_files ($(bc <<<"scale=2; $new_files/$total_files*100")%)"
        echo "Deleted files: $deleted_files ($(bc <<<"scale=2; $deleted_files/$total_files*100")%)"
        echo "Data transferred: $total_size"
        echo "Space used in directory: $space_used"
    } > "$message_file"

    # Send backup message to Telegram if enabled
    send_to_telegram "$message_file"

    # Rotate logs and messages
    rotate_files "$LOG_DIR" "$MAX_LOG_FILES"
    rotate_files "$MESSAGE_DIR" "$MAX_MESSAGE_FILES"

    # Output to screen if enabled
    if [ "$SCREEN_OUTPUT" = "on" ]; then
        cat "$log_file"
        echo "---------------------------------"
        cat "$message_file"
    fi
}

# Execute backup
do_backup

# Make script executable and able to run with cron, handling errors without stopping
set +e
