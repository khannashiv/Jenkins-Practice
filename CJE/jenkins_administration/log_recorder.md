# Jenkins Log Recorder Demo: Kubernetes Connection Troubleshooting

## Overview
This document demonstrates how to use Jenkins Log Recorder to troubleshoot Kubernetes plugin connection issues. The example shows how to configure detailed logging for the Fabric8 Kubernetes client to diagnose connection problems with an EKS cluster.

## Official Documentation
- [CloudBees Documentation: Configure Loggers](https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/configure-loggers-for-jenkins)
- [Jenkins Documentation: Viewing Logs](https://www.jenkins.io/doc/book/system-administration/viewing-logs/)
- [Jenkins Wiki: Logging](https://wiki.jenkins.io/JENKINS/Logging.html)
- [JavaDoc: LogRecorder](https://javadoc.jenkins.io/hudson/logging/LogRecorder.html)

## Important Performance Consideration
**⚠️ Warning:** Changing the log level of a package can generate extensive logs and may affect controller performance due to increased IO throughput (causing iowait). It is recommended to:
1. Change log levels only when troubleshooting specific issues
2. Revert to default levels after completing troubleshooting

## Solution 1: Adding a Logger from the UI (Recommended)

### Step-by-Step Configuration
1. **Navigate to Log Recorder:**
   - Go to **Manage Jenkins** → **System Log** → **Add recorder** (previously "Add New Log Recorder")

2. **Create Log Recorder:**
   - Provide a name for the logger (does not need to match package/class name)
   - Example: `k8s-logger-1`

3. **Add Logger Configuration:**
   - Under the **Loggers** section, click **Add**
   - Enter the package/class name to monitor (auto-complete available based on controller classes)
   - Example: `io.fabric8.kubernetes`
   - Choose log level: **ALL**
   - Click **Save**

### Configuration Summary
| Setting | Value |
|---------|-------|
| **Recorder Name** | k8s-logger-1 |
| **Package/Class** | io.fabric8.kubernetes |
| **Log Level** | ALL |
| **Action Path** | Manage Jenkins → System Log → Add recorder |

## Example Use Case: Troubleshooting EKS Connection

### Problem Scenario
When testing connection to an EKS cluster, only a generic error is displayed:
```
Error testing connection https://5230E0884E76DBCC8EA60734CD280D1D.gr7.us-east-1.eks.amazonaws.com: java.io.IOException: 5230e0884e76dbcc8ea60734cd280d1d.gr7.us-east-1.eks.amazonaws.com
```

### Solution with Log Recorder
After configuring the `k8s-logger-1` log recorder with `io.fabric8.kubernetes` package at **ALL** level:

1. **Trigger the Connection Test:**
   - Navigate to **Manage Jenkins** → **Clouds**
   - Select your cloud (e.g., `EKS-cluster`)
   - Click **Configure**
   - Locate credentials section
   - Perform **Test Connection**

2. **View Detailed Logs:**
   - Go to **Manage Jenkins** → **System Log** → **k8s-logger-1**
   - Observe detailed logging with stack traces and retry patterns

### Sample Log Output (Abbreviated)
```
Jan 07, 2026 11:39:29 PM FINE io.fabric8.kubernetes.client.utils.HttpClientUtils getHttpClientFactory
Using httpclient io.fabric8.kubernetes.client.okhttp.OkHttpClientFactory factory

Jan 07, 2026 11:39:29 PM FINE io.fabric8.kubernetes.client.http.StandardHttpClient shouldRetry
HTTP operation on url: https://5230E0884E76DBCC8EA60734CD280D1D.gr7.us-east-1.eks.amazonaws.com/api/v1/namespaces/jenkins/pods 
should be retried after 100 millis because of IOException
java.net.UnknownHostException: 5230e0884e76dbcc8ea60734cd280d1d.gr7.us-east-1.eks.amazonaws.com: Name or service not known
```

### Issue Identified
The logs reveal a **DNS resolution failure** (`UnknownHostException`) with detailed retry patterns (100ms, 200ms, 400ms intervals), providing much more diagnostic information than the original error message.

## Cleanup Procedure

Once troubleshooting is complete, remove the log recorder to prevent performance impact:

1. Navigate to **Manage Jenkins** → **System Log**
2. Locate your log recorder (e.g., `k8s-logger-1`)
3. Click on the **three dots (⋮)** menu
4. Select **Delete log recorder**

## Best Practices

1. **Temporary Usage:** Only enable detailed logging during active troubleshooting
2. **Specific Targeting:** Use the most specific package/class possible
3. **Documentation:** Record findings before deleting log recorders
4. **Cleanup:** Always remove log recorders after issue resolution
5. **Monitoring:** Monitor system performance while detailed logging is enabled

## Additional Notes

- Log levels available: ALL, FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE
- Multiple loggers can be added to a single log recorder
- Logs can be downloaded for offline analysis
- Consider using log rotation for extensive logging sessions

---

*This demo shows how Jenkins Log Recorder can transform vague error messages into actionable diagnostic information for effective troubleshooting.*