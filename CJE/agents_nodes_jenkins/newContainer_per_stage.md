# Demo: Utilize newContainerPerStage Directive

## Official Docs
- [**Jenkins Pipeline Syntax - Options**](https://www.jenkins.io/doc/book/pipeline/syntax/#options)
- [**Linux/Unix $RANDOM Shell Variable**](https://www.geeksforgeeks.org/linux-unix/random-shell-variable-in-linux-with-examples/)

## Description
- In Jenkins, the `newContainerPerStage()` directive ensures that each stage runs in a new container deployed on the same node, rather than all stages running in the same container.
- Outcomes from the previous container are not carried over to the next one.

## Pipeline Setup
- Created a new branch: `feature-newContainerPerStage` from `main`.
- Created a new pipeline project: `external-agent-pipeline-project-newContainerPerStage`, pointing to the `feature-newContainerPerStage` branch.
- Removed stage-wise agents and used a global agent for stage 4 (Dockerfile agent):
  ```groovy
  agent {
      dockerfile {
          filename 'Dockerfile.cowsay'
          dir './'
          label 'ubuntu-docker-jdk17-node18'
          registryUrl 'https://dhi.io'
          registryCredentialsId 'Docker-hub-login-creds'
      }
  }
  ```

## Behavior Without newContainerPerStage
- Upon successful build, the classic UI shows an additional "Agent Setup" stage that builds the container image used by all following stages.
- Console logs show only one `docker run` command, indicating a single container handles all 4 stages.
- All 4 stages share a common workspace. This is proven by generating a random number in stage 1 (`echo $RANDOM >> /tmp/imp-file-${BUILD_ID}`) and reading it in stages 2, 3, and 4 (`cat /tmp/imp-file-${BUILD_ID}`).

## With newContainerPerStage
- To use a separate container for each stage, add the `newContainerPerStage()` option via the Declarative Directive Generator under "Sample Directive" > "Options".
  ```groovy
  options {
      newContainerPerStage()
  }
  ```
- With this directive, each stage uses a new container and its own workspace. Stage 2 will fail because it cannot access files from stage 1.
- This section is commented out to keep the build green, as it causes failures in the last build.
