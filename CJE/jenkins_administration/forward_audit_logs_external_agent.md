    Here's the markdown file for your content:

# Demo: Forward Audit Logs to External Server

In this demo, we are going to forward the logs generated in the previous demo to Elastic Search.

## Setup Process

### 1. Elastic Search Signup
- Used Gmail: `famvaulta@gmail.com` to sign up with Elastic Search

### 2. Initial Configuration
After signup:
- Click on **Observability**
- Click on **Add Data** (visible on the top right of the UI)
- **What do you want to monitor?** → Select **Host**
- **Monitor your Host using:** → Select **Elastic Agent: Logs & Metrics**

### 3. Installation Instructions
Follow the instructions to **Install standalone Elastic Agent on your host**.

**Note:** In this case, the host is my Jenkins controller since this is the machine which stores audit logs:
- `audit-0.log-2026-01-08`
- `audit-0.log-2026-01-08.lck`

We are going to shift these logs to ES server hosted on cloud (SaaS offering).

### 4. Install Standalone Elastic Agent

Run the following command on your host (Jenkins controller):

```bash
curl https://03bb17b217c54340a69f1acd72d52156.us-central1.gcp.cloud.es.io/4fac8383dfc0/plugins/observabilityOnboarding/assets/auto_detect.sh -so auto_detect.sh && sudo bash auto_detect.sh --id=df14ce63-2534-4eb1-8bc5-c39db389a73d --kibana-url=https://03bb17b217c54340a69f1acd72d52156.us-central1.gcp.cloud.es.io --install-key=SEJuNm1ac0JXdEdsdnpiZkZoMU06RTc0bWs4UmhVNEROc0M5MW5fSVhZUQ== --ingest-key=YmN6Nm1ac0JvNVR6Zk1WLUZ2MC06T0RWRFp2SmNYQUJnNm5IR1hIQ3J6Zw== --ea-version=9.2.3
```

### 5. Configuration
- After running the above commands, follow the instructions that appear on the CLI
- Confirm which logs you need Elastic Search to visualize

## Verification

Once ES completes its validation, you can see logs getting published under ES UI under the **Discover** option available under **Observability**.

**To review the logs:** Apply timestamp filter for 8th-Jan-2026 (from 1:00 AM to 2:00 AM IST)

## Sample Logs

```
Jan 8, 2026 12:30:45,795 AM
monitor-jenkins-grafana-prometheus #49
Started by user user2, Parameters:[]
on Built-In Node;Slave-Agent-Node-1 started at 2026-01-07T18:58:04Z
completed in 160980ms
completed: SUCCESS

Jan 8, 2026 12:34:15,080 AM
job/monitor-jenkins-grafana-prometheus/ #50
Started by user user2, Parameters:[]

Jan 8, 2026 12:42:30,800 AM
job/monitor-jenkins-grafana-prometheus/ #51
Started by user user2, Parameters:[]
```

## Log Metadata

| Field | Value |
|-------|-------|
| Service name | `var_log_jenkins` |
| Host name | `laptop-49sh4k4v` |
| Log path file | `/var/log/jenkins/audit-0.log-2026-01-08` |
| Dataset | `var_log_jenkins` |
| Namespace | `default` |
| Shipper | `LAPTOP-49SH4K4V` |

## KQL Filter Example

One of the KQL filters applied:
```
"user2" AND "user"
```