# BorgGuard Backup Script

## Created by: KeepItTechie
- YouTube Channel: [KeepItTechie](https://youtube.com/@KeepItTechie)
- Blog: [KeepItTechie Docs](https://docs.keepittechie.com/)

## Purpose
BorgGuard is a script designed to automate the process of creating and managing encrypted backups using BorgBackup. This script simplifies the setup and execution of secure backups by handling various tasks, ensuring your data is safely backed up with minimal manual intervention.

## Features
- **Password Management**: Securely creates and stores passwords for encryption.
- **Repository Initialization**: Easily initialize new Borg repositories.
- **Automated Backups**: Automate the backup process with detailed progress and status messages.
- **Password Generation**: Choose between manual and automatic password generation options.
- **Password Policies**: Enforce strong password policies for enhanced security.
- **Password Verification**: Verify passwords against stored hashes before performing backup operations.
- **Secure Storage**: Store and retrieve password hashes securely.

## Requirements
- BorgBackup (`borg`)
- Python 3
- pwgen

## Usage
1. **Clone the Repository**:
    ```sh
    git clone https://github.com/keepittechie/borgguard
    cd borgguard
    ```

2. **Run the Script**:
    ```sh
    ./borgguard.sh
    ```

3. **Follow the Prompts**:
    - You will be asked if this is a new backup repository.
    - Provide the path to the new or existing repository.
    - Choose between automatic or manual password creation.
    - Enter the directory you want to backup.

## Important Notes
- Review the script before running it to ensure it meets your requirements.
- Customize the backup directory and other settings as needed to suit your environment.

## Support
For more information, tutorials, and support, visit:
- [KeepItTechie YouTube Channel](https://youtube.com/@KeepItTechie)
- [KeepItTechie Docs](https://docs.keepittechie.com/)

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request or open an issue on GitHub.

## Disclaimer
This script is provided as-is. Please review and understand the changes it will make to your system before running it. Always ensure you have appropriate backups and understand the security implications of using this script.

