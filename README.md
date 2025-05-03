# linux security Audit and server Hardening Script

This script automates the security audit and hardening process for Linux servers. It performs checks on user accounts, file permissions, services, firewall settings, and more. It also applies hardening measures to improve server security.

## Prerequisites

- Linux server
- Root or sudo access
- Git

## Usage

*Make the Script Executable:**

   ```bash
   chmod +x security_audit_and_server_hardening.sh
   ```

3. **Run the Script:**

   ```bash
   sudo ./scripts/audit_and_harden.sh
   ```

## Script Overview

- `audit_users`: Checks user accounts and passwords.
- `audit_permissions`: Scans file and directory permissions.
- `audit_services`: Lists and checks running services.
- `audit_firewall_network`: Audits firewall and network configurations.
- `check_ip_network`: Checks IP configurations and public vs private IPs.
- `check_updates`: Checks for available security updates.
- `check_logs`: Monitors logs for suspicious activities.
- `harden_server`: Applies hardening measures including SSH configuration, firewall settings, and more.

## Customization

You can extend the script with custom checks by editing the functions or adding new ones. Customize settings in the script as needed for your environment.

## Crontab
   - A file containing all cron jobs that should run or execute in specific time.
   - Used for task scheduling and task automation.

crontab -l  == check all crontab entries
crontab -e  == to edit crontab 

#cmds
-crontab -e
-0 3 */15 * * /path/to/secure_audit_and_server_hardening.sh >> /var/log/audit_cron.log 2>&1
`this will run the scrpt file after every 15 days `
` in this "0 3" is time that is 3:00 am and "15" is day that every 15 days`


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
