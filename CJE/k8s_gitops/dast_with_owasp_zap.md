# README.md

# DAST with OWASP ZAP - Dynamic Application Security Testing

## 📋 Table of Contents
- [Overview](#overview)
- [What is DAST?](#what-is-dast)
- [DAST vs SAST](#dast-vs-sast)
- [OWASP ZAP](#owasp-zap)
- [Prerequisites](#prerequisites)
- [Demo: DAST with OWASP ZAP](#demo-dast-with-owasp-zap)
- [Demo: DAST Ignore Rules](#demo-dast-ignore-rules)
- [Jenkins Pipeline Integration](#jenkins-pipeline-integration)
- [Network Configuration & Port Forwarding](#network-configuration--port-forwarding)
- [ZAP Configuration File](#zap-configuration-file)
- [Report Generation](#report-generation)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Overview

This repository demonstrates the implementation of **Dynamic Application Security Testing (DAST)** using OWASP ZAP (Zed Attack Proxy) in a Jenkins pipeline. The demo showcases how to integrate automated security scanning into a DevSecOps workflow, specifically targeting APIs defined by OpenAPI specifications.

The solution includes:
- DAST scanning for applications deployed on Kubernetes clusters
- Jenkins pipeline integration with OWASP ZAP Docker container
- Handling network connectivity between Jenkins, Minikube, and application endpoints
- Configuring ZAP to ignore specific warnings during scanning
- Generating comprehensive security reports in multiple formats

---

## What is DAST?

**Dynamic Application Security Testing (DAST)** is a black-box testing methodology that identifies security vulnerabilities in running applications. Unlike static analysis, DAST does not require access to the source code—it interacts with the application through its web interfaces and APIs, injecting malicious payloads to detect potential flaws.

### Key Characteristics:
- Tests applications in their **running state**
- Identifies vulnerabilities like **SQL injection**, **Cross-Site Scripting (XSS)**, and **security misconfigurations**
- Simulates real-world attack scenarios
- Can be automated and integrated into CI/CD pipelines

---

## DAST vs SAST

| Feature | DAST | SAST |
|---------|------|------|
| **Application State** | Requires running application | Works on source code |
| **Access Required** | External (black-box) | Internal (white-box) |
| **When to Run** | After deployment | During development |
| **Vulnerabilities Found** | Runtime issues, configuration flaws | Code-level issues |
| **False Positives** | Lower | Higher |

---

## OWASP ZAP

[OWASP ZAP](https://www.zaproxy.org/) (Zed Attack Proxy) is an open-source web application security scanner maintained by OWASP. It's one of the most popular DAST tools available.

### ZAP Docker Images
Official Docker images are available at `ghcr.io/zaproxy/zaproxy` with several scanning modes:

- **Baseline Scan**: Passive scanning for quick checks
- **Full Scan**: Comprehensive active scanning
- **API Scan**: **Specialized for API testing** (used in this demo)

### ZAP API Scan
The API Scan is specifically tuned for:
- OpenAPI, SOAP, and GraphQL APIs
- Imports API definitions and runs active scans against discovered URLs
- Includes scripts to detect:
  - HTTP Server Error response codes
  - Unexpected content types in API responses

---

## Prerequisites

### Infrastructure Requirements
- Kubernetes cluster (Minikube used in this demo)
- Jenkins server (running on WSL/Ubuntu)
- Docker (for running ZAP container)
- kubectl configured for cluster access

### Application Requirements
- Deployed application with OpenAPI/Swagger endpoint
- API specification accessible via URL or local file
- Running application accessible to Jenkins

---

## Demo: DAST with OWASP ZAP

### Architecture Overview
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Minikube VM   │     │  Ubuntu VM       │     │  Jenkins/WSL    │
│   (192.168.49.2)│────▶│  (192.168.10.202)│────▶│  Machine        │
│   ┌───────────┐ │     │  ┌────────────┐  │     └─────────────────┘
│   │ App Pod   │ │     │  │ ZAP Docker │  │            │
│   │ Port:3000 │ │     │  │ Container  │  │◄───────────┘
│   └───────────┘ │     │  └────────────┘  │     (Triggers Scan)
│         │       │     │         │        │
│   ┌─────▼─────┐ │     │  ┌──────▼─────┐  │
│   │ Service   │ │     │  │ API-Docs   │  │
│   │ Port:3000 │ │     │  │ Endpoint   │  │
│   └─────┬─────┘ │     │  └────────────┘  │
│         │       │     └──────────────────┘
│   ┌─────▼─────┐ │              │
│   │ Port-     │ │              │
│   │ Forward   │ │◄─────────────┘
│   │ 30000:3000│ │      (Port Forward)
│   └───────────┘ │
└─────────────────┘
```

### Key Components:
1. **Application deployed on Minikube**: Accessible via `http://192.168.49.2:30000/api-docs` (within cluster)
2. **Port forwarding**: Makes application available on VM's bridged network at `http://192.168.10.202:30000/api-docs`
3. **ZAP Docker container**: Executes API scan against the exposed endpoint
4. **Jenkins pipeline**: Orchestrates the scanning process

---

## Demo: DAST Ignore Rules

When running ZAP scans, various warnings may be generated that don't represent critical vulnerabilities or are false positives. ZAP provides mechanisms to ignore specific warnings.

### Common Warnings Encountered:
| Rule ID | Description |
|---------|-------------|
| 100001 | Unexpected Content-Type returned |
| 10020 | Missing Anti-clickjacking Header |
| 10021 | X-Content-Type-Options Header Missing |
| 10037 | Server Leaks Information via X-Powered-By |
| 10038 | Content Security Policy (CSP) Header Not Set |
| 10063 | Permissions Policy Header Not Set |
| 10098 | Cross-Domain Misconfiguration |
| 90003 | Sub Resource Integrity Attribute Missing |
| 90004 | Insufficient Site Isolation Against Spectre Vulnerability |

### Solution: Configuration File
Create a configuration file to ignore specific warnings:

```bash
# zap_ignore_rules
# Format: [Rule ID] [Action] [URL Pattern] (tab-separated)
100001	IGNORE	http://192.168.10.202:1234
10020	IGNORE	http://192.168.10.202:1234
10021	IGNORE	http://192.168.10.202:1234
10037	IGNORE	http://192.168.10.202:1234
10038	IGNORE	http://192.168.10.202:1234
10063	IGNORE	http://192.168.10.202:1234
10098	IGNORE	http://192.168.10.202:1234
90003	IGNORE	http://192.168.10.202:1234
90004	IGNORE	http://192.168.10.202:1234
```

---

## Jenkins Pipeline Integration

### Stage 1: Application Deployment Verification

```groovy
stage ('APP - Deployed?') {
    when {
        branch 'PR*'
    }
    steps {
        script {
            timeout(time: 1, unit: 'DAYS') {
                input message: 'Is the PR merged & ArgoCD Synced ?', 
                      ok: 'YES ! PR is merged & ArgoCD is merged as well.'
            }
        }
    }
}
```

**Purpose**: Ensures the application is in a running state before initiating DAST scan. This prevents scanning of outdated or incorrect deployments.

### Stage 2: DAST Scan with OWASP ZAP

```groovy
stage ('DAST - OWASP ZAP') {
    when {
        branch 'PR*'
    }
    steps {
        script {
            sh '''
                chmod 777 $(pwd)
                docker run -v $(pwd):/zap/wrk/:rw ghcr.io/zaproxy/zaproxy zap-api-scan.py \
                    -t http://192.168.10.202:1234/api-docs \
                    -f openapi \
                    -r zap_html_report.html \
                    -w zap_report.md \
                    -x zap_xml_report.xml \
                    -J zap_json_report.json \
                    -c zap_ignore_rules
            '''
        }
    }
}
```

**Parameters Explained**:
- `-t`: Target URL (OpenAPI/Swagger endpoint)
- `-f`: API format (openapi, soap, graphql)
- `-r`: HTML report output
- `-w`: Markdown report output  
- `-x`: XML report output
- `-J`: JSON report output
- `-c`: Configuration file for ignoring rules

### Post-build Actions

```groovy
post {
    always {
        publishHTML([
            allowMissing: true, 
            alwaysLinkToLastBuild: true, 
            icon: '', 
            keepAll: true, 
            reportDir: './', 
            reportFiles: 'zap_html_report.html', 
            reportName: 'DAST-OWASP-ZAP-HTML-Report', 
            reportTitles: '', 
            useWrapperFileDirectly: true
        ])
    }
}
```

---

## Network Configuration & Port Forwarding

### The Network Challenge

In this setup, Minikube runs as a nested VM inside the Ubuntu VM, creating a complex network topology:

```
┌─────────────────────────────────────────────────────────┐
│                 Windows Host Laptop                     │
│  IP: 192.168.15.5/21                                    │
│  ┌─────────────────────────────────────────────────┐   │
│  │         WSL / Jenkins Machine                   │   │
│  │         IP: 172.29.32.1/20                     │   │
│  └─────────────────────────────────────────────────┘   │
│                        │                                │
│                        ▼                                │
│  ┌─────────────────────────────────────────────────┐   │
│  │         VirtualBox Ubuntu VM                    │   │
│  │         IP: 192.168.10.202/21 (bridged)         │   │
│  │         ┌─────────────────────────────────┐     │   │
│  │         │    Minikube VM (Nested)         │     │   │
│  │         │    IP: 192.168.49.2             │     │   │
│  │         └─────────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Port Forwarding Solution

```bash
# Forward service port to ALL interfaces on Ubuntu VM
kubectl port-forward -n solar-system svc/solar-system --address 0.0.0.0 1234:3000

# Forward ArgoCD pod port
kubectl port-forward -n argocd pod/argocd-server-xxxxx --address 0.0.0.0 5678:8080
```

**Why `--address 0.0.0.0`?** 
- Binds to ALL network interfaces on the Ubuntu VM
- Makes the service accessible via: `127.0.0.1`, `192.168.10.202`, `172.17.0.1`, `192.168.49.1`

**Accessibility Matrix**:

| Source | VM IP Address | Windows Host | WSL/Jenkins |
|--------|---------------|--------------|-------------|
| `127.0.0.1` | ✅ | ❌ | ❌ |
| `192.168.10.202` | ✅ | ✅ | ✅ |
| `172.17.0.1` | ✅ | ❌ | ❌ |
| `192.168.49.1` | ✅ | ❌ | ❌ |

### Testing Connectivity

```bash
# From Ubuntu VM
curl http://127.0.0.1:1234/          # ✅ Works
curl http://192.168.10.202:1234/     # ✅ Works

# From Windows Host
curl http://192.168.10.202:1234/     # ✅ Works

# From WSL/Jenkins
curl http://192.168.10.202:1234/     # ✅ Works
```

---

## ZAP Configuration File

### Generating Configuration File

Reference: [ZAP API Scan Documentation](https://www.zaproxy.org/docs/docker/api-scan/)

```bash
# Generate initial configuration file
docker run -v $(pwd):/zap/wrk/:rw ghcr.io/zaproxy/zaproxy zap-api-scan.py \
    -t http://192.168.10.202:1234/api-docs \
    -f openapi \
    -g zap_ignore_rules
```

### Configuration File Format

```
[Rule ID] [Action] [URL Pattern]
```

**Fields**:
- **Rule ID**: Numeric identifier from ZAP scan results
- **Action**: `IGNORE`, `FAIL`, or `WARN`
- **URL Pattern**: Base URL pattern to apply the rule

**Important**: Columns must be separated by **single tabs**, not spaces.

### Example Configuration

```bash
100001	IGNORE	http://192.168.10.202:1234
10020	IGNORE	http://192.168.10.202:1234
10021	IGNORE	http://192.168.10.202:1234
10037	IGNORE	http://192.168.10.202:1234
10038	IGNORE	http://192.168.10.202:1234
10063	IGNORE	http://192.168.10.202:1234
10098	IGNORE	http://192.168.10.202:1234
90003	IGNORE	http://192.168.10.202:1234
90004	IGNORE	http://192.168.10.202:1234
```

---

## Report Generation

ZAP generates comprehensive reports in multiple formats:

### Available Formats
- **HTML**: Human-readable format for stakeholders
- **Markdown**: Lightweight documentation
- **XML**: Integration with other tools
- **JSON**: Programmatic processing

### Sample Report Structure
```
Total of 23 URLs
PASS: Directory Browsing [0]
PASS: Vulnerable JS Library [10003]
...
WARN-NEW: Unexpected Content-Type was returned [100001] x 9
WARN-NEW: Missing Anti-clickjacking Header [10020] x 1
...
FAIL-NEW: 0  FAIL-INPROG: 0  WARN-NEW: 9  PASS: 107
```

### Exit Codes
- **0**: Scan completed successfully (no failures)
- **2**: Scan completed with warnings/errors
- **Other**: Scan failed to complete

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Ping Not Working Between WSL/Jenkins and Minikube
**Issue**: `ping 192.168.49.2` fails from WSL
**Cause**: Minikube runs as a nested VM with its own network namespace
**Solution**: Use port forwarding instead of direct IP access

#### 2. Cannot Access Application from Jenkins
**Issue**: `curl http://192.168.49.2:30000/api-docs` fails
**Cause**: 192.168.49.2 is only accessible from within Minikube VM
**Solution**: 
```bash
# On Ubuntu VM
kubectl port-forward svc/solar-system --address 0.0.0.0 1234:3000
# Access via 192.168.10.202:1234 from Jenkins
```

#### 3. ZAP Container Cannot Access Application
**Issue**: ZAP scan fails with connection refused
**Cause**: Container networking isolation
**Solution**: 
- Ensure port forwarding is active
- Verify application is running (`kubectl get pods`)
- Check network connectivity from VM

#### 4. Permission Issues with Docker Volume
**Issue**: Cannot write reports to host directory
**Solution**:
```bash
chmod 777 $(pwd)  # Or more restrictive permissions as needed
```

#### 5. Configuration File Not Working
**Issue**: Warnings still appear despite configuration file
**Causes**:
- Tabs vs spaces in config file
- Incorrect URL pattern
- Rule ID mismatch
- File not mounted correctly

**Solution**: 
```bash
# Verify file is mounted
docker run -v $(pwd):/zap/wrk/:rw ghcr.io/zaproxy/zaproxy ls -la /zap/wrk/

# Check config file format
cat -A zap_ignore_rules  # Tabs should show as ^I
```

---

## References

### Official Documentation
- [KodeKloud DevSecOps Notes - DAST Basics](https://notes.kodekloud.com/docs/DevSecOps-Kubernetes-DevOps-Security/DevSecOps-Pipeline/DAST-Basics)
- [GitHub Articles - What is DAST?](https://github.com/resources/articles/what-is-dast)
- [OWASP DevSecOps Guideline - DAST](https://owasp.org/www-project-devsecops-guideline/latest/02b-Dynamic-Application-Security-Testing)

### OWASP ZAP Resources
- [Official Website](https://www.zaproxy.org/)
- [Download & Documentation](https://www.zaproxy.org/download/)
- [Docker Documentation](https://www.zaproxy.org/docs/docker/)
- [API Scan Documentation](https://www.zaproxy.org/docs/docker/api-scan/)
- [GitHub Action - ZAP API Scan](https://github.com/marketplace/actions/zap-api-scan)

### DAST Tools (Open Source & Commercial)
- **Open Source**: OWASP ZAP
- **Commercial**: Acunetix, Burp Suite, HCL AppScan on Cloud

---

## Contributing

Contributions to improve the DAST implementation are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit changes (`git commit -am 'Add improvement'`)
4. Push to branch (`git push origin feature/improvement`)
5. Create a Pull Request

---

## License

This project is for educational purposes as part of DevSecOps learning. Refer to respective tool licenses for production use.

---

**Note**: IP addresses and credentials in this documentation are for demonstration purposes only and should be replaced with your environment-specific values.