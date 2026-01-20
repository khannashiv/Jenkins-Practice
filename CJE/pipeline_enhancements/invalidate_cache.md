# Cache Invalidation Demo

## Overview
This document demonstrates how cache invalidation works in a Jenkins pipeline when project dependencies are updated. Cache invalidation forces the system to ignore previously cached data and perform tasks from scratch to ensure everything is up to date.

## Key Concept
- **Invalidating Cache**: When `package.json` or `package-lock.json` files are updated (typically after installing new dependencies), Jenkins detects these changes and invalidates the existing cache.
- Jenkins generates a new hash based on the updated files (primarily `package-lock.json`) and rebuilds the cache accordingly.

## Demonstration Steps

1. **Install a New Dependency**:
   ```bash
   npm install localtunnel
   ```

2. **Commit Changes**:
   - Commit the updated `package-lock.json` and/or `package.json` files to the Git repository.

3. **Jenkins Pipeline Execution**:
   - Refer to **Build #28** in the Jenkins project for detailed console output logs.
   - **Full Project Name**: `Organization-folder-demo/solar-system-migrate/feature%2Fk8s-agent`

## Sample Jenkins Logs
The logs below illustrate the cache invalidation process:

```
[Pipeline] cache
16:11:14  [Cache for node_modules/ (npm-dependency-cache) with id acd06b18086a0dd2ae699b1e0b775be8] Searching cache in job specific caches...
16:11:14  [Cache for node_modules/ (npm-dependency-cache) with id acd06b18086a0dd2ae699b1e0b775be8] got hash 7f9d1e32bbf12625d0cd119314bb7274 for cacheValidityDecidingFile(s) - actual file(s): /var/lib/jenkins/workspace/system-migrate_feature_k8s-agent/package-lock.json
16:11:14  [Cache for node_modules/ (npm-dependency-cache) with id acd06b18086a0dd2ae699b1e0b775be8] cacheValidityDecidingFile configured, but previous hash does not match - cache outdated
16:11:14  [Cache for node_modules/ (npm-dependency-cache) with id acd06b18086a0dd2ae699b1e0b775be8] Searching cache in default caches...
16:11:14  [Cache for node_modules/ (npm-dependency-cache) with id acd06b18086a0dd2ae699b1e0b775be8] Skip restoring cache as no up-to-date cache exists
[Pipeline] {
[Pipeline] script
[Pipeline] {
[Pipeline] sh
16:11:14  + node -v
16:11:14  v23.11.1
[Pipeline] sh
16:11:15  + npm install --no-audit
16:11:16  
16:11:16  added 9 packages in 1s
16:11:16  
16:11:16  62 packages are looking for funding
16:11:16    run `npm fund` for details
[Pipeline] stash
16:11:21  Stashed 6387 file(s)
[Pipeline] }
[Pipeline] // script
[Pipeline] }
16:11:21  [Cache for node_modules/ (npm-dependency-cache) with id acd06b18086a0dd2ae699b1e0b775be8] got hash 7f9d1e32bbf12625d0cd119314bb7274 for cacheValidityDecidingFile(s) - actual file(s): /var/lib/jenkins/workspace/system-migrate_feature_k8s-agent/package-lock.json
16:11:21  [Cache for node_modules/ (npm-dependency-cache) with id acd06b18086a0dd2ae699b1e0b775be8] cacheValidityDecidingFile configured, but previous hash does not match - cache outdated
16:11:21  [Cache for node_modules/ (npm-dependency-cache) with id acd06b18086a0dd2ae699b1e0b775be8] Creating cache...
16:11:22  [Cache for node_modules/ (npm-dependency-cache) with id acd06b18086a0dd2ae699b1e0b775be8] got hash 7f9d1e32bbf12625d0cd119314bb7274 for cacheValidityDecidingFile(s) - actual file(s): /var/lib/jenkins/workspace/system-migrate_feature_k8s-agent/package-lock.json
16:11:22  [Cache for node_modules/ (npm-dependency-cache) with id acd06b18086a0dd2ae699b1e0b775be8] Cache created in 1165ms
[Pipeline] // cache
[Pipeline] }
```

## Log Breakdown
- **Cache Detection**: Jenkins searches for existing caches and compares the hash of `package-lock.json`.
- **Cache Outdated**: Since the hash doesn't match (due to dependency updates), Jenkins skips restoring the old cache.
- **Fresh Installation**: `npm install --no-audit` is executed to install dependencies from scratch.
- **New Cache Creation**: After installation, Jenkins creates a new cache with the updated hash.

## Conclusion
Cache invalidation ensures that the build environment uses the most recent dependencies, preventing stale or incorrect data from affecting the build process. This mechanism is automatically triggered when dependency files (`package.json`/`package-lock.json`) are modified.

## References
- Jenkins Cache Plugin Documentation: https://plugins.jenkins.io/cache/
- Jenkins Pipeline Syntax: https://www.jenkins.io/doc/book/pipeline/syntax/
- Gitea repository holding source code: https://gitea.com/my-demo-active-org/solar-system-migrate/src/branch/feature/k8s-agent/
