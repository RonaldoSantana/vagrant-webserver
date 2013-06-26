#!/bin/bash

# if apache2 does no exist
if [ ! -f /etc/apache2/apache2.conf ];
then
	apt-get update

	# Install MySQL
	echo 'mysql-server-5.5 mysql-server/root_password password vipper' | debconf-set-selections
	echo 'mysql-server-5.5 mysql-server/root_password_again password vipper' | debconf-set-selections
	apt-get -y install mysql-client mysql-server
	
	# Install PostgreSQL
	apt-get -y install postgresql libpq-dev
	apt-get -y install postgresql-client-common

	# Install Apache2
	apt-get -y install apache2
	
	# change the document root to vagrant shared folder
	rm -rf /var/www
	ln -fs /vagrant/www /var/www

	# Install PHP5 support - including mysql and postgresql
	apt-get -y install php5 libapache2-mod-php5 php-apc php5-mysql php5-dev php5-mcrypt php5-pgsql

	# Install SSL tools
	#apt-get -y install ssl-cert
	
	# Install OpenSSL
	apt-get -y install openssl

	# Install PHP pear
	apt-get -y install php-pear

	# Install sendmail
	# apt-get -y install sendmail

	# Install CURL dev package
	apt-get -y install libcurl4-openssl-dev

	# Install Perl
	apt-get -y install perl

	#python
	sudo apt-get -y install python-setuptools
	sudo easy_install http://cheeseshop.python.org/packages/source/p/pyparsing/pyparsing-1.5.5.tar.gz
	sudo easy_install markdown

	#curl
	sudo apt-get install curl

	#composer
	curl -sS https://getcomposer.org/installer | php
	#make composer executable and accessible by just typing composer
	sudo mkdir /usr/local/bin/composer
	sudo mv composer.phar /usr/local/bin/composer


	# Install PECL HTTP (depends on php-pear, php5-dev, libcurl4-openssl-dev)
	printf "\n" | pecl install pecl_http

	# Enable PECL HTTP
	echo "extension=http.so" > /etc/php5/conf.d/http.ini

    # set server name
	echo "ServerName webserver.domain.com" > /etc/apache2/httpd.conf

	# Enable mod_rewrite	
	a2enmod rewrite

	# Enable SSL
	a2enmod ssl

	# Add www-data to vagrant group
	usermod -a -G vagrant www-data
	
	# Restart services
	# /etc/init.d/apache2 restart
	
	# ZSH
	apt-get -y install zsh

	# Vim
	apt-get -y install vim
	
	# Clean up apt-get packages
	apt-get -y clean
fi

# Ensures if the specified file is present and the md5 checksum is equal
ensureFilePresentMd5 () {
    source=$1
    target=$2
    if [ "$3" != "" ]; then description=" $3"; else description=" $source"; fi
 
    md5source=`md5sum ${source} | awk '{ print $1 }'`
    if [ -f "$target" ]; then md5target=`md5sum $target | awk '{ print $1 }'`; else md5target=""; fi

    if [ "$md5source" != "$md5target" ];
    then
        echo "Provisioning$description file to $target..."
        cp $source $target
        echo "...done"
        return 1
    else
        return 0
    fi
}

# Ensures that the specified symbolic link exists and creates it otherwise
ensureSymlink () {
    target=$1
    symlink=$2
    if ! [ -L "$symlink" ];
    then
        ln -s $target $symlink
        echo "Created symlink $symlink that references $target"
        return 1
    else
        return 0
    fi
}

# Provision commands
provision() {
    # Hosts file
    rm /etc/hosts
    ensureSymlink /vagrant/vagrant-data/hosts /etc/hosts
	
	#mysql extra configuration
	sudo -s
	mysql -u root -pvipper -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION; FLUSH PRIVILEGES;"
	
	#extra php settings
	rm /etc/php5/apache2/php.ini
	sudo rm /etc/php5/cli/php.ini
	# cp /vagrant/vagrant-data/conf/php.ini /etc/php5/apache2/php.ini
	# cp /vagrant/vagrant-data/conf/php.ini /etc/php5/cli/php.ini
	ensureSymlink /vagrant/vagrant-data/conf/php.ini /etc/php5/apache2/php.ini
	ensureSymlink /vagrant/vagrant-data/conf/php.ini /etc/php5/cli/php.ini

    # MySQL custom settings
    # ensureFilePresentMd5 /vagrant/vagrant-data/mysql/custom.cnf /etc/mysql/conf.d/custom.cnf "custom MySQL settings"
    # if [ "$?" = 1 ]; then echo "Restarting MySQL..."; service mysql restart; echo "...done"; fi

    # Set symbolic link to phpMyAdmin
    # ensureSymlink /usr/share/phpmyadmin /vagrant/www/global/phpMyAdmin

    # Set symbolic link to VistualHost files
    ensureSymlink /vagrant/vagrant-data/vhosts/global.conf /etc/apache2/sites-enabled/global.conf
	ensureSymlink /vagrant/vagrant-data/vhosts/modica.conf /etc/apache2/sites-enabled/modica.conf
	ensureSymlink /vagrant/vagrant-data/vhosts/digital.conf /etc/apache2/sites-enabled/digital.conf
	ensureSymlink /vagrant/vagrant-data/vhosts/myeasyweb.conf /etc/apache2/sites-enabled/myeasywebß.conf
	
	# Restart services
	/etc/init.d/apache2 restart
	
    return 0
}

provision