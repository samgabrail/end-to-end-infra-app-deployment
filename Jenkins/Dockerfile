# docker run -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts
FROM jenkins/jenkins:lts
# if we want to install via apt
USER root
RUN apt-get update && apt-get install -y pip
RUN wget https://releases.hashicorp.com/vault/1.6.0/vault_1.6.0_linux_amd64.zip && unzip vault_1.6.0_linux_amd64.zip && mv vault /usr/local/bin && wget https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip && unzip terraform_0.13.5_linux_amd64.zip && mv terraform /usr/local/bin
# drop back to the regular jenkins user - good practice
USER jenkins
# install-plugins script
RUN jenkins-plugin-cli --plugins docker-slaves github-branch-source:1.8
