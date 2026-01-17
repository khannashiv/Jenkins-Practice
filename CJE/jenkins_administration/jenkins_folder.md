# Jenkins Folders

This document demonstrates the use of Jenkins folders for organizing projects, managing credentials, and handling pipelines.

## Part 1: Jenkins Folders Overview

Folders in Jenkins provide a separate namespace for different projects or teams on the same controller.

### Key Benefits

- **Isolation**: Jobs in one folder are distinct from those in another (e.g., a job named "build" in Folder A is separate from one in Folder B).
- **Simplified Management**: Folders help manage branches and pipelines more effectively.
- **Scoped Resources**: Credentials, properties, or other resources assigned to a folder are only visible to builds within that folder.
- **Inheritance**: Child folders can access credentials from parent folders.

### Example Setup

1. Create a main folder named `shared-infrastructure`.
2. Add dummy credentials (username: `Database-admin`, password: `admin`) with ID `Shared-database-credentials`.
3. Create a sub-folder named `Team-A-folder` under `shared-infrastructure`.
4. In `Team-A-folder`, add credentials (username: `Team-A`, password: `admin`) with ID `Team-A-creds`.
5. Create a pipeline named `Team-A-pipeline` in `Team-A-folder`.

### Official Documentation

- [Handling Credentials in Jenkinsfile](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#handling-credentials)
- [Using Credentials](https://www.jenkins.io/doc/book/using/using-credentials/)
- [Credentials Masking](https://www.jenkins.io/blog/2019/02/21/credentials-masking/)

### Working Pipeline Script

The following pipeline accesses credentials from both the parent and child folders.

```groovy

    pipeline {
        agent any

        environment {
            Shared_DB_Creds = credentials('Shared-database-credentials')
            Team_A_Credentials = credentials('Team-A-creds')
        }

        stages {
            stage('Accessing Credentials') {
                steps {
                    script {
                        sh """
                            echo "Printing Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds}"
                            echo "Printing username from Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds_USR}"
                            echo "Printing password from Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds_PSW}"

                            echo "Printing Shared DB credentials using string interpolation: ${Shared_DB_Creds}"
                            echo "Printing username from Shared DB credentials using string interpolation: ${Shared_DB_Creds_USR}"
                            echo "Printing password from Shared DB credentials using string interpolation: ${Shared_DB_Creds_PSW}"

                            echo "Printing Shared DB credentials using shell variables: $Shared_DB_Creds"
                            echo "Printing username from Shared DB credentials using shell variables: $Shared_DB_Creds_USR"
                            echo "Printing password from Shared DB credentials using shell variables: $Shared_DB_Creds_PSW"

                            echo "Printing Team A credentials using Groovy environment variable: ${env.Team_A_Credentials}"
                            echo "Printing username from Team A credentials using Groovy environment variable: ${env.Team_A_Credentials_USR}"
                            echo "Printing password from Team A credentials using Groovy environment variable: ${env.Team_A_Credentials_PSW}"

                            echo "Printing Team A credentials using string interpolation: ${Team_A_Credentials}"
                            echo "Printing username from Team A credentials using string interpolation: ${Team_A_Credentials_USR}"
                            echo "Printing password from Team A credentials using string interpolation: ${Team_A_Credentials_PSW}"

                            echo "Printing Team A credentials using shell variables: $Team_A_Credentials"
                            echo "Printing username from Team A credentials using shell variables: $Team_A_Credentials_USR"
                            echo "Printing password from Team A credentials using shell variables: $Team_A_Credentials_PSW"
                        """
                    }
                }
            }
        }

        post {
            success {
                echo "Build ran successfully!"
            }
            failure {
                echo "Build failed!"
            }
        }
    }
    
```

**Successful Output**: Build #15 - [View Pipeline](http://localhost:8080/blue/organizations/jenkins/Shared-infrastructure%2FTeam-A%2FTeam-A-pipeline/detail/Team-A-pipeline/15/pipeline)

### Conclusion
Pipelines in sub-folders can access credentials from parent folders. In the console output, usernames are printed, while passwords are masked for security.

## Part 2: Folder Isolation

### Setup
1. Create a new folder named `Team-B-folder` under `Shared-Infra-folder`.
2. Create a pipeline named `Team-B-pipeline` inside `Team-B-folder`.
3. Configure the pipeline with the script below and run it.
4. Observe the unsuccessful output due to Team B not having access to credentials from Team A, although it can access parent folder credentials.

### Case 1: Failing Pipeline (Team A Credentials Not Accessible)

 - This pipeline fails because `Team-A-creds` is not accessible from `Team-B-folder`.

```groovy
        pipeline {
                    agent any 

                    environment {
                        Shared_DB_Creds = credentials('Shared-database-credentials')
                        Team_A_Credentials = credentials('Team-A-creds')
                    }

                    stages {
                        stage ('Accessing Credentials') {
                            steps {
                                  script {
                                        sh '''
                                            echo "Printing Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds}"
                                            echo "Printing username from Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds_USR}"
                                            echo "Printing password from Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds_PSW}"

                                            echo "Printing Shared DB credentials using string interpolation: ${Shared_DB_Creds}"
                                            echo "Printing username from Shared DB credentials using string interpolation: ${Shared_DB_Creds_USR}"
                                            echo "Printing password from Shared DB credentials using string interpolation: ${Shared_DB_Creds_PSW}"

                                            echo "Printing Shared DB credentials using shell variables: $Shared_DB_Creds"
                                            echo "Printing username from Shared DB credentials using shell variables: $Shared_DB_Creds_USR"
                                            echo "Printing password from Shared DB credentials using shell variables: $Shared_DB_Creds_PSW"

                                            echo "Printing Shared DB credentials using Groovy environment variable: ${env.Team_A_Credentials}"
                                            echo "Printing username from Shared DB credentials using Groovy environment variable: ${env.Team_A_Credentials_USR}"
                                            echo "Printing password from Shared DB credentials using Groovy environment variable: ${env.Team_A_Credentials_PSW}"

                                            echo "Printing Shared DB credentials using string interpolation: ${Team_A_Credentials}"
                                            echo "Printing username from Shared DB credentials using string interpolation: ${Team_A_Credentials_USR}"
                                            echo "Printing password from Shared DB credentials using string interpolation: ${Team_A_Credentials_PSW}"

                                            echo "Printing Shared DB credentials using shell variables: $Team_A_Credentials"
                                            echo "Printing username from Shared DB credentials using shell variables: $Team_A_Credentials_USR"
                                            echo "Printing password from Shared DB credentials using shell variables: $Team_A_Credentials_PSW"

                                        '''
                                    }
                                }
                        }
                    }

                    post {
                        success {
                            echo "Build ran successfully!"
                        }
                        failure {
                                echo "Build failed!"
                        }
                    }
        } 
```

**Output**: ERROR - Team-A-creds not found. [View Build](http://localhost:8080/job/Shared-infrastructure/job/Team-B-folder/job/Team-B-pipeline/6/)

### Case 2: Failing Pipeline (Groovy Variables in Shell)

- Pipeline failing in this case due to groovy variables accessed inside shell script using triple single quotes.

```groovy
        pipeline {
                    agent any 

                    environment {
                        Shared_DB_Creds = credentials('Shared-database-credentials')
                    }

                    stages {
                        stage ('Accessing Credentials') {
                            steps {
                                  script {
                                        sh '''
                                            echo "Printing Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds}"
                                            echo "Printing username from Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds_USR}"
                                            echo "Printing password from Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds_PSW}"

                                            echo "Printing Shared DB credentials using string interpolation: ${Shared_DB_Creds}"
                                            echo "Printing username from Shared DB credentials using string interpolation: ${Shared_DB_Creds_USR}"
                                            echo "Printing password from Shared DB credentials using string interpolation: ${Shared_DB_Creds_PSW}"

                                            echo "Printing Shared DB credentials using shell variables: $Shared_DB_Creds"
                                            echo "Printing username from Shared DB credentials using shell variables: $Shared_DB_Creds_USR"
                                            echo "Printing password from Shared DB credentials using shell variables: $Shared_DB_Creds_PSW"

                                        '''
                                    }
                                }
                        }
                    }

                    post {
                        success {
                            echo "Build ran successfully!"
                        }
                        failure {
                                echo "Build failed!"
                        }
                    }
        } 
```

**Output**: Script error (exit code 2). [View Build](http://localhost:8080/job/Shared-infrastructure/job/Team-B-folder/job/Team-B-pipeline/7/)
 
### Case 3: Working Pipeline

- Shifting groovy variables outside shell script, under shell script keeping only shell variables and string interpolation.

```groovy
        pipeline {
                    agent any 

                    environment {
                        Shared_DB_Creds = credentials('Shared-database-credentials')
                    }

                    stages {
                        stage ('Accessing Credentials') {
                            steps {
                                  script {

                                            // Groovy context

                                            echo "Printing Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds}"
                                            echo "Printing username from Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds_USR}"
                                            echo "Printing password from Shared DB credentials using Groovy environment variable: ${env.Shared_DB_Creds_PSW}"

                                            // Shell context

                                            sh '''
                                                # Accessing Shell variables & testing string interpolation.

                                                echo "Printing Shared DB credentials using string interpolation: ${Shared_DB_Creds}"
                                                echo "Printing username from Shared DB credentials using string interpolation: ${Shared_DB_Creds_USR}"
                                                echo "Printing password from Shared DB credentials using string interpolation: ${Shared_DB_Creds_PSW}"

                                                echo "Printing Shared DB credentials using shell variables: $Shared_DB_Creds"
                                                echo "Printing username from Shared DB credentials using shell variables: $Shared_DB_Creds_USR"
                                                echo "Printing password from Shared DB credentials using shell variables: $Shared_DB_Creds_PSW"

                                            '''
                                    }
                                }
                        }
                    }

                    post {
                        success {
                            echo "Build ran successfully!"
                        }
                        failure {
                                echo "Build failed!"
                        }
                    }
        }  
```

**Output**: SUCCESS. [View Build](http://localhost:8080/job/Shared-infrastructure/job/Team-B-folder/job/Team-B-pipeline/8/)

## Part 3: Copying Artifacts Between Folders

1. Create `Team-C-folder` under `shared-infrastructure`.
2. Copy items from `Team-A-folder` to `Team-C-folder`.

    - Once we mention Team-A-Folder & click on save. We can see configuration  which was part of folder A has been replicated to folder C.

    - By default, the "Build Now" button is not available for a pipeline that has been copied from folder A to folder C. To run the pipeline within folder C:
        - Go to the pipeline.
        - Click on Configure.
        - Scroll to the very bottom and click Apply, then Save.
        Once these changes are made, the Build Now option will become available.

3. Run the pipeline successfully. [View Build](http://localhost:8080/job/Shared-infrastructure/job/Team-C-folder/job/Team-A-pipeline/)

## Part 4: Folder Health Metrics

Folders can inherit health from child items.

### Current Health Mismatch
- `Shared-Infra-folder`: >80% (Green)
  - `Team-A-folder`: >80% (Green)
    - `Team-A-pipeline`: 40-60% (Yellow)
  - `Team-B-folder`: >80% (Green)
    - `Team-B-pipeline`: 20-40% (Red)
  - `Team-C-folder`: >80% (Green)
    - `Team-C-pipeline`: >80% (Green)

### Fixing Health
1. For sub-folders (e.g., `Team-B-folder`): Configure > Health Metrics > Select "Child item with worst health" + Recursive > Apply > Save.
2. For parent folder (`Shared-Infra-folder`): Same configuration to match sub-folder health.
