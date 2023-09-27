#!/bin/bash

# Отримати версію дистрибутива
version=$(grep -w 'VERSION_ID' /etc/os-release | cut -d '"' -f 2)
distr=$(grep -w 'ID' /etc/os-release | cut -d '=' -f 2)

#Додавання дистрибутива bookworm-backports до Debian 10
if [[ "$distr" == "debian" && "$version" == "10" ]]; then
    echo "Це Debian 10. Додаємо репозиторій bookworm-backports"
    
    echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/backports.list
    # Додати репозиторій MySQL
    sudo apt-get update
    echo "Репозиторій bookworm-backports успішно додано!"

fi


# Перевірка наявності пакетного менеджера
if [ -x "$(command -v apt-get)" ]; then
    PKG_MANAGER="apt-get"
    PKG_UPDATE="update"
    PKG_UPGRADE="upgrade -y"
    PKG_INSTALL="install -y"
    BUILD_TOOLS=("build-essential" "checkinstall")
    ARCHIVE_TOOLS=("wget" "tar" "gzip" "bzip2" "xz-utils" "git" "gettext-base")
    PYTHON_DEPS=("gdb" "lcov" "pkg-config" "libbz2-dev" "libffi-dev" "libgdbm-dev" "libgdbm-compat-dev" "liblzma-dev" "libncurses5-dev" "libreadline6-dev" "libsqlite3-dev" "libssl-dev" "lzma" "lzma-dev" "tk-dev" "uuid-dev" "zlib1g-dev")
elif [ -x "$(command -v yum)" ]; then
    PKG_MANAGER="yum"
    PKG_UPDATE="update -y"
    PKG_UPGRADE="upgrade -y"
    PKG_INSTALL="install -y --nobest --setopt=skip_missing_names_on_install=True" 
    BUILD_TOOLS=("yum-utils" "make")
    ARCHIVE_TOOLS=("wget" "tar" "gzip" "bzip2" "xz")
    PYTHON_DEPS=("openssl-devel" "bzip2-devel" "libffi-devel" "sqlite-devel" "readline-devel" "ncurses-devel"  "xz-devel" "tk-devel" "zlib-devel") #"gdbm-devel"
    BUILDDEP_TOOL=("yum-builddep python3")
    PKG_GROUPINSTALL="groupinstall -y"
    DEVTOOLS=(""Development Tools"")
    
elif [ -x "$(command -v dnf)" ]; then
    PKG_MANAGER="dnf"
    PKG_UPDATE="update"
    PKG_UPGRADE="upgrade"
    PKG_INSTALL="install -y"
    BUILD_TOOLS=("groupinstall 'Development Tools'")
    ARCHIVE_TOOLS=("wget" "tar" "gzip" "bzip2" "xz")
    PYTHON_DEPS=("openssl-devel" "bzip2-devel" "libffi-devel" "sqlite-devel" "readline-devel" "ncurses-devel" "gdbm-devel" "xz-devel" "tk-devel" "zlib-devel")
elif [ -x "$(command -v zypper)" ]; then
    PKG_MANAGER="zypper"
    PKG_UPDATE="refresh"
    PKG_UPGRADE="update"
    PKG_INSTALL="install -y"
    BUILD_TOOLS=("install -t pattern devel_basis")
    ARCHIVE_TOOLS=("wget" "tar" "gzip" "bzip2" "xz")
    PYTHON_DEPS=("openssl-devel" "bzip2-devel" "libffi-devel" "sqlite-devel" "readline-devel" "ncurses-devel" "gdbm-devel" "xz-devel" "tk-devel" "zlib-devel")
elif [ -x "$(command -v pacman)" ]; then
    PKG_MANAGER="pacman"
    PKG_UPDATE="-Syu"
    PKG_UPGRADE=""
    PKG_INSTALL="-S --noconfirm"
    BUILD_TOOLS=("base-devel")
    ARCHIVE_TOOLS=("wget" "tar" "gzip" "bzip2" "xz")
    PYTHON_DEPS=("openssl" "bzip2" "libffi" "sqlite" "readline" "ncurses" "gdbm" "xz" "tk" "zlib")
else
    echo "Не знайдено підтримуваного пакетного менеджера"
    exit 1
fi



# Перевірка наявності прав root
if [ $(id -u) -eq 0 ]; then
    echo "Увага: з поміркувань безпеки цей скрипт не треба запускати з правами root!"
    exit 1
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



# Оновлення пакетів
$SUDO_CMD $PKG_MANAGER $PKG_UPDATE
if [ -n "$PKG_UPGRADE" ]; then
    $SUDO_CMD $PKG_MANAGER $PKG_UPGRADE
fi

# Встановлення необхідних пакетів для збірки

$SUDO_CMD $PKG_MANAGER $PKG_INSTALL ${BUILD_TOOLS[@]} ${ARCHIVE_TOOLS[@]} ${PYTHON_DEPS[@]}
$SUDO_CMD $PKG_MANAGER $PKG_GROUPINSTALL $DEVTOOLS
$SUDO_CMD $BUILDDEP_TOOL


# Перевірка наявності архіваторів та виведення тексту помилки, якщо їх немає
if ! [ -x "$(command -v tar)" ] || ! [ -x "$(command -v gzip)" ] || ! [ -x "$(command -v bzip2)" ] || ! [ -x "$(command -v xz)" ]; then
    echo "Не знайдено необхідних архіваторів (tar, gzip, bzip2, xz) після встановлення пакетів. Встановіть архіватори та перезапустіть программу"
    exit 1
fi



# Перевірка наявності wget
if  ! [ -x "$(command -v wget)" ]; then
    echo "Не знайдено wget після встановлення пакетів. Встановіть wget та перезапустіть программу"
    exit 1
fi


# Перевірка наявності make
if  ! [ -x "$(command -v make)" ]; then
    echo "Не знайдено make після встановлення пакетів. Встановіть make та перезапустіть программу"
    exit 1
fi




# Завантаження та розпакування Python 3.7.2
cd ~
wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz
tar xzf Python-3.7.2.tgz


cd Python-3.7.2




#Патч похідного коду
#https://github.com/pyenv/pyenv-virtualenv/issues/410#issuecomment-1125942002



cat <<EOT >> alignment.patch
--- Include/objimpl.h
+++ Include/objimpl.h
@@ -250,7 +250,7 @@
         union _gc_head *gc_prev;
         Py_ssize_t gc_refs;
     } gc;
-    double dummy;  /* force worst-case alignment */
+    long double dummy;  /* force worst-case alignment */
 } PyGC_Head;

 extern PyGC_Head *_PyGC_generation0;
--- Objects/obmalloc.c
+++ Objects/obmalloc.c
@@ -643,8 +643,8 @@
  *
  * You shouldn't change this unless you know what you are doing.
  */
-#define ALIGNMENT               8               /* must be 2^N */
-#define ALIGNMENT_SHIFT         3
+#define ALIGNMENT               16               /* must be 2^N */
+#define ALIGNMENT_SHIFT         4

 /* Return the number of bytes in size class I, as a uint. */
 #define INDEX2SIZE(I) (((uint)(I) + 1) << ALIGNMENT_SHIFT)
EOT

patch -p0 < alignment.patch



# Збірка та встановлення Python 3.7.2



#sudo apt install gcc-10
#CC=gcc-10 
#make -j 8 




./configure --enable-optimizations --with-ensurepip=install --prefix=$HOME/python3.7
#./configure --enable-optimizations --with-ensurepip=install #--enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
#CC=gcc-10 
make altinstall

# Створення венв та активація його
cd ~
./Python-3.7.2/python -m venv myenv 
source myenv/bin/activate

