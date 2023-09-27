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




# Clone the repository from GitHub
git clone "https://github.com/Manisha-Bayya/simple-django-project.git"

# Install requirements
cd simple-django-project/
#pip3 install -r requirements.txt

#Install forgotten requirements
pip3 install django==1.11.29


#setuptools is needed for succesful installing of haystack
#https://github.com/googleapis/google-cloud-python/issues/3884
pip3 install -U "setuptools==44.1.1"

#From pipreqs and original requirements.txt
#pip3 install pymysql
pip3 install PyMySQL==0.9.3
pip3 install django-haystack==2.8.1
pip3 install django-phonenumber-field==2.2.0
pip3 install phonenumbers==8.9.6

# raise MissingDependency("The 'whoosh' backend requires the installation of 'Whoosh'. Please refer to the documentation.")
pip3 install whoosh==2.7.4


#Old
# pip3 install django==1.11.29
# pip3 install -U "setuptools==44.1.1"
# pip3 install pymysql
# pip3 install django-phonenumber-field==2.2.0
# pip3 install phonenumbers==8.9.6
# pip3 install django-haystack==2.8.1
# pip3 install whoosh==2.7.4


#fix some indian code
pip3 install --upgrade autopep8
#sudo apt install -y python-autopep8
autopep8 -i world/models.py

#Load sample data into MySQL
#sudo 
mysql -u root -p$MYSQL_ROOT_PASSWORD  < ~/simple-django-project/world.sql

#MAGIC. edit config with sed and insert to it env variables. Thanks ChatGPT for our happy childhood!!
echo "s/'PASSWORD': '[^']*',\$/'PASSWORD': '\$MYSQL_ROOT_PASSWORD',/g" | envsubst | sed -i -f - ./panorbit/settings.py
echo "s/\s*EMAIL_HOST_USER = '[^']*'\$/EMAIL_HOST_USER = '\$EMAIL_HOST_USER'/g" | envsubst | sed -i -f - ./panorbit/settings.py
echo "s/\s*EMAIL_HOST_PASSWORD = '[^']*'\$/EMAIL_HOST_PASSWORD = '\$EMAIL_HOST_PASSWORD'/g" | envsubst | sed -i -f - ./panorbit/settings.py

#Run project
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py rebuild_index
# Run the Django server on port 8001
echo "Running the Django server on port 8001..."
python3 manage.py runserver 8001

