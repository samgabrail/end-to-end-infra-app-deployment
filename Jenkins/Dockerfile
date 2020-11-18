# docker run -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts
FROM jenkins/jenkins:lts
# if we want to install via apt
USER root
RUN apt-get update && apt-get install -y wget gnupg2 curl software-properties-common && curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && apt-add-repository --yes --update ppa:ansible/ansible && apt-get update && apt-get -y install  vault terraform ansible
# drop back to the regular jenkins user - good practice
USER jenkins
# install-plugins script
RUN /usr/local/bin/install-plugins.sh docker-slaves github-branch-source:1.8
