# Jenkins `when` Directive: Conditional Stage Execution

## Overview
The `when` directive in Jenkins pipelines allows conditional execution of stages based on specified conditions. This is essential for creating efficient, targeted pipeline workflows that only run specific stages when required conditions are met.

## Key Features

- **Conditional Execution**: Controls whether a stage should execute based on evaluated conditions
- **Multiple Conditions**: A stage runs if at least one condition in the `when` directive is satisfied
- **Complex Logic**: Supports nesting multiple conditions for advanced control flow
- **Agent Optimization**: Can evaluate conditions before allocating agents to avoid unnecessary resource usage

## Available Conditions

### 1. **Branch Selection**
Executes stage only if the current branch matches the specified pattern:
```groovy
when { branch 'main' }
```

### 2. **Environment Checks**
Runs stage if a specific environment variable is set to a particular value:
```groovy
when { 
    environment name: 'deploy', value: 'pre-prod' 
}
```

### 3. **Custom Expressions**
Executes stage based on evaluation of custom Groovy expressions:
```groovy
when {
    expression {
        return params.MANUAL_TEST
    }
}
```

### 4. **Change Request Handling**
Triggers stage when pipeline is initiated by a pull request/change request:
```groovy
when { changeRequest() }

// With author filtering
when { changeRequest authorEmail: "abc@mail.com" }
```

### 5. **Tag Checks**
Executes stage when building against specific tags:
```groovy
when { buildingTag() }

// With pattern matching
when { tag "feature-*" }
```

### 6. **Before Agent Evaluation**
Evaluates conditions before allocating an agent to avoid unnecessary checkouts:
```groovy
when {
    beforeAgent true
    branch 'sandbox'
}
```

### 7. **Logical NOT**
Inverts the result of nested conditions (runs only if inner condition is false):
```groovy
when {
    not { branch 'pre-prod' }
}
```

### 8. **Logical ANYOF**
Executes stage if any one of the nested conditions evaluates to true:
```groovy
when {
    anyOf {
        branch 'uat'
        branch 'qa'
    }
}
```

### 9. **Logical ALLOF**
Runs stage only if all nested conditions evaluate to true:
```groovy
when {
    allOf {
        branch 'main'
        environment name: 'deploy', value: 'pre-prod'
    }
}
```

## Usage Notes

- Combine multiple conditions for complex workflow logic
- Refer to official Jenkins documentation for additional conditions and advanced usage
- Use `beforeAgent` to optimize resource usage when conditions are likely to fail
- Conditions can be nested to create sophisticated decision trees

## Best Practices

1. Use specific conditions to target exact scenarios
2. Combine `beforeAgent` with expensive conditions to save resources
3. Test complex nested conditions thoroughly
4. Use descriptive condition names for maintainability
5. Consider performance implications of expression evaluations

## Documentation Reference
For complete details and additional conditions, refer to the official Jenkins documentation on the `when` directive.