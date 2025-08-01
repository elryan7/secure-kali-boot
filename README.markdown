# Kali Linux Boot Security Script

This Bash script, authored by **elryan7**, is designed to secure a Kali Linux system booted from a USB drive. It enhances system security by disabling unnecessary services, configuring a firewall, randomizing the MAC address, creating a temporary user, securing SSH, and enabling automatic updates. The script is licensed under the **MIT License**.

## Features

- **Service Disabling**: Stops and disables unnecessary services (e.g., Bluetooth, CUPS, Avahi, RPC, NFS).
- **Firewall Configuration**: Uses UFW to block incoming connections except for SSH on a non-standard port.
- **MAC Address Randomization**: Randomizes the network interface's MAC address for anonymity.
- **Temporary User**: Creates a non-privileged user for safer operations.
- **SSH Hardening**: Configures SSH to use a non-standard port, disable root login, and enforce key-based authentication.
- **Automatic Updates**: Enables unattended upgrades for security patches.
- **Logging**: Saves all actions to a timestamped log directory.

## Requirements

The script requires the following tools to be installed:

- `ufw`
- `macchanger`
- `systemctl`
- `apt`

Install missing tools on Kali Linux using:

```bash
sudo apt-get install <tool-name>
```

## Usage

1. **Configure the script**: Edit the following variables at the top of the script:

   - `INTERFACE`: Network interface (e.g., `eth0`). Verify with `ip a`.
   - `LOG_DIR`: Directory for logs (default: `/root/security_logs`).
   - `TEMP_USER`: Name of the temporary user (default: `tempuser`).
   - `SSH_PORT`: Non-standard SSH port (default: `2222`).

2. **Run the script**:

   ```bash
   sudo ./secure_kali_boot.sh
   ```

   - The script must be run as root.
   - Logs are saved in `$LOG_DIR` with timestamps.

## Output

- **Logs**: All actions are logged in `$LOG_DIR` with timestamps (e.g., `services_2025-08-01_10-47-00.log`).
- **Summary**: A summary of actions (disabled services, firewall rules, etc.) is displayed at the end.
- **Captured Files**:
  - Service logs (`services_*.log`).
  - Firewall configuration logs (`ufw_*.log`).
  - MAC address changes (`macchanger_*.log`).
  - User creation logs (`user_*.log`).
  - SSH configuration logs (`ssh_*.log`).
  - Update logs (`updates_*.log`).

## Security Features

- Disables unnecessary services to reduce attack surface.
- Configures UFW to allow only SSH traffic on a non-standard port.
- Randomizes MAC address to prevent tracking.
- Creates a temporary user with a default password (`TempPass123`) for non-root operations.
- Hardens SSH by disabling root login and password authentication.
- Enables automatic security updates to keep the system patched.
- Restores original MAC address on cleanup.

## Cleanup

The script includes a cleanup function (`cleanup`) that:

- Restores the original MAC address.
- Automatically runs on script completion or interruption (`Ctrl+C`).

## License

This script is released under the **MIT License**.