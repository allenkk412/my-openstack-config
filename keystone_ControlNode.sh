#!/bin/bash

############## Identity service config on ControlNode #############

############ Install and configure ############

#### Prerequisites

# mysql -u root -p 
# mysql> CREATE DATABASE keystone;
# mysql> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
#  IDENTIFIED BY 'KEYSTONE_DBPASS';
# mysql> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
# IDENTIFIED BY 'KEYSTONE_DBPASS';

#### Install and configure components

yum install -y openstack-keystone httpd mod_wsgi openstack-utils
cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bk
openstack-config --set /etc/keystone/keystone.conf \ 
  database connection mysql+pymysql://keystone:123@controller/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone \
  --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone \
  --keystone-group keystone
##ADMIN_PASS = 123
keystone-manage bootstrap --bootstrap-password 123 \    
  --bootstrap-admin-url http://controller:35357/v3/ \
  --bootstrap-internal-url http://controller:35357/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

#### Configure the Apache HTTP server

sed -i "s/#ServerName www.example.com:80/ServerName controller/" \
  /etc/httpd/conf/httpd.conf
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

#### Finalize the installation

systemctl enable httpd.service
systemctl status httpd.service

# export OS_USERNAME=admin
# export OS_PASSWORD=ADMIN_PASS
# export OS_PROJECT_NAME=admin
# export OS_USER_DOMAIN_NAME=Default
# export OS_PROJECT_DOMAIN_NAME=Default
# export OS_AUTH_URL=http://controller:35357/v3
# export OS_IDENTITY_API_VERSION=3

############ Create a domain, projects, users, and roles ############

openstack project create --domain default \ 
  --description "Service Project" service
openstack project create --domain default \
  --description "Demo Project" demo
openstack user create --domain default demo \
  --password 123
openstack role create user
openstack role add --project demo --user demo user

#### Verify operation

vi /etc/keystone/keystone-paste.ini 
# Edit the /etc/keystone/keystone-paste.ini file and 
# remove admin_token_auth from the [pipeline:public_api],
# [pipeline:admin_api], and [pipeline:api_v3] sections.

unset OS_AUTH_URL OS_PASSWORD
openstack --os-auth-url http://controller:35357/v3 \
  --os-project-domain-name Default \
  --os-user-domain-name Default \
  --os-project-name admin \
  --os-username admin token issue \
  --os-password 123
openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default \
  --os-user-domain-name Default \
  --os-project-name demo \
  --os-username demo token issue \
  --os-password 123

############### Create OpenStack client environment scripts ##########

## admin-openrc     
## replace ADMIN_PASS with admin's password in Identity service

# export OS_PROJECT_DOMAIN_NAME=Default
# export OS_USER_DOMAIN_NAME=Default
# export OS_PROJECT_NAME=admin
# export OS_USERNAME=admin
# export OS_PASSWORD=ADMIN_PASS
# export OS_AUTH_URL=http://controller:35357/v3
# export OS_IDENTITY_API_VERSION=3
# export OS_IMAGE_API_VERSION=2

## demo-openrc     
## replace DEMO_PASS with demo's password in Identity service

# export OS_PROJECT_DOMAIN_NAME=Default
# export OS_USER_DOMAIN_NAME=Default
# export OS_PROJECT_NAME=demo
# export OS_USERNAME=demo
# export OS_PASSWORD=DEMO_PASS
# export OS_AUTH_URL=http://controller:5000/v3
# export OS_IDENTITY_API_VERSION=3
# export OS_IMAGE_API_VERSION=2
