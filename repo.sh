 #!/bin/bash

#Install tools, createpo, reposync, firewalld and nginx

yum -y update 
yum -y install yum-utils 
yum -y install createrepo epel-release firewalld  && yum -y install nginx

#Make directory to place files for repo

mkdir -p /var/www/html/repos 

#Move config file for ngnix and then edit file 

mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig 

# Create nginx config file

cat > /etc/nginx/nginx.conf << EOF

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;
}
EOF

# Create Port 80 VirtualHost

cat > /etc/nginx/conf.d/repo80.conf << EOF

 server {
    listen  80;
    server_name  172.16.2.23;
    # return 301 https://$host$request_uri;
    root  /var/www/html/repos;

    location  / {
        autoindex  on;
    }

}
EOF


# Create Port 443 Virtualhost

# cat > /etc/nginx/conf.d/sslrepo << EOF
# server {
#    listen 443 http2 ssl;
#    listen [::]:443 http2 ssl;

#        server_name  172.16.2.23;

# root  /var/www/html/repos;

#    location  / {
#        autoindex  on;
#    }


#    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
#    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
#    ssl_dhparam /etc/ssl/certs/dhparam.pem;
#  }
#EOF



# Restart nginx

service nginx restart 

# Add Repo for Icgina, Salt and Docker

# Icgina Repo
sudo rpm --import http://packages.icinga.org/icinga.key
sudo rpm -i https://packages.icinga.org/epel/7/release/noarch/icinga-rpm-release-7-1.el7.centos.noarch.rpm

#salt stack repo

yum -y install  https://repo.saltstack.com/yum/redhat/salt-repo-latest-1.el7.noarch.rpm 

#docker repo

yum-config-manager \
    --add-repo \
    https://docs.docker.com/engine/installation/linux/repo_files/centos/docker.repo

 yum clean all 
 yum update -y 


# enable firewall traffic

systemctl enable nginx.service && systemctl enable firewalld.service

systemctl start firewalld.service

firewall-cmd --permanent --add-service=http

firewall-cmd --permanent --add-service=https

firewall-cmd --permanent --add-service=ssh

firewall-cmd --reload


# Sync Repos this will take awhile
cd /var/www/html/repos
reposync -r base 
reposync -r updates 
reposync -r extras  
reposync -r salt-latest 
reposync -r docker-ce-stable
reposync -r epel 

# Create repos this will take awhile

createrepo    /var/www/html/repos/base
createrepo   /var/www/html/repos/updates
createrepo   /var/www/html/repos/extras
createrepo   /var/www/html/repos/epel
createrepo  /var/www/html/repos/salt-latest
createrepo /var/www/html/repos/docker-ce-stable


 

