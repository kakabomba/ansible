#!/bin/bash

apt-get install git ansible sudo

usermod -aG sudo $(cat /etc/passwd | tail -n1 | grep 1000 | sed -e 's/:.*//g')

git config --global user.email "kakabomba@gmail.com"
git config --global user.name "Oles Zaburannyi"
git config --global push.default simple

git clone https://github.com/kakabomba/ansible.git
cd ansible
ansible-playbook -i 'localhost,' --connection=local ./playbooks/common.yml
