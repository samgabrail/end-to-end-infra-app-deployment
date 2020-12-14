# Store Jenkins Data
You can store your entire jenkins data from the container somewhere on your local computer (don't check into git).

Then when rebuilding the Jenkins machine, copy the directory over using the following command:

```shell
scp -r jenkins_data/ adminuser@samg-jenkins.centralus.cloudapp.azure.com:/home/adminuser/
```

**Remember to restart the docker container**