# Demo: Create & Configure Node

## Overview
- Let's create a Jenkins Agent/Node for this demo. (Jenkins Node = Agent)
- For this, spin up a new EC2 server.
- Navigate to the Jenkins home page > Manage Jenkins > Nodes, and fill in the details for the new node:
  - **Description**: Any descriptive text.
  - **Number of Executors**: 1
  - **Remote Root Directory**: /home/ubuntu
  - **Labels**: ubuntu-docker-jdk17-node20
  - **Usage**: Only build jobs with label expression matching this node.
  - **Launch Method**: By connecting it to the controller.
  - **Availability**: Keep the agent online as much as possible.
  - **Node Properties**:
    - Manage disk space.
    - Define environment variables.
    - Restrict job execution at the node.
  - In this demo, monitor disk threshold:
    - Free disk space threshold: 1GB
    - Free disk space warning threshold: 2GB
    - Free temp space threshold: 1GB
    - Free temp space warning threshold: 2GB

- Finally, click Save.

## Establishing Connection Between Node and Controller
- Follow the steps provided by the Jenkins controller.
- Ensure the agent has JDK installed. Preferably, use the same JDK version on both controller/master and slave/agent node.
- Choose the working directory as `/home/ubuntu` on the agent/node machine to install and download required binaries.
- Note: There may be a 404 error related to `tcpSlaveAgentListener` due to security constraints. Go to Manage Jenkins > Security > Search for "TCP" > TCP port for inbound agents (under agents section) > It is disabled by default. Update it to "Fixed" or "Random". Select "Random" to allow inbound traffic to the controller from the agent.

- The node/agent should now be connected successfully to the controller/master.

## Forwarding
- https://kneadable-saniyah-semierectly.ngrok-free.dev -> http://localhost:8080

## Original Commands (To Set Up Connection)
```bash
curl -sO http://localhost:8080/jnlpJars/agent.jar;
java -jar agent.jar -url http://localhost:8080/ -secret ee3104ecd62d7d5a044ebcf4e1ab27265bbec68322711f02229b502c385259ab -name "Slave-Agent-Node-1" -webSocket -workDir "/home"
```

## Modified Commands
- Connect to the EC2 instance, switch to root user, and navigate to `/home` folder.
- Install Java on Ubuntu:
  ```bash
  sudo apt update
  sudo apt install openjdk-17-jdk
  ```
- Run the curl command to download the JAR file.
- Modified commands:
  ```bash
  curl -sO https://kneadable-saniyah-semierectly.ngrok-free.dev/jnlpJars/agent.jar;
  java -jar agent.jar -url https://kneadable-saniyah-semierectly.ngrok-free.dev/ -secret ee3104ecd62d7d5a044ebcf4e1ab27265bbec68322711f02229b502c385259ab -name "Slave-Agent-Node-1" -webSocket -workDir "/home"
  ```

## Agent Logs
- Connection established between controller and node.
  ```
  Inbound agent connected from 34.233.120.0
  Remoting version: 3309.v27b_9314fd1a_4
  Launcher: JNLPLauncher
  Communication Protocol: WebSocket
  This is a Unix agent
  ```