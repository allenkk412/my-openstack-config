#!/bin/bash

############## Networking service config on the ComputeNode #############

yum install openstack-neutron-linuxbridge ebtables ipset

#### Configure the common component

# 配置 /etc/neutron/neutron.conf

cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bk

openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:123@controller
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name Default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name Default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password 123

openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

#### Configure networking options2：Self-service networks

# 配置 /etc/neutron/plugins/ml2/linuxbridge_agent.ini 

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:eno1

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip 10.0.0.31
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population True

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

#### 配置nova使用neutron

# 配置 /etc/nova/nova.conf

openstack-config --set /etc/nova/nova.conf neutron url http://controller:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name Default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name Default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password 123

# 重启nova

systemctl restart openstack-nova-compute.service

# 启动Linux bridge中介并设置开机启动

systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service
