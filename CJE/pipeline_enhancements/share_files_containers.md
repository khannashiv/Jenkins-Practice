# Demo: Sharing Files Between Containers in Kubernetes Pods

## Statement Analysis

> **Statement**: "From Kubernetes, we are already aware of the fact that within a pod if we have multiple containers running, by default that means both containers will make use of a common volume under the hood, using which both containers can make use of files and folders residing within the pod. Is this statement correct?"

**Answer**: This statement is **partially correct** but requires an important technical clarification to avoid confusion when building Jenkins pipelines.

## Technical Discussion

### 1. The Correction: Containers are Isolated by Default

If you run two containers (e.g., `ubuntu` and `nodejs` containers) **without any additional configuration**:

- **Files created in `/tmp` on the ubuntu container** cannot be seen by the nodejs container
- **Each container has its own private root file system** based on its Docker image
- **By default, no automatic file sharing occurs** between containers in the same pod

### 2. The "Jenkins Magic": Automatic Sharing

In the specific case of the **Jenkins Kubernetes Plugin**, the original statement appears correct because Jenkins automatically creates and manages shared volumes:

- **Jenkins creates an `EmptyDir` volume** called `workspace-volume`
- **This volume is automatically mounted** to every container in your Pod at `/home/jenkins/agent`
- **Result**: This is why you can download code in the ubuntu container and then run `npm install` on that same code in the nodejs container—they're both accessing the same physical directory managed by Jenkins

### 3. Summary: Shared vs. Isolated Resources

Within a single Pod in EKS:

| Resource | Shared? | Behavior |
|----------|---------|----------|
| **Network** | ✅ YES | Both containers share `localhost`. One container can communicate with another via `localhost:port`. |
| **Storage** | ❌ NO | By default, file systems are isolated between containers. |
| **Volumes** | ✅ YES | If a Volume is mounted to multiple containers, they share that specific folder. |
| **Process Namespace** | ❌ NO | Containers cannot see each other's running processes by default. |

## Practical Implementation in Jenkins Pipeline

### How to Use Shared Volumes in Your Pipeline

To pass files between your ubuntu container and nodejs container:

1. **Work within the shared workspace directory** (`/home/jenkins/agent`)
2. **Create files in one container** and **access them in another container**

### Updated Pipeline Example

Here's how to implement file sharing in your Jenkins pipeline:

```groovy
pipeline {
    agent {
        kubernetes {
            cloud 'EKS-cluster'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: nodejs-container
    image: node:krypton-bookworm
    command:
    - sleep
    args:
    - infinity
  - name: ubuntu-container
    image: ubuntu
    command:
    - sleep
    args:
    - infinity
'''
            defaultContainer 'ubuntu-container'
            retries 2
        }
    }
    stages {
        stage('Print NodeJS Version') {
            steps {
                container('nodejs-container') {
                    sh 'node -v'
                    sh 'npm -v'
                }
            }
        }
        
        stage('Share Data Between Containers') {
            steps {
                // Step 1: Create a file in ubuntu-container
                container('ubuntu-container') {
                    sh '''
                        echo "Hello from Ubuntu Container" > /home/jenkins/agent/message.txt
                        echo "Current directory: $(pwd)"
                        ls -la
                    '''
                }
                
                // Step 2: Read the same file in nodejs-container
                container('nodejs-container') {
                    sh '''
                        echo "Reading from NodeJS Container:"
                        cat /home/jenkins/agent/message.txt
                        echo "Files in shared workspace:"
                        ls -la
                    '''
                }
            }
        }
        
        stage('Collaborative File Processing') {
            steps {
                container('ubuntu-container') {
                    sh '''
                        # Create a data file
                        echo "product,price,quantity" > /home/jenkins/agent/data.csv
                        echo "apple,1.99,10" >> /home/jenkins/agent/data.csv
                        echo "banana,0.99,20" >> /home/jenkins/agent/data.csv
                        echo "orange,2.49,15" >> /home/jenkins/agent/data.csv
                        echo "Data file created by ubuntu container"
                    '''
                }
                
                container('nodejs-container') {
                    sh '''
                        # Process the data file using NodeJS
                        echo "Processing CSV data with NodeJS:"
                        node -e "
                            # Load the built-in File System module in NodeJS so I can read and write files.
                            const fs = require('fs');
                            
                            # Read the CSV file
                            const data = fs.readFileSync('/home/jenkins/agent/data.csv', 'utf8');

                            # Process the data or Split into lines and remove header/footer
                            const lines = data.split('\\n').slice(1, -1);
                            # lines = ["apple,1.99,10", "banana,0.99,20", "orange,2.49,15"]

                            # Calculate total inventory value
                            let total = 0;
                            lines.forEach(line => {
                                const [product, price, quantity] = line.split(',');
                                total += parseFloat(price) * parseInt(quantity);
                            });

                            # Output the result or display the result
                            console.log('Total inventory value: $' + total.toFixed(2));

                            # Write result to a file for ubuntu container to read
                            fs.writeFileSync('/home/jenkins/agent/total.txt', 'Total: $' + total.toFixed(2));
                        "
                    '''
                }
                
                container('ubuntu-container') {
                    sh '''
                        # Read the result generated by NodeJS
                        echo "Result from NodeJS processing:"
                        cat /home/jenkins/agent/total.txt
                    '''
                }
            }
        }
        
        stage('Print Hostname') {
            steps {
                sh 'hostname'
                sh 'sleep 30s'
            }
        }
    }
}
```

## Key Takeaways

### 1. **Volume Mounting is Explicit**
Containers only share files when:
- A volume is explicitly created in the Pod specification
- That volume is mounted to the same path in multiple containers

### 2. **Jenkins Simplifies This Process**
The Jenkins Kubernetes plugin automatically:
- Creates an `EmptyDir` volume
- Mounts it to `/home/jenkins/agent` in all containers
- Manages the volume lifecycle

### 3. **Best Practices for Container Collaboration**
- **Always use the shared workspace** (`/home/jenkins/agent`) for inter-container file sharing
- **Document shared paths** in your pipeline for team clarity
- **Clean up temporary files** to avoid accumulating data in the volume
- **Use meaningful file names** to avoid conflicts between stages

### 4. **Verification Steps**
To verify file sharing is working:

```bash
# In your pipeline, add a verification step
stage('Verify File Sharing') {
    steps {
        container('ubuntu-container') {
            sh '''
                echo "Test file from container 1" > shared-file.txt
                ls -la shared-file.txt
            '''
        }
        container('nodejs-container') {
            sh '''
                echo "Checking file from container 2:"
                cat shared-file.txt
            '''
        }
    }
}
```

## Common Use Cases

1. **Code Compilation & Testing**: One container compiles code, another runs tests
2. **Data Processing**: One container downloads data, another processes it
3. **Multi-language Pipelines**: Different containers handle different language-specific tasks
4. **Asset Generation**: One container generates assets, another packages them

## Troubleshooting

If file sharing isn't working:

1. **Check volume mounts**: Verify both containers mount the same volume at the same path
2. **Verify working directory**: Ensure you're working in the shared directory
3. **Check permissions**: Some containers may run as different users
4. **Inspect pod configuration**: Use `kubectl describe pod` to see volume mounts

```bash
# Debug pod configuration
kubectl describe pod <pod-name> -n jenkins | grep -A5 -B5 "Mounts"
```

By understanding these concepts, you can effectively design Jenkins pipelines that leverage multiple containers while maintaining efficient file sharing between them.