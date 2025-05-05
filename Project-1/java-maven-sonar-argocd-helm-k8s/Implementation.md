
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

   ```groovy
   stages {
        stage('Build and Test') {
            steps {
        sh 'ls -ltr'
        sh 'cd Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app && mvn clean package'
      }
    }
   }
   ```
   ![](images/Pipeline-stage-3.PNG "Pipeline-stage-3")
   ![](images/Pipeline-stage-4.PNG "Pipeline-stage-4")

   <!-- Explanation of the 'Explanation of the 'Build & Test' stage .

    -- sh 'ls -ltr' : Lists all files and directories in the current Jenkins workspace directory .
    -- sh 'cd Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app && mvn clean package'
        -- Changes into the following nested directory i.e. Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app
        -- Then runs:
                -- mvn clean: Deletes previously compiled files and the target directory (ensures a clean build).
                -- mvn package: Compiles the code, runs unit tests, and packages the application into a .jar or .war, based on your pom.xml

    Q :What Must Be true for this stage to Work ?
    Sol : 
        . The path Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app must exist in the Jenkins workspace (i.e., it was checked out correctly).
        . Maven (mvn) must be installed and available in the environment or Docker container.
        . The directory must contain a valid pom.xml.
-->

  ```groovy
   stages {

        stage('Static Code Analysis') {
            environment {
            SONAR_URL = "http://3.87.39.73:9000"
        }
            steps {
                withCredentials([string(credentialsId: 'sonarqube_token', variable: 'SONAR_AUTH_TOKEN')]) {
                sh 'cd Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app && mvn sonar:sonar -Dsonar.login=$SONAR_AUTH_TOKEN -Dsonar.host.url=${SONAR_URL}'
                }
            }
    }
   }
   ```

   ![](images/Pipeline-stage-5.PNG "Pipeline-stage-5")
   ![](images/Pipeline-stage-6.PNG "Pipeline-stage-6")
   ![](images/Pipeline-stage-7.PNG "Pipeline-stage-7")
   ![](images/Pipeline-stage-8.PNG "Pipeline-stage-8")

<!-- Explanation of the 'Static Code Analysis' stage .

 -- stage('Static Code Analysis') : Defines a pipeline stage named "Static Code Analysis".
 -- environment { SONAR_URL = "http://3.87.39.73:9000" }
    -- Sets a stage-level environment variable named SONAR_URL.
    -- This is the URL where your SonarQube server is running.
    -- In this case: http://3.87.39.73:9000 (likely an EC2 instance or similar).
-- withCredentials([string(...)])
    -- Securely injects a SonarQube authentication token into the environment.
    -- credentialsId: 'sonarqube_token': Refers to a secret string stored in Jenkins Credentials.
    -- variable: 'SONAR_AUTH_TOKEN': The environment variable Jenkins will use inside the block.
-- Shell Commands :
    -- cd Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app && \
    -- mvn sonar:sonar -Dsonar.login=$SONAR_AUTH_TOKEN -Dsonar.host.url=${SONAR_URL}
         # Changes into the Spring Boot app directory.
         # Runs a Maven command to trigger SonarQube analysis with:
            -Dsonar.login=$SONAR_AUTH_TOKEN: uses the secure token for authentication.
            -Dsonar.host.url=${SONAR_URL}: tells Maven where to send analysis results.

Assumptions for this stage to Work.
    .. The project has a valid pom.xml with SonarQube plugin configured.
    .. Jenkins has the SonarQube token stored under the ID sonarqube_token.
    .. Maven and the sonar:sonar goal are available.
    .. The SonarQube server (http://3.87.39.73:9000) is reachable from Jenkins.
-->

  ```groovy
   stages {

        stage('Build and Push Docker Image') {
            environment {
                DOCKER_IMAGE = "khannashiv/ultimate-cicd:${BUILD_NUMBER}"
                REGISTRY_CREDENTIALS = credentials('docker-cred')
            }
            steps {
                script {
                sh 'cd Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app && docker build -t ${DOCKER_IMAGE} .'
                def dockerImage = docker.image("${DOCKER_IMAGE}")
                docker.withRegistry('https://index.docker.io/v1/', "docker-cred") {
                    dockerImage.push()
                }
                }
            }
        }
   }
   ```

 ![](images/Pipeline-stage-9.PNG "Pipeline-stage-9")
 ![](images/Pipeline-stage-10.PNG "Pipeline-stage-10")
 ![](images/Pipeline-stage-11.PNG "Pipeline-stage-11")
 ![](images/Pipeline-stage-12.PNG "Pipeline-stage-12")
 ![](images/Pipeline-stage-13.PNG "Pipeline-stage-13")
 ![](images/Pipeline-stage-14.PNG "Pipeline-stage-14")

   <!-- Explanation of the 'Build and Push Docker Image' stage .

    -- This stage builds a Docker image from your Java app and pushes it to Docker Hub using credentials stored in Jenkins.
    -- environment { ... }
        Defines environment variables for this stage .
            -- DOCKER_IMAGE = "khannashiv/ultimate-cicd:${BUILD_NUMBER}"
            -- The Docker image name and tag.
            -- Uses the current Jenkins build number as the tag (e.g., khannashiv/ultimate-cicd:44).
            -- REGISTRY_CREDENTIALS = credentials('docker-cred')
            -- Injects Docker Hub credentials stored in Jenkins under the ID docker-cred.
    -- script { ... }
        --  Build Docker image: sh 'cd Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app && docker build -t ${DOCKER_IMAGE} .'
            .. Changes into the app directory.
            .. Runs Docker build using the Dockerfile there.
            .. Tags the image as khannashiv/ultimate-cicd:<build_number>.
        --  Prepare Docker image for push: def dockerImage = docker.image("${DOCKER_IMAGE}")
            .. Creates a reference to the built Docker image in Jenkins Docker pipeline DSL.
                .. Meaning of : def dockerImage = docker.image("${DOCKER_IMAGE}")
                    This line tells Jenkins:
                        -- “Hey, I have a Docker image called khannashiv/ultimate-cicd:<build number> (from the DOCKER_IMAGE variable).”
                        -- “Save a reference to that image so I can do things with it later.This menas dockerImage will act as a”
                        -- Think of it like saying: “This is the image I just built — remember it as dockerImage.”

        -- Authenticate and push:
            docker.withRegistry('https://index.docker.io/v1/', "docker-cred") {
                                                    dockerImage.push()
                                                }
                .. Logs into Docker Hub using credentials ID docker-cred.
                .. Pushes the image to the registry.
                .. docker.withRegistry('https://index.docker.io/v1/', "docker-cred") { ... }
                    .. This tells Jenkins : “Log in to Docker Hub using my saved credentials (docker-cred).”
                .. dockerImage.push() : This tells Jenkins : “Take the image I just referenced (dockerImage) and push it to Docker Hub.”

The login is temporary — it’s only used inside the { ... } block.

What must be true for this stage to Work ?

    .. Docker must be installed and running on the Jenkins agent.
    .. Jenkins must have Docker credentials stored as ID docker-cred.
    .. The Dockerfile must exist in the specified app directory.
    .. Jenkins must be running as a user with permission to run Docker (docker.sock access, often via --user root in Docker agents).
-->


  ```groovy
   stages {

        stage('Update Deployment File') {
            environment {
            GIT_REPO_NAME = "Jenkins-Practice"
            GIT_USER_NAME = "khannashiv"
            }
        steps {
            withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
            sh '''
                echo "Updating deployment.yml with image tag ${BUILD_NUMBER}"
                export GIT_DIR=$WORKSPACE/.git
                export GIT_WORK_TREE=$WORKSPACE
                git config user.email "khannashiv94@gmail.com"
                git config user.name "Shiv"

                sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app-manifests/deployment.yml
                git add Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app-manifests/deployment.yml

                git commit -m "Update deployment image to version ${BUILD_NUMBER}" || echo "Nothing to commit"
                git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main || echo "Nothing to push"
            '''
            }
        }
    }
   }
   ```

 ![](images/Pipeline-stage-15.PNG "Pipeline-stage-15")
 ![](images/Pipeline-stage-16.PNG "Pipeline-stage-16")
 ![](images/Pipeline-stage-17.PNG "Pipeline-stage-17")
 ![](images/Jenkins-server-docker-images.PNG "Jenkins-server-docker-images")

<!-- Explanation of the 'Update Deployment File' stage .
 
 -- Environment Variables: These are used to build the GitHub push URL later.
    GIT_REPO_NAME = "Jenkins-Practice"
    GIT_USER_NAME = "khannashiv"

-- withCredentials([string(...)]) : credentialsId: 'github', variable: 'GITHUB_TOKEN'
    .. Securely loads your GitHub access token (stored in Jenkins under ID 'github').
    .. It's assigned to the variable GITHUB_TOKEN for use in Git operations.


-- echo "Updating deployment.yml with image tag ${BUILD_NUMBER}" : Logs the current action for visibility.

--  export GIT_DIR=$WORKSPACE/.git
    export GIT_WORK_TREE=$WORKSPACE
     .. Meaning of export : Tells Git where your project is located — this setup is needed if Jenkins doesn’t automatically set it up as a standard Git working tree.

--  git config user.email "khannashiv94@gmail.com"
    git config user.name "Shiv"
    .. Configures Git identity (needed for commits).

-- sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app-manifests/deployment.yml
    .. Replaces the placeholder text replaceImageTag in your deployment file with the actual Jenkins build number (e.g., 15).
    .. This essentially updates the image tag to point to the new Docker image you just built.

-- git add Project-1/.../deployment.yml
    .. Stages the modified deployment file for commit.

-- git commit -m "Update deployment image to version ${BUILD_NUMBER}" || echo "Nothing to commit"
    .. Commits the change, or prints a message if nothing was actually changed.

-- git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main || echo "Nothing to push"
    .. Pushes the commit to the main branch on GitHub using your token for authentication.
    .. Falls back to a message if there's nothing to push.


Summary for this stage .
        -- Edits your Kubernetes deployment file to use the latest image.
        -- Commits and pushes that change to GitHub automatically.
        -- This is essential for GitOps workflows, where you want your Git repo to be the single source of truth for deployments.
-->

## Here we have completed CI part from implementation prospective & we are going to implement CD part .

1. **Install MiniKube** :

    - For this I have deployed ubuntu machine On premises . On top of it I have installed minikube cluster by following the documentation as follows as per my OS which in this case is ubuntu
    - OS configuration
        - RAM : 16GB
        - Processor : 8
        - Disk : 80 GB
        - Since in my case initially minikube fails to start, hence I have to install drivers for linux distribution where I have used docker container based approach & following links have been attached from installation standpoint.
    - Refrences .
        - https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download
        - https://minikube.sigs.k8s.io/docs/drivers/
        - https://minikube.sigs.k8s.io/docs/drivers/docker/

    - Some basic minikube commands.

    - Starting, Stopping, and Managing the Cluster

        | Command            | Description                                                  |
        | ------------------ | ------------------------------------------------------------ |
        | `minikube start`   | Starts a Minikube cluster (creates one if it doesn't exist). |
        | `minikube stop`    | Stops the Minikube cluster.                                  |
        | `minikube delete`  | Deletes the Minikube cluster completely.                     |
        | `minikube status`  | Shows the current status of the Minikube cluster.            |
        | `minikube restart` | Restarts the Minikube cluster.                               |
        | `minikube docker-env`	 | Shows how to use Minikube’s Docker daemon.               |

    - Working with Add-ons

    | Command                                | Description                                                         |
    | -------------------------------------- | ------------------------------------------------------------------- |
    | `minikube addons list`                 | Lists all available and enabled add-ons.                            |
    | `minikube addons enable <addon-name>`  | Enables an add-on (e.g., `dashboard`, `metrics-server`, `ingress`). |
    | `minikube addons disable <addon-name>` | Disables an add-on.                                                 |

    - Accessing Services

    | Command                           | Description                                                  |
    | --------------------------------- | ------------------------------------------------------------ |
    | `minikube service <service-name>` | Opens a service in your default browser.                     |
    | `minikube service list`           | Lists URLs for services with NodePort or LoadBalancer types. |
    | `minikube tunnel`                 | Enables LoadBalancer-type services to work locally.          |

    - Working with the VM or Container

    | Command                                | Description                                   |
    | -------------------------------------- | --------------------------------------------- |
    | `minikube ssh`                         | SSH into the Minikube VM/container.           |
    | `minikube mount <host-path>:<vm-path>` | Mounts a host directory into the Minikube VM. |


2. **Install ArgoCD via operator** :

    - Once our K8's cluster was ready, we further have done installation of ArgoCD using operator approach.
    - For which we have followed official documentation for installing operators i.e. https://operatorhub.io/operator/argocd-operator
        - Commands used for installtion & to verify if operators / pods deployed successfully or not.
         -  curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.31.0/install.sh | bash -s v0.31.0
         - kubectl create -f https://operatorhub.io/install/argocd-operator.yaml
         - kubectl get pods -n operators
         - kubectl get pods -n operators -w
         - kubectl get nodes -o wide

         - Some basic Kubectl commands .

            - Cluster Info & Configuration

                | Command                | Description                       |
                | ---------------------- | --------------------------------- |
                | `kubectl version`      | Shows client and server versions. |
                | `kubectl cluster-info` | Displays cluster endpoint URLs.   |
                | `kubectl config view`  | Shows kubeconfig file details.    |
                | `kubectl get nodes`    | Lists all nodes in the cluster.   |  

            - Working with Resources .

                | Command                   | Description                                                              |
                | ------------------------- | ------------------------------------------------------------------------ |
                | `kubectl get pods`        | Lists all pods in the current namespace.                                 |
                | `kubectl get pods -A`     | Lists all pods in **all namespaces**.                                    |
                | `kubectl get deployments` | Lists all deployments.                                                   |
                | `kubectl get services`    | Lists all services (ClusterIP, NodePort, etc.).                          |
                | `kubectl get all`         | Lists **all** common resource types (pods, services, deployments, etc.). |

            - Create & Apply Resources

                | Command                         | Description                                     |
                | ------------------------------- | ----------------------------------------------- |
                | `kubectl apply -f <file.yaml>`  | Applies a manifest (creates or updates).        |
                | `kubectl create -f <file.yaml>` | Strictly creates a resource from the YAML file. |
                | `kubectl delete -f <file.yaml>` | Deletes a resource defined in the YAML.         |
                | `kubectl delete pod <pod-name>` | Deletes a specific pod.                         |

            - Namespaces

            | Command                                                        | Description                                             |
            | -------------------------------------------------------------- | ------------------------------------------------------- |
            | `kubectl get namespaces`                                       | Lists all namespaces.                                   |
            | `kubectl get pods -n <namespace>`                              | Lists pods in a specific namespace.                     |
            | `kubectl config set-context --current --namespace=<namespace>` | Changes the default namespace for your current context. |


            - Inspecting & Debugging

                | Command                                       | Description                                                       |
                | --------------------------------------------- | ----------------------------------------------------------------- |
                | `kubectl describe pod <pod-name>`             | Shows detailed info about a pod (events, container status, etc.). |
                | `kubectl logs <pod-name>`                     | Shows logs from a pod's main container.                           |
                | `kubectl logs <pod-name> -c <container-name>` | Logs from a specific container in a multi-container pod.          |
                | `kubectl exec -it <pod-name> -- bash`         | Executes an interactive shell in the pod (if bash is available).  |
                | `kubectl get events`                          | Shows recent events (warnings, info).                             |

 - ![](images/minikube-1.PNG "minikube-1")
 - ![](images/minikube-2.PNG "minikube-2")
 - ![](images/ArgoCD-1.PNG "ArgoCD-1")
 - ![](images/ArgoCD-2.PNG "ArgoCD-2")


3. **Creating ArgoCD controller** :

    - Create a new yml file say by the name of : vim argocd-basic.yml
    - Copy the content in the above yaml file as mentioned in the below documentation.
    - Refrence docs : https://argocd-operator.readthedocs.io/en/latest/usage/basics/ 
    - After this run command i.e.  kubectl apply -f argocd-basic.yml and wait for argocd pods to get deployed under default namespace.
    - Once pods are ready go to the services such that : kubectl get svc & look for example-argocd-server and by default the type of service will be ClusterIP.
    - We will go ahead & convert this to NodePort so that we can login to ArgoCD via browser since this service is responsible for ArgoCD UI . So we will run command i.e. kubectl edit svc example-argocd-server ( This may not work due to ownerReferences section hence follow below stepsto change service type.)

        - kubectl get argocd -A
        - kubectl edit argocd example-argocd -n default
        - Search for the server section and see if you can define.Further Update the service type to NodePort from ClusterIP & then save and check the service .
                spec:
                    server:
                        service:
                            type: NodePort
    - Further we will generate the URL, so that we can access AgroCD over a web browser. For this we will use command i.e. 
        - minikube service list
        - minikube service example-argocd-server

    - Next to login to ArgoCD, we have user-name as admin & password we have to pull from secret section of argocd cluster i.e. example-argocd-cluster
        - Commands used are .
            - kubectl get secret
            - kubectl edit secret example-argocd-cluster
            -  echo <XXXXXX> | base64 -d        # Decode password using base64 conversion.
            - Finally we will able to login to admin page of ArgoCD.

4. **Final application deployed via ArgoCD**

- Further we have created an application on ArgoCD UI where we have mentioned following details i.e.

    - CLUSTER   : https://kubernetes.default.svc
    - NAMESPACE : default
    - REPO URL  : https://github.com/khannashiv/Jenkins-Practice 
    - PATH      : To manifest files i.e. Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app-manifests/ 
    - Finally we can see our application running on top of pods got deployed sucessfully after configuring ArgoCD.
        - kubectl get pods
        - kubectl get deploy
        - kubectl get svc
        - minikube service list
        - We can see minikube has alloted 1 more URL to application i.e. using which we can load app on top of browser .

            default     | spring-boot-app-service                            | http/80      | http://192.168.49.2:31123


 - ![](images/ArgoCD-3.PNG "ArgoCD-3")
 - ![](images/ArgoCD-4.PNG "ArgoCD-4")
 - ![](images/ArgoCD-5.PNG "ArgoCD-5")
 - ![](images/ArgoCD-6.PNG "ArgoCD-6")
 - ![](images/ArgoCD-7.PNG "ArgoCD-7")
 - ![](images/ArgoCD-8.PNG "ArgoCD-8")
 - ![](images/ArgoCD-9.PNG "ArgoCD-9")
 - ![](images/ArgoCD-10.PNG "ArgoCD-10")
 - ![](images/ArgoCD-11.PNG "ArgoCD-11")
 - ![](images/ArgoCD-13.PNG "ArgoCD-13")
 - ![](images/ArgoCD-12.PNG "ArgoCD-12")