#!/bin/bash
#  Linux security audit and hardening script

REPORT="/var/log/security_audit_report.txt"
CONFIG_FILE="./custom_checks.conf"

echo "Security Audit and Hardening Report - $(date)" > "$REPORT"

log() {
    echo "$1" | tee -a "$REPORT"
}
#User and Group Audits 
log "---User and Group Audits ---"
log "All system users:"
cut -d: -f1 /etc/passwd | tee -a "$REPORT"
log "All system groups:"
cut -d: -f1 /etc/group | tee -a "$REPORT"
log "Users with UID 0:"
awk -F: '($3 == "0") {print}' /etc/passwd | tee -a "$REPORT"
log "Users without passwords:"
awk -F: '($2 == "") {print $1}' /etc/shadow | tee -a "$REPORT"

# File and Directory Permissions 
log "----File and Directory Permissions ---"
log "World-writable directories:"
find / -xdev -type d -perm -0002 -exec ls -ld {} \; 2>/dev/null | tee -a "$REPORT"
log ".ssh directory permissions:"
find /home -type d -name ".ssh" -exec ls -ld {} \; 2>/dev/null | tee -a "$REPORT"
log "SUID/SGID files:"
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f -exec ls -ld {} \; 2>/dev/null | tee -a "$REPORT"

# Service Audits 
log "--- Service Audits ---"
log "Running services:"
systemctl list-units --type=service --state=running | tee -a "$REPORT"
log "Checking for unnecessary services:"
UNNECESSARY_SERVICES=(avahi-daemon cups bluetooth)
for SERVICE in "${UNNECESSARY_SERVICES[@]}"; do
    systemctl is-active --quiet "$SERVICE" && log "Unnecessary service running: $SERVICE"
done
log "Checking for critical services:"
CRITICAL_SERVICES=(sshd ufw)
for SERVICE in "${CRITICAL_SERVICES[@]}"; do
    systemctl is-active --quiet "$SERVICE" || log "Critical service NOT running: $SERVICE"
done

# Firewall and Network 
log "---Firewall and Network Configuration ---"
log "Firewall status:"
ufw status | tee -a "$REPORT"
log "Open ports:"
ss -tuln | tee -a "$REPORT"
log "IP forwarding check:"
sysctl net.ipv4.ip_forward | tee -a "$REPORT"

#IP Address Classification 
log "--- IP Address Classification ---"
ip -o -4 addr show | awk '{print $4}' | while read IP; do
    if [[ $IP =~ ^10\. || $IP =~ ^172\.1[6-9]\. || $IP =~ ^172\.2[0-9]\. || $IP =~ ^172\.3[01]\. || $IP =~ ^192\.168 ]]; then
        log "Private IP: $IP"
    else
        log "Public IP: $IP"
    fi
done
#  Security Updates 
log "---Security Updates ---"
log "Checking for security updates:"
apt-get update -qq
apt list --upgradable 2>/dev/null | grep security | tee -a "$REPORT"
log "Ensuring unattended upgrades are configured:"
dpkg-reconfigure --priority=low unattended-upgrades

#Log Monitoring 
log "---- Log Monitoring ---"
log "Last 10 failed SSH login attempts:"
grep "Failed password" /var/log/auth.log | tail -10 | tee -a "$REPORT"

# Hardening Steps 
log "--- Server Hardening ---"
log "Disabling root password SSH login..."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl reload sshd
log "Disabling IPv6..."
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
log "Securing GRUB bootloader..."
if [ -f /etc/grub.d/40_custom ]; then
    echo "set superusers=\"root\"" >> /etc/grub.d/40_custom
    echo "password_pbkdf2 root $(grub-mkpasswd-pbkdf2 | grep 'grub.pbkdf2' | awk '{print $7}')" >> /etc/grub.d/40_custom
    update-grub
fi
log "Configuring iptables firewall rules..."
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables-save > /etc/iptables/rules.v4

#Custom Security Checks 
log "--- Custom Security Checks ---"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    if declare -f custom_security_checks > /dev/null; then
        custom_security_checks >> "$REPORT"
    fi
else
    log "No custom checks config found."
fi
log "Audit completed. Report saved to $REPORT"
