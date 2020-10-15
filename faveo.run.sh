#!/bin/bash

if [[ $# -lt 8 ]]; then 
    echo "Please run the script by passing all the required arguments."
    exit 1;
fi

echo "Checking Prerequisites....."

apt update && apt install unzip curl -y || yum install unzip curl -y && setenforce 0

if [[ $? -eq 0 ]]; then
    echo "Prerequisites check completed."
else
    echo "Check failed please make sure to execute the script as sudoer and also check your internet connectivity."
    exit 1;
fi
CUR_DIR=$(pwd)
host_root_dir="faveo"
# Evaluate the arguments
while test $# -gt 0; do
        case "$1" in
                -domainname)
                    shift
                    domainname=$1         
                    shift 
                    ;;
                -email)
                    shift
                    email=$1
                    shift
                    ;;
                -license)
                    shift
                    license=$1
                    shift
                    ;;
                -orderno)
                    shift
                    orderno=$1
                    shift
                    ;;
                *)
                echo "$1 is not a recognized flag!"
                exit 1;
                ;;
        esac
done  
echo -e "\n";
echo -e "Confirm the Entered Helpdesk details:\n";
echo -e "-------------------------------------\n"

echo "Domain Name : $domainname";
echo "Email: $email";
echo "License Code: $license";
echo "Order Number: $orderno";
echo -e "\n";
read -p "Continue (y/n)?" REPLY

if [[ ! $REPLY =~ ^(yes|y|Yes|YES|Y) ]]; then
        exit 1;
fi;
 
if [ ! -d $CUR_DIR/certbot/html ]; then
    mkdir -p $CUR_DIR/certbot/html
elif [ ! -e $CUR_DIR/certbot/html ]; then
    exit 0;
fi;

echo "<h1>Obtain SSL Certs</h1>" > $CUR_DIR/certbot/html/index.html

echo -e "Initializing Temporary Apache container to obtain SSL Certificates..."

docker run -dti -p 80:80 -v $CUR_DIR/certbot/html:/usr/local/apache2/htdocs --name apache-cert httpd:2.4.33-alpine

if [[ $? -eq 0 ]]; then
    echo "Initializing Certbot Container to obtain SSL Certificates for $domainname"
    docker run -ti --rm -v $CUR_DIR/certbot/letsencrypt/etc/letsencrypt:/etc/letsencrypt -v $CUR_DIR/certbot/html:/data/letsencrypt --name certbot certbot/certbot certonly --webroot --email $email  --agree-tos --non-interactive  --no-eff-email --webroot-path=/data/letsencrypt -d $domainname
else
    echo "Temporary Container Failed to Initialise exiting..."
    exit 1;
fi;

docker rm -f apache-cert

chown -R $USER:$USER $CUR_DIR/certbot

if [[ $? -eq 0 ]]; then
    echo "SSL Certificates for $domainname obtained Successfully."        
else
    echo "Permission Issue."
    exit 1;
fi;

echo "Downloading Faveo Helpdesk"

curl https://billing.faveohelpdesk.com/download/faveo\?order_number\=$orderno\&serial_key\=$license --output faveo.zip

if [[ $? -eq 0 ]]; then
    echo "Download Successfull";
else
    echo "Download Failed. Please check the order number, serial number of Helpdesk entered and your Internet connectivity."
    exit 1;
fi;

if [ ! -d $CUR_DIR/$host_root_dir ]; then
    unzip faveo.zip -d $host_root_dir
else
    rm -rf $CUR_DIR/$host_root_dir
    unzip faveo.zip -d $host_root_dir
fi

if [ $? -eq 0 ]; then
    chown -R 33:33 $host_root_dir
    find $host_root_dir -type d -exec chmod 755 {} \;
    find $host_root_dir -type f -exec chmod 644 {} \;     
else
    echo "Extract failure."
fi

db_root_pw=$(openssl rand -base64 12)
db_name=faveo
db_user=faveo
db_user_pw=$(openssl rand -base64 12)

if [[ $? -eq 0 ]]; then
    if [[ ! -f apache/$domainname.conf ]]; then
        cp apache/example.conf apache/$domainname.conf
    else
        rm -f apache/$domainname.conf
        cp apache/example.conf apache/$domainname.conf
    fi
    if [[ ! -f .env ]]; then
        cp example.env .env
    else 
        rm -f .env
        cp example.env .env
        sed -i 's:MYSQL_ROOT_PASSWORD=:&'$db_root_pw':' .env
        sed -i 's/MYSQL_DATABASE=/&'$db_name'/' .env
        sed -i 's/MYSQL_USER=/&'$db_user'/' .env
        sed -i 's:MYSQL_PASSWORD=:&'$db_user_pw':' .env
        sed -i 's/DOMAINNAME=/&'$domainname'/' .env
        sed -i 's:example.conf:'$domainname':g' apache/$domainname.conf
        sed -i 's/HOST_ROOT_DIR=/&'$host_root_dir'/' .env
        sed -i 's:CUR_DIR=:&'$PWD':' .env
    fi

    
else
    echo "Unkonw error"
        exit 1;
fi

if [[ $? -eq 0 ]]; then
    docker-compose up -d
else
    echo "Script Failed unknown error."
fi

if [[ $? -eq 0 ]]; then
    echo -e "\n"
    echo "#########################################################################"
    echo -e "\n"
    echo "Faveo Docker installed successfully. Visit https://$domainname from your browser."
    echo "Please save the following credentials."
    echo "Mysql Database root password: $db_root_pw"
    echo "Faveo Helpdesk name: $db_name"
    echo "Faveo Helpdesk DB User: $db_user"
    echo "Faveo Helpdesk DB Password: $db_pw"
    echo -e "\n"
    echo "#########################################################################"
else
    echo "Script Failed unknown error."
    exit 1;
fi

