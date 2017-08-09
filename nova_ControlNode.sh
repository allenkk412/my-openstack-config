#!/bin/bash

############## Compute service config on ControlNode #############

#### Prerequisites
# mysql -u root --password=123
# mysql> CREATE DATABASE nova_api;
# mysql> CREATE DATABASE nova;
# mysql> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
#   IDENTIFIED BY '123';
# mysql> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
#   IDENTIFIED BY '123';
# mysql> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
#   IDENTIFIED BY '123';
# mysql> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
#   IDENTIFIED BY '123';

. admin-openrc
openstack user create --domain default nova --password 123
openstack role add --project service --user nova admin
openstack service create --name nova --description "Openstack Compute Service" compute 

# 创建nova的endpoint
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1/%\(tenant_id\)s

#### Install and configure components
yum install openstack-nova-api openstack-nova-conductor \
  openstack-nova-console openstack-nova-novncproxy \
  openstack-nova-scheduler

# 修改nova的配置文件 /etc/nova/nova.conf
cp /etc/nova/nova.conf /etc/nova/nova.conf.bk

openstack-config --set /etc/nova/nova.conf \
  DEFAULT enabled_apis osapi_compute,metadata
openstack-config --set /etc/nova/nova.conf \
  DEFAULT transport_url rabbit://openstack:123@controller
openstack-config --set /etc/nova/nova.conf \
  DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf \
  DEFAULT my_ip 10.0.0.11
openstack-config --set /etc/nova/nova.conf \
  DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf \
  DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

openstack-config --set /etc/nova/nova.conf \
  api_database connection mysql+pymysql://nova:123@controller/nova_api

openstack-config --set /etc/nova/nova.conf \
  database connection mysql+pymysql://nova:123@controller/nova

openstack-config --set /etc/nova/nova.conf \
  keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/nova/nova.conf \
  keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf \
  keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/nova/nova.conf \
  keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf \
  keystone_authtoken project_domain_name Default
openstack-config --set /etc/nova/nova.conf \
  keystone_authtoken user_domain_name Default
openstack-config --set /etc/nova/nova.conf \
  keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf \
  keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf \
  keystone_authtoken password 123

openstack-config --set /etc/nova/nova.conf \
  vnc vncserver_listen $my_ip
openstack-config --set /etc/nova/nova.conf \
  vnc vncserver_proxyclient_address $my_ip

openstack-config --set /etc/nova/nova.conf \
  glance api_servers http://controller:9292

openstack-config --set /etc/nova/nova.conf \
  oslo_concurrency lock_path /var/lib/nova/tmp

# 同步nova数据库
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova

# 启动nova并设置开机启动
systemctl enable openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service

systemctl start openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service

######### nova在控制节点配置完成，接下来在计算节点配置nova #############
#########    计算节点配置nova，见nova_ComputeNode.sh     #############