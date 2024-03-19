#!/bin/bash

# Backup script using s3cmd for DigitalOcean Spaces

# Configuration
# Setting the system's hostname or provide a custom name
HOSTNAME=$(hostname)

# DigitalOcean Spaces configuration
SPACE_NAME="your_space_name"
ACCESS_KEY="your_access_key"
SECRET_KEY="your_secret_key"

# Directory in the Space for backups
DIRECTORY="/${HOSTNAME}_backup"

# HTTPS transfer
USE_HTTPS="yes" # Change to "no" to use HTTP

# Backup type: "sync" or "copy"
BACKUP_TYPE="sync"

# Paths to backup
INCLUDE_PATHS=("/var/www" "/home")
# Uncomment the next line to include /root in the backup
#INCLUDE_PATHS+=("/root")

# Logging
LOG_DIR="/var/log/s3cmd_backup"
LOG_NAME="s3cmd_backup_logfile_$(date +'%Y-%m-%d_%H-%M-%S').log"
MAX_LOG_FILES=10

# Backup message
MESSAGE_DIR="/var/log/s3cmd_backup"
MESSAGE_NAME="s3cmd_backup_message_$(date +'%Y-%m-%d_%H-%M-%S').txt"
MAX_MESSAGE_FILES=10

# Screen output
SCREEN_OUTPUT="off"

# Ensure necessary directories exist
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

# Backup function
do_backup() {
    local paths="${INCLUDE_PATHS[*]}"
    local log_file="${LOG_DIR}/${LOG_NAME}"
    local message_file="${MESSAGE_DIR}/${MESSAGE_NAME}"

    # Setting up s3cmd configuration
    s3cmd --access_key="$ACCESS_KEY" --secret_key="$SECRET_KEY" --use-https="$USE_HTTPS" \
          --no-progress --config=".s3cfg" --logfile="$log_file" \
          ${BACKUP_TYPE} "${paths}" "s3://${SPACE_NAME}${DIRECTORY}" > "$log_file" 2>&1

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
