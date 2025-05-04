Jenkins Pipeline for Java based application using Maven, SonarQube, Argo CD, Helm and Kubernetes .

Git || VCS || SCM 

First of all we have created a new git repository to implement this project. Here the name of the repository is : Jenkins-Practice and url for the repository is : https://github.com/khannashiv/Jenkins-Practice/

Under this repository, we have added required folders such as ArgoCD, spring-boot-app, spring-boot-app-manifests and README.md file for the base project .

Jenkins 

We have done the installion  of Jenkins Server on EC2 instance i.ee. t2.large
Once installation of Jenkins completes, We have logged into admin page of Jenkins using user-name as Jenkins & passsword as XXX
To pull default password for jenkins, you can use : cat /var/lib/jenkins/secrets/initialAdminPassword
Then we have clicked on new item from Jenkins home page >> Selected the type of project i.e. in my case I have selected pipeline as my project type.
After this I have added General description, Discard old build section, Pipeline definition, SCM as Git, Repository URL, branches to build, script path i.e. path to your Jenkins file.