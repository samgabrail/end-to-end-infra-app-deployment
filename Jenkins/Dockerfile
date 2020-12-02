# docker run -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 samgabrail/jenkins-tf-vault-ansible:latest
FROM jenkins/jenkins:lts
# if we want to install via apt
USER root

RUN wget https://releases.hashicorp.com/vault/1.6.0/vault_1.6.0_linux_amd64.zip && unzip vault_1.6.0_linux_amd64.zip && mv vault /usr/local/bin && wget https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip && unzip terraform_0.13.5_linux_amd64.zip && mv terraform /usr/local/bin && rm vault_1.6.0_linux_amd64.zip && rm terraform_0.13.5_linux_amd64.zip

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y gnupg2 python3-pip sshpass git openssh-client jq && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean
    
RUN python3 -m pip install --upgrade pip cffi && \
    pip install ansible==2.10.3 && \
    pip install mitogen ansible-lint jmespath && \
    pip install --upgrade pywinrm

# drop back to the regular jenkins user - good practice
USER jenkins
# RUN python -m pip install --user ansible
# install-plugins script
# RUN jenkins-plugin-cli --plugins docker-slaves github-branch-source:1.8