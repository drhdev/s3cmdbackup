# s3cmdbackup

`s3cmdbackup.sh` is a robust and highly customizable shell script designed for backing up files from an Ubuntu server to DigitalOcean Spaces using the s3cmd tool. It ensures secure and efficient backups with detailed logging, flexible configuration options, error resilience, and supports updated backup modes "sync" and "sync and delete".

## Features

- **Flexible Configuration**: Customize hostname, DigitalOcean Spaces details, directories for backup, and more directly within the script.
- **Secure Transfer**: Supports HTTPS for secure file transfers to DigitalOcean Spaces.
- **Updated Backup Modes**: Now exclusively supports 'sync' for straightforward backups and 'sync and delete' for mirror-like backups, removing files in the destination not present in the source.
- **Logging and Monitoring**: Generates detailed logs with automatic rotation and backup messages, offering summaries of each backup operation.
- **Error Handling**: Crafted to handle errors gracefully and continue running, enhancing the script's robustness.
- **Cron Job Friendly**: Easily schedule automated backups with cron for regular, hands-off operation.

## Prerequisites

- Ubuntu server (22.04 recommended)
- s3cmd version 2.x installed and configured for your DigitalOcean Spaces
- DigitalOcean Spaces access key and secret key
- `.s3cfg` configuration file set up in the user's home directory

## Installation

1. Clone the repository or download `s3cmdbackup.sh` directly:
   ```
   git clone https://github.com/drhdev/s3cmdbackup.git
   ```
2. Make the script executable:
   ```
   chmod +x s3cmdbackup/s3cmdbackup.sh
   ```
3. Edit `s3cmdbackup.sh` to configure your backup settings, following the instructions within the script.

## Usage

- **Manual Execution**:
  ```
  ./s3cmdbackup/s3cmdbackup.sh
  ```
- **Cron Job**: Schedule with cron for regular backups. For example, to run the backup daily at 2 AM, add the following line to your crontab (edit with `crontab -e`):
  ```
  0 2 * * * /path/to/s3cmdbackup/s3cmdbackup.sh
  ```

## Configuration

The script offers several configuration options for customization:

- Hostname
- DigitalOcean Spaces Details
- Backup Directory
- HTTPS Usage
- Backup Type (`sync` or `sync and delete`)
- Paths to Backup
- Logging and Backup Message Settings

Refer to comments in `s3cmdbackup.sh` for detailed configuration instructions.

## Contributing

Contributions are welcome! If you have a feature request, bug report, or suggestion, please feel free to open an issue or submit a pull request.

## License

This project is licensed under the GNU Public License - see the LICENSE file for details.
```
