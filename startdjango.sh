#!/bin/bash
# Script for setting up the environment for the Django project from GitHub






#Check if provision are done
if [ -z "$MYSQL_ROOT_PASSWORD" ]; 
  then
  # $var is empty, do what you want
  echo "MySQL Password does not determined. Maybe you don't launched provisionmysql.sh in shell context?"
  read -p "Do you know MySQL root password? (Y\n)" answer
    case ${answer:0:1} in
        y | Y | yes | YES )
          echo "Please provide MySQL root password"
          read PASSWORD
          export MYSQL_ROOT_PASSWORD=$PASSWORD
        ;;
        * ) 
          echo "Sorry, i can't continue"
          exit
        ;;
    esac

  else
  echo "Ok, OS is provisioned"
fi





if command -v apt-get >/dev/null; then
  echo "apt-get is used here"
  sudo apt update
  sudo apt -y upgrade
  sudo apt install -y python3 python3-pip python3-venv virtualenv mysql-client git
  sudo apt install -y python-autopep8
  if [[ $(lsb_release -rs) == "18.04" ]]; then # replace 8.04 by the number of release you want
      #Version tuning (Cheatcodes=ON)
      sudo apt install -y python3.7 python3-pip
      sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2
  else
       echo "Non-compatible version"
  fi

elif command -v yum >/dev/null; then
  echo "yum is used here"
  #TODO: Write yum packages installing
else
  echo "Sorry, i cant continue, distro is unknown"
fi

# Make a directory
mkdir envs

# Create virtual environment
virtualenv ./envs/

# Activate virtual environment
source envs/bin/activate

# Clone the repository from GitHub
git clone "https://github.com/Manisha-Bayya/simple-django-project.git"

# Install requirements
cd simple-django-project/
pip3 install -r requirements.txt

#Install forgotten requirements
pip3 install django==3.2.10
pip3 install -U "setuptools==44.1.1"
pip3 install pymysql
pip3 install haystack
pip3 install django-phonenumber-field
pip3 install django-phonenumbers
pip3 install django-haystack
pip3 install whoosh

#fix some indian code
pip3 install --upgrade autopep8
sudo apt install -y python-autopep8
autopep8 -i world/models.py

#Load sample data into MySQL
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD  < ~/simple-django-project/world.sql

#MAGIC. edit config with sed and insert to it env variables. Thanks ChatGPB for our happy childhood!!
echo "s/'PASSWORD': '[^']*',\$/'PASSWORD': '\$MYSQL_ROOT_PASSWORD',/g" | envsubst | sed -i -f - ./panorbit/settings.py
echo "s/\s*EMAIL_HOST_USER = '[^']*'\$/EMAIL_HOST_USER = '\$EMAIL_HOST_USER'/g" | envsubst | sed -i -f - ./panorbit/settings.py
echo "s/\s*EMAIL_HOST_PASSWORD = '[^']*'\$/EMAIL_HOST_PASSWORD = '\$EMAIL_HOST_PASSWORD'/g" | envsubst | sed -i -f - ./panorbit/settings.py

#Run project
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py rebuild_index
# Run the Django server on port 8000
echo "Running the Django server on port 8000..."
python3 manage.py runserver 8000

