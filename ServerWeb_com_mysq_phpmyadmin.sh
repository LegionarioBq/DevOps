#!/bin/bash
### Criado por ALBERT ANDRADE
### atualizado 01-06-2023 V1.0
### ATENÇÃO !!!!
### FAZER MODIFICAÇÃO CONFORME SUA MAQUINA LINHAS 50, 51 E 52

# Diretorio Raiz
cd /

# Atualiza a hora
echo "Atualizando a Hora Brasil... "

date
sudo timedatectl set-timezone America/Sao_Paulo
timedatectl
date

# Atualiza os repositórios do sistema
echo "Atualizando os repositórios do sistema... "

sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean

# Instala pacotes essenciais
echo "Instalando Apache2 e bibliotecas do sistema... "

sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql php-cli php-mbstring php-xml php-zip curl git unzip p7zip-full php-fpm php-json php-common php-gd php-curl php-pear php-bcmath

# Configurações do Apache
sudo service apache2.service enable
sudo service apache2 start

echo "Permissão para a pasta WWW... "
# Permissão para a pasta www
sudo chmod 777 -R /var/www

# Configurações do PHP
echo "Instalando e Configurando o PHP... "

sudo service apache2 restart

# Obter a versão do PHP instalada
php_version=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]')

# Configurar as opções do PHP
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" "/etc/php/$php_version/apache2/php.ini"
sudo sed -i "s/;file_uploads = .*/file_uploads = On/" "/etc/php/$php_version/apache2/php.ini"
sudo sed -i "s/;allow_url_fopen = .*/allow_url_fopen = On/" "/etc/php/$php_version/apache2/php.ini"
sudo sed -i "s/memory_limit = .*/memory_limit = 8192M/" "/etc/php/$php_version/apache2/php.ini"
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 20000M/" "/etc/php/$php_version/apache2/php.ini"
sudo sed -i "s/max_execution_time = .*/max_execution_time = 30000/" "/etc/php/$php_version/apache2/php.ini"

sudo service apache2.service restart

# Cria o arquivo para testar o PHP instalado
sudo rm -rf /var/www/html/index.html
echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/index.php

# Configurações do MySQL
sudo service mysql start

echo "Instalando MySQL ..."

# Solicitar ao usuário para inserir o nome de usuário e senha
read -p "Digite o nome de usuário: " username
read -sp "Digite a senha: " password
read -p "Digite o nome do banco de dados: " database_name

echo "Configurando o MySQL..."

# Verificar se a base de dados já existe
existing_databases=$(sudo mysql -e "SHOW DATABASES LIKE '$database_name';" | grep -o "$database_name")

while [ "$existing_databases" = "$database_name" ]; do
    echo "A base de dados $database_name já existe. Por favor, digite outro nome de banco de dados:"
    read -p "Digite o nome do banco de dados: " database_name
    existing_databases=$(sudo mysql -e "SHOW DATABASES LIKE '$database_name';" | grep -o "$database_name")
done

sudo mysql -e "CREATE USER '$username'@'%' IDENTIFIED BY '$password';"
sudo mysql -e "CREATE DATABASE $database_name;"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$username'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES; FLUSH PRIVILEGES;"
sudo sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo service mysql restart

echo "A base de dados $database_name foi criada com sucesso."

# Instala o Composer
echo "Instalando Composer ... "

sudo rm -rf /root/.composer
cd ~
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Instalador verificado'; } else { echo 'Instalador corrompido'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer

# Instala o Node.js
echo "Instalando Node.js ... "

curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# Reinicia o Apache para aplicar as configurações
sudo service apache2 restart

# Instala o IFCONFIG
sudo apt install -y net-tools

# Instala o phpMyAdmin
echo "Instalando phpMyAdmin ..."

sudo apt install -y phpmyadmin
sudo echo "Include /etc/phpmyadmin/apache.conf" | sudo tee -a /etc/apache2/apache2.conf
sudo service apache2 restart

echo "Foi Finalizado a Instalação dos programas --> Servidor Apache2 | php $php_version | mysql | Composer | Node.Js | phpMyAdmin ."