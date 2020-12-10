# Overview

This folder is used to run an ansible playbook that will start the Jenkins Docker container. Ansible runs here directly on the Admin's computer. Once the Jenkins Docker container is created, Ansible will get invoked by Jenkins directly as part of the pipeline.

[Ansible Docker Resource](https://docs.ansible.com/ansible/2.5/modules/docker_container_module.html)

Make sure you're in the ansible folder when running the command:
```shell
ansible-playbook -i inventory jenkinsPlaybook.yaml
```
