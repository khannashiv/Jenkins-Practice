# Jenkins Pipeline: Stash & Unstash Demo

## Overview
This Jenkins pipeline demonstrates the use of **stash** and **unstash** commands to share files between different stages and nodes within the same pipeline run. The example specifically shows how to cache and reuse `node_modules` directory across different stages to optimize build performance.

## Prerequisites
- Jenkins with Pipeline plugin installed
- Node.js and npm available on Jenkins agents
- Basic understanding of Jenkins Pipeline syntax

## Pipeline Concept

### Stash Command
The `stash` command saves a set of files for later use on any node/workspace in the same Pipeline run. By default, stashed files are discarded at the end of a pipeline run.

**Syntax:**
```groovy
stash includes: 'path/to/files/', name: 'unique-stash-name'
```

### Unstash Command
The `unstash` command retrieves previously stashed files into the current workspace.

Stash and unstash work seamlessly across different agent types (K8s, Docker, or any agent) within the same pipeline run, enabling efficient artifact sharing between stages.

For example, you can stash files on a Kubernetes agent and unstash them on a Docker agent or vice versa within the same pipeline execution.

**Syntax:**
```groovy
unstash 'unique-stash-name'
```

## Pipeline Flow

### Stage 1: Installing Node.js Dependencies
1. Clone the repository
2. Install Node.js dependencies using `npm install --no-audit`
3. **Stash** the `node_modules/` folder with a unique name for later use

### Stage 2: NodeJS 20 - Install Dependencies (Sequential)
1. Instead of re-installing dependencies, **unstash** the previously saved `node_modules/` folder
2. This significantly reduces build time by avoiding redundant npm installations

## Code Implementation

### Key Pipeline Snippets

**Stashing the node_modules folder:**
```groovy
stage("Installing nodejs dependencies") {
    steps {
        sh 'npm install --no-audit'
        stash includes: 'node_modules/', name: 'solar-system-node-modules'
    }
}
```

**Unstashing the node_modules folder:**
```groovy
stage("Install-dependency-Sequential") {
    steps {
        // Instead of: sh 'npm install --no-audit'
        unstash 'solar-system-node-modules'
    }
}
```

## Benefits

1. **Performance Optimization**: Avoids redundant dependency installations
2. **Resource Efficiency**: Reduces network usage and build time
3. **Consistency**: Ensures the same dependencies are used across stages
4. **Cross-Node Sharing**: Enables file sharing between different Jenkins agents

## Notes

- Stashed files are automatically discarded at the end of the pipeline run by default
- Some plugins (like Declarative Pipeline with `preserveStashes()`) can retain stashes for longer periods
- The stash name must be unique within the pipeline
- Only files within the workspace can be stashed
- Stash/unstash works across different nodes but within the same pipeline run

## Official Documentation
For more details, refer to the [Jenkins Pipeline Basic Steps Documentation](https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/)

## Build Information
- **Project**: Organization-folder-demo/solar-system-migrate/feature%2Fk8s-agent
- **Demo Build**: #23

## Troubleshooting

If the unstash fails:
1. Verify the stash name matches exactly
2. Ensure the stash was created successfully in a previous stage
3. Check that the pipeline hasn't been restarted (unless using `preserveStashes()`)
4. Confirm the files exist in the expected location before stashing

## Best Practices

1. Use descriptive stash names related to the content
2. Only stash necessary files to minimize storage usage
3. Consider using `excludes` parameter to omit unnecessary files
4. Document stash names used in the pipeline for team reference
5. Clean up temporary files before stashing when appropriate