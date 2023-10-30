1. Check system requirements:
   * MySQL presence? Version?
   * Python presence? Version?
   * PIP presence? Version?
   * virtualenv presence? Version?
   * mysql-client presence? Version?
   * python-autopep8
  ....
2. Try to satisfy requirements:
   1. Install packages?
   2. User interaction if fails
3. Аctivate VirtualEnvironment
4. Install application requirements that desctibed in requirements.txt
5. Install mising application requirements:
   * django==3.2.10
   * setuptools==44.1.1"
   * pymysql
   * haystack
   * django-phonenumber-field
   * django-phonenumbers
   * django-haystack
   * whoosh
   * TODO: Write versions?
6. Path world/models.py with autopep8 
7. Load sample data provided by application developer into MySQL
8. Populate application config ./panorbit/settings.py with data. Check if that data present?
   * MySQL Pass
   * Email data
9. Run preparation described in application:
   * python3 manage.py makemigrations
   * python3 manage.py migrate
   * python3 manage.py rebuild_index
10. Check if port 8000 is free? 
11. Run application
    * python3 manage.py runserver 8000