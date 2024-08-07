# terraform-ansible-azurevm

# le but de cette config est de creer un vm azure b1s grace a terraform et la configurer avec ansible afin de pouvoir deployer des applications dockerizer

# terrafom init
# terraform apply
# ansible-playbook -i hosts.ini install.yml -e "ansible_ssh_extra_args='-o HostKeyAlgorithms=+ssh-rsa'"
