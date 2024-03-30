#! /bin/bash

# ================================
# Ensure the script is run with root privileges.
# ===================================================
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# ================================
# Create helper functions.
# ===================================================
printLines() {
  local content="$1"
  local colorGreen='\033[0;32m'
  local noColor='\033[0m'

  echo -e "\n"
  echo -e "${colorGreen}# =======================================================${noColor}"
  echo -e "${colorGreen}# $content${noColor}"
  echo -e "${colorGreen}# =======================================================${noColor}"
  echo -e "\n"
}

printLine() {
	local content="$1"
	# Print in yellow color.
	local color='\033[0;33m'

	echo -e "${color}# $content${noColor}"
}

# ================================
# Update and upgrade the system.
# ===================================================
printLines "⌛ Doing - system update and upgrade."
sleep 2

apt update -y
apt upgrade -y

sleep 2
printLines "✅ Done, updating and upgrading the system."

# ================================
# Update timezone & hostname.
# ===================================================
printLines "⌛ Doing - setting timezone and hostname."
sleep 2

timedatectl set-timezone Asia/Kathmandu
hostnamectl set-hostname vm-anujsubedi

# Print time and hostname.
timedatectl
echo -e "\n"
hostnamectl

printLines "✅ Done, setting up timezone and hostname."
sleep 2

# ================================
# Installed nginx.
# ===================================================
printLines "⌛ Doing - install nginx."
sleep 2

apt install nginx -y
mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

sudo enable nginx
sudo start nginx

sleep 2
printLines "✅ Success, nginx installed."


# ================================
# Add HTTP, HTTPS, SSH, and Nginx Full to the UFW firewall.
# ===================================================
printLines "⌛ Doing - add port to UFW."
sleep 2

ufw allow 'Nginx Full'
ufw allow 'OpenSSH'

# Pass yes to the prompt.
echo "y" | ufw enable

printLines "✅ Port added to firewall UFW."
sleep 2

# ================================
# Install Docker, io, compose and cli.
# ===================================================
printLines "⌛ Doing - Install docker."
sleep 2

apt update -y
apt install ca-certificates curl
apt install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update repo.
apt update -y
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sleep 2
printLines "✅ Done, installing docker, io, cli and compose."

# ================================
# Install PHP 8.1, FPM, and other necessary PHP extensions for running WordPress.
# ===================================================
printLines "⌛ Doing - Installing PHP 8.2."
sleep 2

echo -ne '\n' | add-apt-repository ppa:ondrej/php # Execute the enter key too.

apt update -y

apt install php8.2-cli php8.2-common php8.2-fpm php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath -y

sleep 2
printLines "✅ Done, installing PHP 8.1 and common extensions."

# ================================
# Install mariaDB.
# ===================================================
printLines "⌛ Doing - Install MariaDB server."
sleep 2

apt install expect -y 
apt install mariadb-server -y

sleep 2
printLines "✅ Success, MariaDB installed."

# Enable.
systemctl enable mariadb.service
systemctl start mariadb.service

# Prepare variables for MariaDB installation.
PASSWORD="anujsubedi"
USERNAME="anujsubedi"
DATABASE="admin-db"

printLines "⌛ Doing - Secure MariaDB installation. This might take some time."

# Secure MariaDB installation
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Press y|Y for Yes, any other key for No:\"
send \"y\r\"
expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
send \"2\r\"
expect \"New password:\"
send \"$PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$PASSWORD\r\"
expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"

# Create a new user and grant privileges
mysql -u root -p"$PASSWORD" -e "CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$PASSWORD';"
mysql -u root -p"$PASSWORD" -e "GRANT ALL PRIVILEGES ON $DATABASE.* TO '$USERNAME'@'localhost';"
mysql -u root -p"$PASSWORD" -e "FLUSH PRIVILEGES;"

printLines "✅ MariaDB secure installation completed. Below are the credentials."
sleep 2

# Print credentials.
printLine "MariaDB root credentials: "
echo -e "Username: $USERNAME"
echo -e "Password: $PASSWORD"

# Create new db, user and deligate all privileges.
WPDB="enchanted-db"
WPUSER="admin"
WPPASS="admin"

printLines "⌛ Doing - Create new db for WordPress."
sleep 2

mysql -u root -p"$PASSWORD" -e "CREATE DATABASE $WPDB;"
mysql -u root -p"$PASSWORD" -e "CREATE USER '$WPUSER'@'localhost' IDENTIFIED BY '$WPPASS';"
mysql -u root -p"$PASSWORD" -e "GRANT ALL PRIVILEGES ON $WPDB.* TO '$WPUSER'@'localhost';"
mysql -u root -p"$PASSWORD" -e "FLUSH PRIVILEGES;"

sleep 2
printLines "✅ Success, new db created for WordPress. Below is the credentials of db."

# Print credentials.
printLine "WP DB Credentials: "
echo -e "Database: $WPDB"
echo -e "Username: $WPUSER"
echo -e "Password: $WPPASS"

# ================================
# Create nginx configuration file.
# ===================================================
sleep 5
printLines "⌛ Doing - Create nginx configuration file."

cd /etc/nginx/sites-available

touch anujsubedi.com

cat <<EOF > anujsubedi.com
server {
		listen 80;
		listen [::]:80;

		root /var/www/html;
		index index.php index.html index.htm;

		server_name anujsubedi.com www.anujsubedi.com;

		location / {
			try_files \$uri \$uri/ =404;
		}

		location ~ \.php$ {
			include snippets/fastcgi-php.conf;
			fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
		}

		location ~ /\.ht {
			deny all;
		}
}
EOF

sudo ln -s /etc/nginx/sites-available/anujsubedi.com /etc/nginx/sites-enabled/

# Remove default configuration.
rm /etc/nginx/sites-enabled/default

# Test configuration.
nginx -t

# Restart nginx.
systemctl restart nginx

sleep 2
printLines "✅ Success, nginx configuration file created."

# ================================
# Install Git.
# ===================================================
sleep 2
printLines "⌛ Doing - Installing Git."

apt install git -y
apt update -y

sleep 2
printLines "✅ Success, Git installed."

# ================================
# Download WordPress.
# ===================================================
sleep 2
printLines "⌛ Doing - Download WordPress."

cd /var/www/html

wget https://wordpress.org/latest.tar.gz

tar -xvf latest.tar.gz

mv wordpress/* .

rm -rf wordpress latest.tar.gz
rm index.nginx-debian.html

# Change ownership.
chown -R www-data:www-data /var/www/html

printLines "✅ Success, WordPress downloaded. Installing WordPress."
sleep 2

# ================================
# Install WordPress.
# ===================================================
printLines "⌛ Doing - Installing WordPress."

cd /var/www/html

mv wp-config-sample.php wp-config.php

# Update credentials.
sleep 2
printLines "⌛ Setting wp-config.php."

sed -i "s/database_name_here/$WPDB/g" wp-config.php
sed -i "s/username_here/$WPUSER/g" wp-config.php
sed -i "s/password_here/$WPPASS/g" wp-config.php

# Remove default salts.
sleep 2
printLines "⌛ Setting, WordPress salts."

sed -i '/AUTH_KEY/d' wp-config.php
sed -i '/SECURE_AUTH_KEY/d' wp-config.php
sed -i '/LOGGED_IN_KEY/d' wp-config.php
sed -i '/NONCE_KEY/d' wp-config.php
sed -i '/AUTH_SALT/d' wp-config.php
sed -i '/SECURE_AUTH_SALT/d' wp-config.php
sed -i '/LOGGED_IN_SALT/d' wp-config.php
sed -i '/NONCE_SALT/d' wp-config.php

# WordPress salts.
curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php

# Print.
printLines "✅ Success, WordPress installed."

# Get IP address.
IP=$(hostname -I | awk '{print $1}')

echo -e "🌍 WORPRESS URL: http://${IP} ✨"

# ================================
# Finalize.
# ===================================================
printLines "✨ Done, everything completed. Exiting...✨"