
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
     - Add required plugins such as **Git plugin**, **Docker pipeline**, **SonarQube Scanner** used in this project.
     - Configure credentials for **Git**, **SonarQube**, and **Docker** for authentication purposes.

    - ![](images/Jenkins-config-1.PNG "Jenkins-config-1")
    - ![](images/Jenkins-config-2.PNG "Jenkins-config-2")
    - ![](images/Jenkins-config-3.PNG "Jenkins-config-3")
    - ![](images/Jenkins-config-4.PNG "Jenkins-config-4")
    - ![](images/Jenkins-config-5.PNG "Jenkins-config-5")

## Configuring the Pipeline

- **Jenkinsfile**: Add the pipeline script in a file named `JenkinsFile` at the git repository whose absolute path is Jenkins-Practice/Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app/JenkinsFile. Below we are explaining each code block which is part of Jenkins pipeine.

   ```groovy
   pipeline {

       agent {
           docker {
               image 'khannashiv/maven-shiv-docker-agent:v1'
               args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
           }
       }
   }
   ```

<!-- Explanation of the agent block above:
    - pipeline { ... }
        This declares a Declarative Pipeline, the modern and more structured way to define Jenkins pipelines.
        - `agent`: Specifies where and how Jenkins should run the pipeline or specific stages.
            - `docker`: Indicates the pipeline will run inside a Docker container.
                - `image`: Specifies the Docker image (`khannashiv/maven-shiv-docker-agent:v1`) to use.
                    - Jenkins will:
                        - Pull this image from Docker Hub (or another registry) if it's not already on the system (i.e. if not present on Jenkins Node.)
                        - Start a container using this image to run the pipeline steps.
                        - This image probably includes Maven, Java, and other tools needed for building Java projects.
                - `args`: Provides additional arguments to the Docker container:
                - `--user root`: Runs the container as the root user.
                - `-v /var/run/docker.sock:/var/run/docker.sock`: Mounts the host's Docker socket into the container, allowing Docker commands inside the container to interact with the host's Docker daemon.

- Summary of this code block
    - This pipeline block configures Jenkins to run all build steps inside a custom Docker container with root access and Docker control, which is useful for Maven-based projects that also need to build or run Docker images.

Q: How Jenkins Gets the Docker Image ?

Sol :
1. Jenkins uses the local Docker engine on the agent node (where the pipeline runs).The Docker agent is required on that node for this to work.

2.Image Lookup and Pulling.
    -- Jenkins instructs Docker to run the image khannashiv/maven-shiv-docker-agent:v1.
    -- Docker checks if that image is already present locally.
    -- If the image is not found locally, Docker will:
        . Attempt to pull it from Docker Hub (since no private registry or credentials were specified).
        . This assumes khannashiv/maven-shiv-docker-agent:v1 is publicly available on Docker Hub.
3. Execution
    -- Once the image is pulled (or found locally), Docker spins up a container using that image.
    -- Jenkins executes all pipeline steps inside that container, with root access and the host’s Docker socket mounted.

Prerequisites for this to Work .
    The Jenkins agent must:
        . Have Docker installed and running.
        . Be able to pull images from Docker Hub.
        . Have permissions to run Docker containers (Jenkins user is often part of the docker group).
-->

   ```groovy
   options {
       skipDefaultCheckout(true)
       buildDiscarder(logRotator(numToKeepStr: '10'))
   }
   ```

<!-- Explanation of the options block mentioned above .

- `skipDefaultCheckout(true)`: Prevents Jenkins from automatically checking out the repository source code at the start of the pipeline. This is useful for custom checkouts and avoiding permission issues.
- `buildDiscarder(logRotator(numToKeepStr: '10'))`: Configures Jenkins to retain only the last 10 builds, automatically discarding older build logs to save disk space.
- skipDefaultCheckout(true) and buildDiscarder(logRotator(...)) are built-in features provided by Jenkins for use in Declarative Pipelines.

-->

   ```groovy
   stages {

       stage('Clean Workspace & Fix Permissions') {
           steps {
               sh '''
               echo "Cleaning workspace and fixing permissions..."
               rm -rf ${WORKSPACE}/*
               mkdir -p ${WORKSPACE}
               chown -R 111:113 ${WORKSPACE}
               '''
           }
       }
   }
   ```
![](images/Pipeline-stage-1.PNG "Pipeline-stage-1")

<!-- Explanation of the 'Clean Workspace & Fix Permissions' stage:

This stage ensures a clean workspace by removing old files and resetting permissions to avoid conflicts in subsequent stages.
- echo "Cleaning workspace and fixing permissions..."
    . Prints a message to the Jenkins console log for visibility.
- rm -rf ${WORKSPACE}/*
    . Deletes everything inside the Jenkins workspace directory.
- ${WORKSPACE} is a built-in Jenkins environment variable pointing to the job’s working directory. In this case path of this env variable is : /var/lib/jenkins/workspace/Project-1 ( Refer snap for this stage .)
- rf means:
    r: recursive (delete directories and contents)
    f: force (ignore non-existent files, don’t prompt)
- mkdir -p ${WORKSPACE}
    . Recreates the workspace directory if needed.
    . -p ensures no error is thrown if it already exists.
- chown -R 111:113 ${WORKSPACE}
    . Changes the ownership of the workspace directory to user ID 111 (Jenkins) and group ID 113 (Jenkins).
    . -R: recursive, applies to all files and subdirectories.
- Purpose of this Stage:
        -- Ensures a clean build environment.
        -- Resolves file permission issues, especially in Docker-based builds where user IDs in the container and host differ.
        -- Prevents problems from leftover files of previous builds.
-->

   ```groovy
   stages {

    stage('Checkout') {
        steps {
            checkout([
            $class: 'GitSCM',
            branches: [[name: '*/main']],
            userRemoteConfigs: [[
                url: 'https://github.com/khannashiv/Jenkins-Practice.git',
                credentialsId: 'github'
            ]]
            ])
        }
        }
   }
   ```
![](images/Pipeline-stage-2.PNG "Pipeline-stage-2")

<!-- Explanation of the 'Checkout' stage .

-- stage('Checkout') : Defines a stage in the pipeline called "Checkout", where source code retrieval occurs.
    -- steps { ... } : Contains the commands to be executed during this stage.
        -- checkout([ ... ]) : Invokes a manual Git checkout using Jenkins' internal Git plugin (GitSCM class).
            . $class: 'GitSCM' : Tells Jenkins to use the GitSCM (Source Control Manager) plugin for this checkout.
            . branches: [[name: '*/main']] : Specifies the branch to check out.
                */main matches the main branch regardless of the remote name (origin/main, etc.).
            . userRemoteConfigs: [[ ... ]] : Defines where to pull the source code from and what credentials to use: url: 'https://github.com/khannashiv/Jenkins-Practice.git' -- > The GitHub repository URL.
            . credentialsId: 'github' : The ID of credentials stored in Jenkins (in Manage Jenkins > Credentials).
                - This is mainly used for authenticated access to private repositories.
                - This ID must match the one we've configured in Jenkins (e.g., personal access token or classic token).
-->