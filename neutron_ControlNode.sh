#!/bin/bash

############## Networking service config on ControlNode #############

#### Prerequisites
# mysql -u root --password=123
# mysql> CREATE DATABASE neutron;
# mysql> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
#   IDENTIFIED BY '123';
# mysql> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
#   IDENTIFIED BY '123';

. admin-openrc

openstack user create --domain default neutron --password 123
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "Openstack Networking Service" network

# 创建neutron的endpoint
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696