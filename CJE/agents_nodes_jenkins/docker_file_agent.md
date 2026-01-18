# Demo: Utilize Docker File Agent

## Q&A

### Question 1: Can I not use apt install instead of npm install in Dockerfile?
**Solution 1:** Yes, we can do this as we have updated our Dockerfile.

### Question 2: What is the generic way to add a new app package to a Dockerfile assuming we have some base Docker image?

## Error 1
```
+ cowsay 'Hello from apt-installed cowsay!'
/home/workspace/external-agent-pipeline-project@tmp/durable-f6a1b16a/script.sh.copy: line 7: cowsay: command not found
```

**Tracked via following commands defined under Dockerfile:**
```bash
echo "cowsay location: $(find /usr -type f -name cowsay 2>/dev/null | head -5)" && \
echo "PATH: $PATH"
```

**Output:**
```
cowsay location: /usr/games/cowsay
PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

**Solution 1:**
```dockerfile
# M1: Add symlink to /usr/local/bin (which IS in PATH)
RUN ln -sf /usr/games/cowsay /usr/local/bin/cowsay
```

**Solution 2:**
```dockerfile
# M2: Add /usr/games to PATH
ENV PATH="/usr/games:$PATH"
```

### Question 3: Meaning of PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin?
**Solution:** This is your system PATH environment variable. It tells the shell where to look for executable commands. Your cowsay is installed in `/usr/games/cowsay`, but `/usr/games/` is NOT in the PATH!

**How PATH Works:**
When you type a command like `cowsay`, the shell searches through each directory in PATH in order:
- First looks in `/usr/local/sbin/` → No cowsay
- Then `/usr/local/bin/` → No cowsay
- Then `/usr/sbin/` → No cowsay
- Then `/usr/bin/` → No cowsay
- Then `/sbin/` → No cowsay
- Then `/bin/` → No cowsay
- Result: `cowsay: command not found`

### Question 4: So if I go with this method i.e. `ENV PATH="/usr/games:$PATH"` vs via softlink creation: `RUN ln -sf /usr/games/cowsay /usr/local/bin/cowsay`. So will the softlink able to add new path `/usr/games/cowsay` to environment variable PATH means if I do echo to echo "PATH: $PATH". Will it give new path added to the system paths?
**Solution:** No, the symlink does NOT change the PATH variable at all.

**Comparison:**

| Aspect                      | Symlink Method                                      | ENV PATH Method                                    |
|-----------------------------|-----------------------------------------------------|----------------------------------------------------|
| Changes PATH?               | ❌ No                                               | ✅ Yes                                             |
| `echo $PATH` output         | Unchanged                                          | Shows `/usr/games:` added                          |
| How it works                | Creates shortcut in existing PATH dir              | Adds new directory to PATH                         |
| Effect on other commands    | Only affects cowsay                                | Affects ALL commands in `/usr/games/`              |
| Cleanliness                 | More precise                                       | Broader change                                     |
| Persistence                 | Symlink persists                                   | Environment variable persists                      |

### Question 5: Further this activity will happen within a container i.e. `ln -sf /usr/games/cowsay /usr/local/bin/cowsay` as well as `ENV PATH="/usr/games:$PATH"` nothing is happening on the host OS right?
**Solution:** Both operations happen only inside the Docker container, not on the host OS. Docker containers are isolated sandboxes. Anything you do inside (RUN, ENV, creating files, installing packages) stays inside the container and doesn't affect your host/Jenkins server at all.

## Updated Dockerfile and Jenkins File

- Here is the updated Dockerfile as well as Jenkins file with new stage added i.e. `stage ('S4-Docker-File')`.

- **Working Dockerfile: `Dockerfile.cowsay`**
  ```dockerfile
  ####### Dockerfile working using soft link as well as using env var #########

  # Using DHI as base image
  FROM dhi.io/node:25-debian13-dev

  # Update package list and install cowsay via apt
  RUN apt-get update && apt-get install -y cowsay && \
      apt-get clean && rm -rf /var/lib/apt/lists/* && \
      echo "cowsay location: $(find /usr -type f -name cowsay 2>/dev/null | head -5)" && \
      echo "PATH: $PATH"

  # M1: Add symlink to /usr/local/bin (which IS in PATH)
  # RUN ln -sf /usr/games/cowsay /usr/local/bin/cowsay

  # M2: Add /usr/games to PATH
  ENV PATH="/usr/games:$PATH"

  # Debug path of cowsay & default system path
  RUN echo "cowsay location: $(find /usr -type f -name cowsay 2>/dev/null | head -5)"
  RUN echo "PATH: $PATH"

  # Verify version of cowsay
  RUN cowsay --version && \
      echo "Symlinks created successfully!"
  ```

- **Updated Jenkins File with New Stage:**
  ```groovy
  stage('S4-Docker-File') {
      agent {
          dockerfile {
              filename 'Dockerfile.cowsay'
              dir './'
              label 'ubuntu-docker-jdk17-node18'
              registryUrl 'https://dhi.io'
              registryCredentialsId 'Docker-hub-login-creds'
          }
      }
      steps {
          script {
              sh '''
                  cat /etc/os-release
                  node -v
                  npm -v
                  echo "=== System Packages ==="
                  cowsay "Hello from apt-installed cowsay!"
              '''
          }
      }
  }
  ```
