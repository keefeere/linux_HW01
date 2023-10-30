# Django project deploy tool

This set of scripts is homework for DevOPS01 cource

## TASK:

Task description goes here:

https://github.com/DevOps01-ua/Linux01/blob/main/homework/HW1.md

In few words the scripts should deploy sample project https://github.com/Manisha-Bayya/simple-django-project


## Requirements and preparation:

1. OS distribution - tested with **Debian\Ubuntu\Oracle\Alma\Rocky** linux stale version on september 2023 and minus 2 stable version. May work on other versions but not guaranteed
2. Create linux user without root rights
   ```bash
    #create user
    useradd keefeere
    #add user to sudo like this
    usermod -aG sudo keefeere
    #or this
    echo "keefeere ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo
    #make shure that user's dir is exist and accesible
    mkdir /home/keefeere
    chown keefeere:keefeere /home/keefeere
   ```
3. Ensure that *sudo* is installed and user have sudo rights 
4. In case of using *wsl2* ensure that *systemd* support enabled
    
    To enable, start your Ubuntu (or other Systemd) distribution under WSL (typically just wsl ~ will work).

    Edit file ```/etc/wsl.conf``` like this:
    ```
    sudo -e /etc/wsl.conf
    ```
    Add the following:
    ```bash
    [boot]
    systemd=true
    ```

## USAGE:

### 1. Clone git repository

```bash
git clone "https://github.com/keefeere/linux_HW01.git"
cd linux_HW01
```

### 2. Enter and store user data in environment variables

Open file ```mail_config_example.sh``` with any editor and enter your variables for mail server

Better use GMail but not forget that for SMTP you must enable [passwords for appliations](https://support.google.com/mail/answer/185833https:/)

```bash
export EMAIL_HOST_USER='your_user@gmail.com'
export EMAIL_HOST_PASSWORD='pass'
```
Execute script mail_config_example.sh 

> :bulb: **TIP:** Run with ```. mail_config_example.sh``` not with ```.\mail_config_example.sh``` because this script will be executed in curren shell and script will set current shell environment variables

### 3. Run provision of specific version of Python

This script will install all build dependencies and build specific Python version for you
you may asked of root or sudo password

```bash
cd /your dir
chmod +x provisionmysqlenv.sh
./provisionpython.sh
```
at the end of execution you should see prompt with ENV started

### 4. Run provision of MySQL server 

This will install MySQL server and provision it's root password to main script throught environment variable

Open dir with scripts, set execution rights and run

```bash
cd /your dir
chmod +x provisionmysql.sh
. provisionmysql.sh
```

> :bulb: **TIP:** Run with ```. provisionmysql.sh``` not with ```.\provisionmysql.sh``` because this script will be executed in current shell and script will set current's shell environment variables

### 5. Run main script

In dir with scrips run:

```bash
cp startdjango.sh ~
cd ~
chmod +x startdjango.sh
./startdjango.sh
```

When scrips prompts:
*WARNING: This will irreparably remove EVERYTHING from your search index in connection 'default'.
Your choices after this are to restore from backups or rebuild via the `rebuild_index` command.
Are you sure you wish to continue? [y/N]*
Press ```y```

![Alt text](image.png)
