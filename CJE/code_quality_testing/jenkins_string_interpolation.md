# Jenkins String Interpolation Demo

## Overview

This demo illustrates how string interpolation works in Jenkins pipelines, showing the differences between single quotes and double quotes, and demonstrating various interpolation scenarios with different variable types.

## String Interpolation Basics

**Key Rule**: String interpolation **only works with double quotes (`"`)** in Jenkins/Groovy pipelines. Single quotes (`'`) treat content as literal strings.

### Example Comparison:
```groovy
def name = "Jenkins-demo-user"
echo 'Hello, ${name}'      # Output: Hello, ${name}  (No interpolation)
echo "Hello, ${name}"      # Output: Hello, Jenkins-demo-user  (Interpolation works)
```

## Pipeline Configuration

### Project Setup
- **Project Name**: String-Interpolation-Demo
- **Project Type**: Pipeline
- **Configuration**: Direct pipeline script (without SCM)

### Pipeline Script

```groovy
pipeline{
    
    agent any

    parameters {
      string (defaultValue: 'Hello, Jenkins! from parameters', 
              description: 'Name of the user', 
              name: 'USER_NAME')
    }

    environment {
      GREETING = "Hello....&.....Welcome from environment variable...!!!"
    }

    stages {
        stage ('Print basic string') {
            steps {
                script {
                    echo 'This is basic string interpolation example.'
                }
            }
        }
        stage ('Interpolation with variable') {
            steps {
                script {
                    def name = "Jenkins-demo-user"
                    echo 'Hello, ${name}'      # No interpolation
                    echo "Hello, ${name}"      # Interpolation works
                }
            }
        }
        stage ('Interpolation with parameter') {
            steps {
                script {
                    echo "Hello, ${params.USER_NAME}"
                }
            }
        }
        stage ('Interpolation with environment variables') {
            steps {
                script {
                    echo "Environment variable greeting: ${env.GREETING}"
                }
            }
        }
        stage ('Interpolation with Expressions') {
            steps {
                script {
                    def x = 10
                    def y = 20
                    def sum = x + y
                    echo "Addition of 2 numbers is: ${sum}"
                }
            }
        }
        stage ('Complex Interpolation') {
            steps {
                script {
                    def list = [1, 2, 3]
                    echo "The number of elements that list has: ${list.size()} and elements in the list are: ${list.join(', ')}"
                }
            }
        }
        stage ('Job Parameters') {
            steps {
                script {
                    def build_number = currentBuild.number
                    echo "The current running build number is: ${build_number}"
                    def build_result = currentBuild.currentResult 
                    echo "The build result is: ${build_result}"
                }
            }
        }
    }
}
```

## Stage-by-Stage Breakdown

### 1. **Print Basic String**
- Demonstrates basic string output without interpolation
- Uses single quotes for literal string output

### 2. **Interpolation with Variable**
- Shows the difference between single and double quotes
- Single quotes: `${name}` is treated as literal text
- Double quotes: `${name}` is replaced with variable value

### 3. **Interpolation with Parameter**
- Accesses pipeline parameters using `${params.PARAMETER_NAME}`
- Parameters are defined in the `parameters` block

### 4. **Interpolation with Environment Variables**
- Accesses environment variables using `${env.VARIABLE_NAME}`
- Environment variables are defined in the `environment` block

### 5. **Interpolation with Expressions**
- Demonstrates mathematical expression evaluation
- Calculations can be performed within `${}`

### 6. **Complex Interpolation**
- Shows method calls within interpolation
- Multiple interpolations in a single string
- Collection manipulation within interpolation

### 7. **Job Parameters**
- Accesses Jenkins job/build information using global variables
- **`currentBuild.number`**: Gets the current build number
- **`currentBuild.currentResult`**: Gets the current build result (SUCCESS, FAILURE, etc.)

## Accessing Different Variable Types

| Variable Type | Syntax | Example |
|--------------|--------|---------|
| Local Variable | `${variable}` | `${name}` |
| Pipeline Parameter | `${params.PARAM_NAME}` | `${params.USER_NAME}` |
| Environment Variable | `${env.VAR_NAME}` | `${env.GREETING}` |
| Global Variable | `${globalVar}` | `${currentBuild.number}` |

## Common Global Variables for Job Information

Here are some useful global variables for accessing job information:

```groovy
// Build Information
echo "Build Number: ${currentBuild.number}"
echo "Build Result: ${currentBuild.currentResult}"
echo "Build URL: ${env.BUILD_URL}"

// Job Information
echo "Job Name: ${env.JOB_NAME}"
echo "Job Base Name: ${env.JOB_BASE_NAME}"

// Workspace Information
echo "Workspace: ${env.WORKSPACE}"
```

## Best Practices

1. **Use double quotes** when you need interpolation
2. **Use single quotes** for literal strings to avoid accidental interpolation
3. **Be explicit** with variable scopes (e.g., `env.`, `params.`)
4. **Validate expressions** within `${}` for complex operations
5. **Escape special characters** when needed with backslash (`\`)

## Official Documentation Reference

For more detailed information, refer to the official Jenkins documentation:
- [Jenkins Pipeline: String Interpolation](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#string-interpolation)

## Troubleshooting

**Issue**: Interpolation not working even with double quotes
**Solution**: Check variable scope and ensure the variable is defined in the current context

**Issue**: Special characters breaking interpolation
**Solution**: Escape special characters or use different quotation marks

**Issue**: Cannot access job parameters
**Solution**: Ensure parameters are properly defined in the `parameters` block and accessed via `params.`

## Example Output

When running this pipeline, you should see output similar to:

```
[Print basic string] This is basic string interpolation example.
[Interpolation with variable] Hello, ${name}
[Interpolation with variable] Hello, Jenkins-demo-user
[Interpolation with parameter] Hello, Hello, Jenkins! from parameters
[Interpolation with environment variables] Environment variable greeting: Hello....&.....Welcome from environment variable...!!!
[Interpolation with Expressions] Addition of 2 numbers is: 30
[Complex Interpolation] The number of elements that list has: 3 and elements in the list are: 1, 2, 3
[Job Parameters] The current running build number is: 1
[Job Parameters] The build result is: SUCCESS
```

This demo provides a comprehensive understanding of how string interpolation works in Jenkins pipelines, enabling you to effectively use variables and expressions in your pipeline scripts.