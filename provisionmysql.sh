#!/bin/bash



# Перевірка наявності пакетного менеджера
if [ -x "$(command -v apt-get)" ]; then
    PKG_MANAGER="apt-get"
    PKG_INSTALL="install -y"
	PKG_UPDATE="update"
    PKG_UPGRADE="upgrade -y"
	MYSQL_SERVER="mysql-server"
   
elif [ -x "$(command -v yum)" ]; then
    PKG_MANAGER="yum"
	PKG_UPDATE="update -y"
    PKG_UPGRADE="upgrade -y"
    PKG_INSTALL="install -y --nobest"
	MYSQL_SERVER="mysql-server"
    
    
elif [ -x "$(command -v dnf)" ]; then
    PKG_MANAGER="dnf"
    PKG_INSTALL="install -y"
	PKG_UPDATE="update"
    PKG_UPGRADE="upgrade"
	MYSQL_SERVER="mysql-server"
	
    
elif [ -x "$(command -v zypper)" ]; then
    PKG_MANAGER="zypper"
	PKG_UPDATE="refresh"
    PKG_UPGRADE="update"
    PKG_INSTALL="install -y"
	MYSQL_SERVER="mysql-server"
    
elif [ -x "$(command -v pacman)" ]; then
    PKG_MANAGER="pacman"
	PKG_UPDATE="-Syu"
    PKG_UPGRADE=""
    PKG_INSTALL="-S --noconfirm"
    MYSQL_SERVER="mysql-server"
	
else
    echo "Не знайдено підтримуваного пакетного менеджера"
    exit 1
fi




# Перевірка наявності прав root
if [ $(id -u) -eq 0 ]; then
    echo "Є root права!"
else
    # Перевірка наявності команди sudo
    if command -v sudo &> /dev/null; then
        SUDO_CMD="sudo"
        echo "Команда sudo знайдена: $SUDO_CMD"
    else
        # Перевірка наявності команди su
        if command -v su &> /dev/null; then
            SU_CMD=$(command -v su)
            echo "Команда su знайдена: $SU_CMD"
            echo "Спроба запустити su та встановити sudo. Треба знати пароль root користувача"
            su -c "$PKG_MANAGER $PKG_UPDATE && $PKG_MANAGER $PKG_UPGRADE && $PKG_MANAGER $PKG_INSTALL sudo"
            current_user=$(whoami)
            su -c "sudo usermod -aG sudo $current_user"
            su -c "echo \"$current_user ALL=(ALL:ALL) ALL\" | sudo EDITOR='tee -a' visudo"


        else
            echo "Помилка: команди sudo або su не знайдено. Вихід..."
            exit 1
        fi
    fi
fi






# Отримати версію дистрибутива
version=$(grep -w 'VERSION_ID' /etc/os-release | cut -d '"' -f 2)
distr=$(grep -w 'ID' /etc/os-release | cut -d '=' -f 2)

# Перевірити, чи це Debian 12
#if [[ "$distr" == "debian" && c ]]; then
if [[ "$distr" == "debian" ]]; then
    echo "Це Debian. Додаємо репозиторій MySQL..."
    
    # Додати репозиторій MySQL
    $SUDO_CMD apt-get install lsb-release -y
    wget https://dev.mysql.com/get/mysql-apt-config_0.8.25-1_all.deb
    $SUDO_CMD dpkg -i mysql-apt-config_0.8.25-1_all.deb
    $SUDO_CMD apt-get update
    
    echo "Репозиторій MySQL успішно додано!"
	
	$SUDO_CMD apt-get install -y systemctl
	
		
else
    echo "Це не Debian. Репозиторій MySQL не було додано."
fi



if [[ "$PKG_MANAGER" == "yum" ]]; then

    echo "Додаємо репозиторій MySQL для yum... "
    wget https://repo.mysql.com//mysql80-community-release-el7-6.noarch.rpm
    $SUDO_CMD yum -y install mysql80-community-release-el7-6.noarch.rpm
    $SUDO_CMD rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022


fi




# Оновлення пакетів
$SUDO_CMD_CMD $PKG_MANAGER $PKG_UPDATE
if [ -n "$PKG_UPGRADE" ]; then
    $SUDO_CMD_CMD $PKG_MANAGER $PKG_UPGRADE
fi


# Generate a random password for root user
PASSWORD=$(date +%s | sha256sum | base64 | head -c 16)
# Save the password in an environment variable
export MYSQL_ROOT_PASSWORD=$PASSWORD

#to suppres questions on Debian
export DEBIAN_FRONTEND=noninteractive


$SUDO_CMD -E $PKG_MANAGER $PKG_INSTALL $MYSQL_SERVER
$SUDO_CMD service mysql start
	

$SUDO_CMD chown -R mysql: /var/run/mysqld
$SUDO_CMD sed -i --follow-symlinks 's|ExecStartPre=+|ExecStartPre=/bin/bash |g' /etc/systemd/system/multi-user.target.wants/mysql.service
$SUDO_CMD systemctl reload
$SUDO_CMD systemctl enable mysqld
$SUDO_CMD systemctl start mysql
$SUDO_CMD systemctl start mysqld

cat > grant.sql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
# Execute the .sql file using mysql command
$SUDO_CMD mysql < grant.sql
# Delete the .sql file
rm grant.sql
# Print the password for reference
echo "The password for root@localhost is: $PASSWORD"

echo "$PASSWORD" > MySQLRootPass.log