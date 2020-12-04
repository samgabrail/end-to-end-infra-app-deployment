# Overview

This folder is used to run an ansible playbook from withing a Jenkins pipeline. It's used to configure the two VMs below:
1. The main Python app VM hosting the Webblog application. 
2. The VM hosting the MongoDB.

Make sure you're in the ansible folder when running the command:
```shell
ansible-playbook -i inventory --extra-vars "mongo_root_user=1.23.45 mongo_root_password=foo" appPlaybook.yaml
```