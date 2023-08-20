#!/bin/bash

###Provision MySQL server and user data


#Enter your variables
export EMAIL_HOST_USER='your_user@gmail.com'
export EMAIL_HOST_PASSWORD='pass'

# Generate a random password for root user
PASSWORD=$(date +%s | sha256sum | base64 | head -c 16)
# Save the password in an environment variable
export MYSQL_ROOT_PASSWORD=$PASSWORD
# Install MySQL server
sudo apt-get update
sudo apt -y upgrade
sudo apt-get install mysql-server -y
# Start MySQL service
sudo service mysql start
# Create a .sql file with the commands to grant all privileges to root user
cat > grant.sql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
# Execute the .sql file using mysql command
sudo mysql < grant.sql
# Delete the .sql file
rm grant.sql
# Print the password for reference
echo "The password for root@localhost is: $PASSWORD"

echo "$PASSWORD" > MySQLRootPass.log