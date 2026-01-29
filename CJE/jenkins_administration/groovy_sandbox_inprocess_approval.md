# Jenkins Groovy Sandbox and In-process Script Approval

## Overview

This document explains the **Groovy Sandbox** feature in Jenkins, a critical security mechanism that controls script execution within Jenkins pipelines. When enabled, it provides a restricted environment that prevents potentially harmful operations while allowing necessary pipeline functionality.

---

## What is Groovy Sandbox?

- **Purpose**: Jenkins (and many plugins) allow users to execute Groovy scripts. To safeguard Jenkins from malicious scripts, the **Script Security Plugin** executes user-provided scripts within a Groovy Sandbox.
- **Default Status**: Enabled by default.
- **Function**: Provides a safe execution environment where anyone can test scripts without risking harm to the Jenkins environment.

---

## How Groovy Sandbox Works

1. **Method-Level Security**  
   During script execution, **each method call and field access** is verified against an approved allow list.

2. **Approved Operations**  
   If all operations are permitted, the script runs smoothly.

3. **Unapproved Operations**  
   If an unapproved operation is attempted, the script is **terminated immediately**.

   **Example**:  
   By default, scripts are **not allowed** to use the `getInstance()` static method. If called, the pipeline is terminated.

4. **Use Case**  
   The sandbox provides a safe space to test pipeline code that hasn't been thoroughly reviewed or validated.

---

## Script Approval Process

When a script fails due to an unapproved operation:

1. **Notification in Build Logs**  
   The build log displays a message indicating the unapproved signature/method.

2. **Approval Queue**  
   The unapproved operation is added to an **approval queue**.

3. **Admin Intervention**  
   An administrator can review and approve scripts via:
   - **Manage Jenkins** → **Security** → **In-process Script Approval**

---

## Approval Options

Admins have three choices when reviewing scripts:

1. **Approve**  
   Allows the script to run without restrictions.

2. **Deny**  
   Blocks the script from running.

3. **Approve Assuming Permissions Check**  
   Allows the script to run **only if** the user executing it has the necessary permissions. This ensures scripts adhere to existing user permission rules, making it a more secure approval method.

---

## Approved Signatures List

- Once a method or signature is approved, it is added to an **approved signatures list**.
- Any pipeline or script using that method can run **until it is removed** from the approved list.

---

## Sandbox Disabled or Unchecked

- If the Groovy Sandbox is **disabled or unchecked**, scripts/pipelines **will not execute**.
- **Non-admin users** will see a note: *"Jenkins admin must approve this script/method before it can be used."*
- **Admin users** will see a prompt to approve the script directly on the configuration page.

---

## Pipeline Execution Behavior

- If a pipeline contains an unapproved script, **the entire pipeline fails**—**none** of the stages are executed.
- **Example**: A 10-stage pipeline where the 10th stage calls an unapproved method will fail immediately at the start. Even if the first 9 stages are correctly written, they will be ignored.

---

## Best Practices

### 1. **Sandbox is Crucial for Scripted Pipelines**
   - The script security sandbox is more critical for **Scripted Pipelines** than Declarative Pipelines because Declarative Pipelines are less complex and harder to misuse.

### 2. **Iterative Allow List Management**
   - The sandbox can be **annoying** because scripts fail on the first unapproved item, requiring several iterations to get all operations onto the allow list.

### 3. **Never Disable the Sandbox**
   - Disabling the sandbox carries **enormous risk** and **should not be done**.

### 4. **Allow List Guidelines**
   - **Avoid** including operations that **change the state of persisted objects**, such as:
     - `setProperty`
     - `execute` methods
   - **Generally safe** to include **"get" methods** (e.g., `getProperty`, `getName`), as they are harmless and can be easily added to the allow list.

---

## Summary

- **Groovy Sandbox** = Restricted execution environment for Jenkins scripts.
- **In-process Script Approval** = Admin-controlled mechanism to allow specific scripts/methods.
- **Fail-fast behavior** = Unapproved scripts halt the entire pipeline.
- **Security first** = Keep the sandbox enabled, approve cautiously, and follow best practices for allow list management.

---
*For more details, refer to the [Jenkins Script Security Plugin documentation](https://plugins.jenkins.io/script-security/).*