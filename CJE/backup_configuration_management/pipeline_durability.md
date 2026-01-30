# Jenkins Pipeline Durability Demo

## Overview
This demo explores Jenkins Pipeline durability settings, which determine how pipeline jobs handle unexpected restarts compared to traditional freestyle jobs. The key difference is that pipeline jobs can resume after interruptions due to frequent disk writes, but this comes with performance trade-offs.

## Key Concepts

### Pipeline vs. Freestyle Jobs
- **Pipeline Jobs**: Can resume after unexpected Jenkins restarts or system crashes due to frequent transient data writes to disk
- **Freestyle Jobs**: Cannot resume after interruptions
- **Trade-off**: Performance issues may arise in pipelines with 100+ steps due to frequent disk I/O

### Durability Settings

#### 1. **Performance-Optimized Mode** (`PERFORMANCE_OPTIMIZED`)
- **Description**: Greatly reduces disk I/O
- **Risk**: Pipelines may lose data if Jenkins is not shut down gracefully
- **Behavior**: Behaves like Freestyle projects in crash scenarios
- **Use Case**: Non-critical pipelines where performance is prioritized

#### 2. **Maximum Survivability/Durability** (`MAX_SURVIVABILITY`)
- **Description**: Original Pipeline behavior, slowest option
- **Risk**: Minimal data loss risk
- **Use Case**: Critical pipelines where data integrity is paramount

#### 3. **Less Durable, Faster** (`SURVIVABLE_NONATOMIC`)
- **Description**: Writes data with every step but avoids atomic writes
- **Performance**: Faster than maximum durability, especially on networked filesystems
- **Risk**: Small extra risk of data corruption
- **Use Case**: Balance between performance and durability

## Configuration Methods

### 1. Global Configuration
**Path**: Jenkins UI → Manage Jenkins → System → "Pipeline Speed/Durability Settings"

**Options**:
- `MAX_SURVIVABILITY`
- `PERFORMANCE_OPTIMIZED` 
- `SURVIVABLE_NONATOMIC`

### 2. Multi-branch Project Level
**Configuration Steps**:
1. Navigate to Organization Folder → Configure
2. Find "Property Strategy"
3. Select "Named branches get different properties"
4. Add exceptions for specific branches:
   - **Main branch**: Add property → "Pipeline branch speed/durability override" → `MAX_SURVIVABILITY`
   - **Feature branches**: Add property → "Pipeline branch speed/durability override" → `PERFORMANCE_OPTIMIZED`

### 3. Individual Project Level
**Configuration Steps**:
1. Create/Edit Pipeline Job
2. Under Configuration settings, find "Pipeline speed/durability override"
3. Select desired durability level
4. Apply and save

## Demonstration

### Test Scenario: Pipeline with 600 Iterations
```groovy
// Sample test pipeline
pipeline {
    agent any
    stages {
        stage('Test Durability') {
            steps {
                script {
                    for (int i = 0; i < 600; i++) {
                        echo "Iteration ${i}"
                        sleep 1
                    }
                }
            }
        }
    }
}
```

### Test Procedure

#### **Test 1: MAX_SURVIVABILITY**
1. Configure pipeline with `MAX_SURVIVABILITY`
2. Start pipeline execution
3. Force kill Jenkins: `kill -9 <jenkins_pid>`
4. Wait 2 minutes
5. Restart Jenkins
6. **Result**: Pipeline resumes from last saved state

#### **Test 2: PERFORMANCE_OPTIMIZED**
1. Configure pipeline with `PERFORMANCE_OPTIMIZED`
2. Start pipeline execution
3. Force kill Jenkins: `kill -9 <jenkins_pid>`
4. Wait 2 minutes
5. Restart Jenkins
6. **Result**: Pipeline fails with error:
   ```
   Cannot resume the build since PERFORMANCE_OPTIMIZED durability settings were used and Jenkins was not shut down cleanly
   ```

## Important Notes

1. **Properties Step**: Use `properties` step in pipeline script to override durability settings for the NEXT run only
2. **Branch Properties**: Multi-branch project settings override global settings
3. **Job Configuration**: Project-level settings override branch and global settings
4. **Clean Shutdown**: `PERFORMANCE_OPTIMIZED` requires clean Jenkins shutdown for pipeline recovery

## Best Practices

1. **Critical Pipelines**: Use `MAX_SURVIVABILITY` for production or critical workflows
2. **Development/Test Pipelines**: Use `PERFORMANCE_OPTIMIZED` for better performance
3. **Mixed Environments**: Configure different durability levels per branch in multi-branch projects
4. **Networked Filesystems**: Consider `SURVIVABLE_NONATOMIC` for better performance on shared storage

## References
- [Official Jenkins Documentation](https://www.jenkins.io/doc/book/pipeline/scaling-pipeline/)
- Always refer to the latest Jenkins documentation for updates and additional configuration options

## Troubleshooting
- If pipelines fail to resume after restart, check durability settings
- Ensure proper file system permissions for Jenkins workspace
- Monitor disk I/O performance on Jenkins server
- Consider Jenkins master high availability for critical environments