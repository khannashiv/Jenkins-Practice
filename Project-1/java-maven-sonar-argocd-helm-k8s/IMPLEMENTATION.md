
---

## Setting Up Jenkins
1. **Install Jenkins**:
   - Set up a Jenkins server on an EC2 instance (e.g., t2.large).
   - Use the following command to retrieve the initial admin password:
     ```bash
     cat /var/lib/jenkins/secrets/initialAdminPassword
     ```

2. **Log into Jenkins**:
   - Navigate to the Jenkins admin page.
   - Enter the username `Jenkins` and the password retrieved in Step 1.

3. **Create a New Pipeline**:
   - Click on "New Item" on the Jenkins home page.
   - Select "Pipeline" as the project type.

4. **Configure the Pipeline**:
   - Add a general description.
   - Set up the "Discard old builds" section.
   - Define the pipeline:
     - **SCM**: Git
     - **Repository URL**: `https://github.com/khannashiv/Jenkins-Practice`
     - **Branches to build**: Specify the branch name.
     - **Script Path**: Path to your `Jenkinsfile`.

    - ![](images/Jenkins-config-1.PNG "Jenkins-config-1")
    - ![](images/Jenkins-config-2.PNG "Jenkins-config-2")
    - ![](images/Jenkins-config-3.PNG "Jenkins-config-3")
    - ![](images/Jenkins-config-4.PNG "Jenkins-config-4")
    - ![](images/Jenkins-config-5.PNG "Jenkins-config-5")

---

## Configuring the Pipeline
- **Jenkinsfile**: Add the pipeline script in a file named `Jenkinsfile` at the root of the repository. Example:
   ```groovy
   pipeline {
       agent any
       stages {
           stage('Build') {
               steps {
                   sh 'mvn clean install'
               }
           }
           stage('Test') {
               steps {
                   sh 'mvn test'
               }
           }
           stage('Code Analysis') {
               steps {
                   sh 'sonar-scanner'
               }
           }
           stage('Deploy') {
               steps {
                   sh 'helm install ...'
               }
           }
       }
   }
