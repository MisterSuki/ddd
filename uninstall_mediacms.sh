#!/bin/bash

# Variables
INSTALL_DIR="/home/suki/mediacms"  # Remplace par le chemin de ton installation de MediaCMS
DB_NAME="mediacms_db"
DB_USER="mediacms_user"
SERVICE_NAME="mediacms"

# Vérifier si l'utilisateur est root
if [ "$EUID" -ne 0 ]; then
  echo "Merci de lancer le script avec les droits administrateur (sudo)." 
  exit 1
fi

# 1. Arrêter et désactiver le service MediaCMS
echo "Arrêt du service MediaCMS..."
systemctl stop $SERVICE_NAME
systemctl disable $SERVICE_NAME

# 2. Supprimer les fichiers MediaCMS
echo "Suppression des fichiers MediaCMS..."
rm -rf $INSTALL_DIR

# 3. Supprimer l'environnement virtuel (si utilisé)
if [ -d "$INSTALL_DIR/venv" ]; then
  echo "Suppression de l'environnement virtuel..."
  rm -rf "$INSTALL_DIR/venv"
fi

# 4. Supprimer la base de données PostgreSQL (ou MySQL)
echo "Suppression de la base de données et de l'utilisateur..."
echo "Supprimer PostgreSQL (si c'est utilisé)..."
sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;
EOF

echo "Supprimer MySQL (si c'est utilisé)..."
mysql -u root -p <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS '$DB_USER'@'localhost';
EOF

# 5. Supprimer le service systemd
echo "Suppression du service systemd..."
rm /etc/systemd/system/$SERVICE_NAME.service
systemctl daemon-reload

# 6. Supprimer les dépendances Python (facultatif)
echo "Suppression des dépendances Python liées à MediaCMS..."
pip3 uninstall -y django
pip3 freeze | grep mediacms | xargs pip3 uninstall -y

# 7. Supprimer les configurations Nginx/Apache (facultatif)
echo "Suppression des fichiers de configuration Nginx..."
rm -f /etc/nginx/sites-available/mediacms
rm -f /etc/nginx/sites-enabled/mediacms
systemctl reload nginx

echo "Suppression des fichiers de configuration Apache..."
a2dissite mediacms.conf
rm -f /etc/apache2/sites-available/mediacms.conf
systemctl reload apache2

echo "Désinstallation complète de MediaCMS terminée."
