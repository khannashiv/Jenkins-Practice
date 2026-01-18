# Demo: Utilize Agents in Jobs

## Official Docs
- [**Jenkins Pipeline Syntax - Agent**](https://www.jenkins.io/doc/book/pipeline/syntax/#agent)

## Projects Created
In this demo, we created two projects to demonstrate agent usage.

### Freestyle Project: external-agent-freestyle-project
- **Configuration**: Used the option "Restrict where this project can be run" with the label `ubuntu-docker-jdk17-node18`. This ensures the project runs on the node with that label.
- **Build Steps**: Execute shell with the following commands:
  ```bash
  cat /etc/os-release
  node -v
  npm -v
  ```

### Pipeline Project: external-agent-pipeline-project
- **Configuration**: Uses `agent any` globally, which is the default for any stage. It has two stages: one using the default agent and another using a specific agent. We can compare the output of `node` and `npm` in both cases from the console output logs.
- **Pipeline Code**:
  ```groovy
  pipeline {
      agent any
      stages {
          stage('Default-agent') {
              steps {
                  script {
                      sh '''
                          sudo -u ubuntu bash -c "
                              cat /etc/os-release
                              # Use nvm-installed node directly
                              /home/ubuntu/.nvm/versions/node/v24.7.0/bin/node -v
                              /home/ubuntu/.nvm/versions/node/v24.7.0/bin/npm -v
                          "
                      '''
                  }
              }
          }
          stage('External-agent') {
              agent {
                  label 'ubuntu-docker-jdk17-node18'
              }
              steps {
                  script {
                      sh 'cat /etc/os-release'
                      sh 'node -v'
                      sh 'npm -v'
                  }
              }
          }
      }
  }
  ```

## Notes
- `sudo -u ubuntu bash -c "commands here"`: This means "Run these commands in a bash shell as the ubuntu user."