#!/bin/bash

# Script to secure a Kali Linux system booted from a USB drive
# Author: elryan7
# License: MIT
# Features: Disable unnecessary services, configure firewall, randomize MAC, secure SSH, set up temporary user, enable updates

# Configuration
INTERFACE="eth0"  # Default network interface (verify with 'ip a')
LOG_DIR="/root/security_logs"
TIMESTAMP=$(date +%F_%H-%M-%S)
TEMP_USER="tempuser"
SSH_PORT=2222  # Non-standard SSH port for added security
mkdir -p $LOG_DIR

# Gestion des interruptions
trap cleanup INT

# Vérification des dépendances
check_tools() {
    TOOLS=("ufw" "macchanger" "systemctl" "apt")
    for tool in "${TOOLS[@]}"; do
        if ! command -v $tool &> /dev/null; then
            echo "[!] $tool n'est pas installé. Installez-le avec : sudo apt-get install $tool"
            exit 1
        fi
    done
    echo "[+] Toutes les dépendances sont présentes."
}

# Désactivation des services inutiles
disable_services() {
    echo "[*] Désactivation des services inutiles..."
    UNNECESSARY_SERVICES=("bluetooth" "cups" "avahi-daemon" "rpcbind" "nfs-common")
    for service in "${UNNECESSARY_SERVICES[@]}"; do
        if systemctl is-active --quiet $service; then
            systemctl stop $service &>> $LOG_DIR/services_$TIMESTAMP.log
            systemctl disable $service &>> $LOG_DIR/services_$TIMESTAMP.log
            echo "[+] Service $service désactivé."
        else
            echo "[+] Service $service déjà inactif."
        fi
    done
}

# Configuration du pare-feu (UFW)
setup_firewall() {
    echo "[*] Configuration du pare-feu UFW..."
    ufw reset &>> $LOG_DIR/ufw_$TIMESTAMP.log
    ufw default deny incoming &>> $LOG_DIR/ufw_$TIMESTAMP.log
    ufw default allow outgoing &>> $LOG_DIR/ufw_$TIMESTAMP.log
    ufw allow $SSH_PORT/tcp &>> $LOG_DIR/ufw_$TIMESTAMP.log
    ufw enable &>> $LOG_DIR/ufw_$TIMESTAMP.log
    echo "[+] Pare-feu configuré : seules les connexions SSH ($SSH_PORT) sont autorisées en entrée."
}

# Randomisation de l'adresse MAC
randomize_mac() {
    echo "[*] Randomisation de l'adresse MAC..."
    ip link set $INTERFACE down
    macchanger -r $INTERFACE &>> $LOG_DIR/macchanger_$TIMESTAMP.log
    ip link set $INTERFACE up
    echo "[+] Nouvelle adresse MAC : $(macchanger -s $INTERFACE | grep Current | awk '{print $3}')"
}

# Création d'un utilisateur temporaire non privilégié
create_temp_user() {
    echo "[*] Création de l'utilisateur temporaire $TEMP_USER..."
    if ! id $TEMP_USER &> /dev/null; then
        useradd -m -s /bin/bash $TEMP_USER &>> $LOG_DIR/user_$TIMESTAMP.log
        echo "$TEMP_USER:TempPass123" | chpasswd &>> $LOG_DIR/user_$TIMESTAMP.log
        echo "[+] Utilisateur $TEMP_USER créé avec mot de passe 'TempPass123'."
    else
        echo "[+] Utilisateur $TEMP_USER existe déjà."
    fi
}

# Sécurisation de SSH
secure_ssh() {
    echo "[*] Sécurisation de la configuration SSH..."
    SSH_CONFIG="/etc/ssh/sshd_config"
    cp $SSH_CONFIG $SSH_CONFIG.bak_$TIMESTAMP
    sed -i "s/^#Port 22/Port $SSH_PORT/" $SSH_CONFIG
    sed -i "s/^PermitRootLogin .*/PermitRootLogin no/" $SSH_CONFIG
    sed -i "s/^#PasswordAuthentication .*/PasswordAuthentication no/" $SSH_CONFIG
    sed -i "s/^#PermitEmptyPasswords .*/PermitEmptyPasswords no/" $SSH_CONFIG
    systemctl restart sshd &>> $LOG_DIR/ssh_$TIMESTAMP.log
    echo "[+] SSH configuré : port $SSH_PORT, connexion root désactivée, authentification par mot de passe désactivée."
}

# Activation des mises à jour automatiques
enable_auto_updates() {
    echo "[*] Configuration des mises à jour automatiques..."
    apt-get update &>> $LOG_DIR/updates_$TIMESTAMP.log
    apt-get install -y unattended-upgrades &>> $LOG_DIR/updates_$TIMESTAMP.log
    dpkg-reconfigure --priority=low unattended-upgrades &>> $LOG_DIR/updates_$TIMESTAMP.log
    echo "[+] Mises à jour automatiques activées."
}

# Nettoyage
cleanup() {
    echo "[*] Nettoyage..."
    ip link set $INTERFACE down
    macchanger -p $INTERFACE &>> $LOG_DIR/macchanger_$TIMESTAMP.log
    ip link set $INTERFACE up
    echo "[+] Adresse MAC restaurée."
    echo "[+] Nettoyage terminé."
    exit 0
}

# Résumé
summarize_results() {
    echo "[*] Résumé des actions effectuées :"
    echo "- Services inutiles désactivés : voir $LOG_DIR/services_$TIMESTAMP.log"
    echo "- Pare-feu UFW configuré : connexions entrantes limitées à SSH (port $SSH_PORT)"
    echo "- Adresse MAC randomisée"
    echo "- Utilisateur temporaire $TEMP_USER créé (si applicable)"
    echo "- SSH sécurisé : port $SSH_PORT, connexion root et mots de passe désactivés"
    echo "- Mises à jour automatiques activées"
    echo "- Logs : $LOG_DIR"
}

# Exécution principale
echo "[*] Sécurisation du système Kali Linux..."

check_tools
disable_services
setup_firewall
randomize_mac
create_temp_user
secure_ssh
enable_auto_updates
cleanup
summarize_results

echo "[+] Sécurisation terminée. Consultez $LOG_DIR pour les logs."
