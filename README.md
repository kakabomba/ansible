
ansible 2.3.1.0 playbooks



ssh-keygen -t rsa

cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys




sed -i -e 's/^StrictModes /#\0/g' /etc/ssh/sshd_config

sed -i -e 's/^\(PermitRootLogin\)\s*.*$/\1 yes/g' /etc/ssh/sshd_config

service ssh restart


sed -i -e 's/^\(host_key_checking\)\s*.*$/\1 False/g' /etc/ansible/ansible.cfg

sed -i -e 's/^\(retry_files_enabled\)\s*.*$/\1 False/g' /etc/ansible/ansible.cfg


ansible-playbook -i 'localhost,' ./playbooks/common.yml
