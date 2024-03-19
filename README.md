# S3cmdBackup

`S3cmdBackup.sh` is a highly customizable and robust shell script designed for backing up files from an Ubuntu server to DigitalOcean Spaces using the `s3cmd` tool. It features detailed logging, flexible configuration options, error resilience, and supports both sync and copy backup modes.

## Features

- **Flexible Configuration**: Easily configure hostname, DigitalOcean Spaces details, directories for backup, and more.
- **Secure Transfer**: Option to use HTTPS for secure file transfer.
- **Backup Modes**: Supports both 'sync' and 'copy' modes for flexible backup strategies.
- **Logging and Monitoring**: Detailed logging with automatic log rotation and backup messages providing a summary of each backup operation.
- **Error Handling**: Designed to continue running even if errors occur, ensuring robustness.
- **Cron Job Friendly**: Can be scheduled with a cron job for automated backups.

## Prerequisites

- Ubuntu 22.04 server
- `s3cmd` version 2.x installed and configured for your DigitalOcean Spaces
- DigitalOcean Spaces access key and secret key

## Installation

1. Clone the repository or download `s3cmdbackup.sh` directly:

```bash
git clone https://github.com/drhdev/s3cmdbackup.git
```

2. Make the script executable:

```bash
chmod +x s3cmdbackup/s3cmdbackup.sh
```

3. Edit `s3cmdbackup.sh` to configure your backup settings according to the comments in the script.

## Usage

Execute the script manually:

```bash
./s3cmdbackup/s3cmdbackup.sh
```

Or schedule it with cron for regular backups. For example, to run the backup daily at 2 AM, add the following line to your crontab (edit crontab with `crontab -e`):

```
0 2 * * * /path/to/s3cmdbackup/s3cmdbackup.sh
```

## Configuration

The script includes several configuration options you can customize:

- **Hostname**
- **DigitalOcean Spaces Details**
- **Backup Directory**
- **HTTPS Usage**
- **Backup Type**
- **Paths to Backup**
- **Logging and Backup Message Settings**

See the comments in `s3cmdbackup.sh` for detailed instructions on each configuration option.

## Contributing

Contributions are welcome! If you have a feature request, bug report, or a suggestion, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
