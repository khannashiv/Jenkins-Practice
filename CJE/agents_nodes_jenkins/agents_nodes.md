# Theory: Concept of Agents & Nodes

## Overview
- Agents act as extensions of Jenkins, managing task execution by using executors on remote nodes.
- An agent represents a specific way a node connects to the controller, defining the communication protocol and authentication mechanism used.
- For example, you may have a Java agent connecting via JNLP or an SSH agent connecting via SSH protocol.
- Any tools required for testing or building pipelines and code are installed on the node where the agents run.
- Apart from static/dedicated agents, we can use Docker or Kubernetes as base agents.
- When working with Docker, we can use Docker containers as build agents with pre-defined images instead of installing tools/dependencies on dedicated worker nodes.
- You may define a Docker image containing all the necessary software for building jobs. This is well-suited for scenarios where build jobs require specific software versions or dependencies.
- Finally, each build job runs in a clean, isolated environment, preventing conflicts between projects.

## Types of Agents
- Jenkins agents are like worker machines. These machines may be physical, virtual, or containers that connect to the Jenkins controller and act as execution engines for build pipelines.
- **Permanent Agents**: Dedicated agents that are always available.
- **Docker Agents**: Agents running in Docker containers.
- **Cloud-based Agents**: Agents provisioned on-demand from cloud providers.
- **Label-based Agents**: Agents assigned based on labels for specific tasks.

## Using Agents in Pipelines

### Example 1: Any Agent
```groovy
pipeline {
    agent any
    stages {
        stage('A') {
            // steps
        }
    }
}
```

### Example 2: Label-based Agent
```groovy
pipeline {
    agent {
        label 'my-agent'
    }
    stages {
        stage('A') {
            // steps
        }
    }
}
```

### Example 3: Docker Agent
```groovy
pipeline {
    agent {
        docker {
            image 'node:latest'
            args '-v $HOME:/root/npm'
        }
    }
    stages {
        stage('A') {
            // steps
        }
    }
}
```

### Example 4: Per-Stage Agent
```groovy
pipeline {
    agent {
        label 'my-agent'
    }
    stages {
        stage('A') {
            agent {
                label 'nodejs-agent'
            }
            // steps
        }
    }
}
```
