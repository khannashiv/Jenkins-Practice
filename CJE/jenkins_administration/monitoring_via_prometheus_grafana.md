# Jenkins Monitoring with Prometheus & Grafana

This project sets up a complete monitoring stack for Jenkins using **Prometheus** for metrics collection and **Grafana** for visualization.

## 📋 Prerequisites

- Docker and Docker Compose installed
- Jenkins instance running with Prometheus metrics plugin
- Basic understanding of Docker networking

## 🚀 Quick Start

1. **Clone the repository and navigate to the monitoring folder:**
   ```bash
   mkdir jenkins-monitoring && cd jenkins-monitoring
   ```

2. **Create configuration files:**
   ```bash
   touch docker-compose.yml prometheus.yml
   ```

3. **Configure Jenkins:**
   - Install the Prometheus metrics plugin in Jenkins
   - Restart Jenkins after installation
   - Go to: `Manage Jenkins` → `System` → Configure metrics collection
   - Set collecting metrics period to 10 seconds
   - (Optional) Uncheck disk usage monitoring

## ⚙️ Configuration

### 1. **Prometheus Configuration (`prometheus.yml`)**

```yaml
global:
  scrape_interval: 15s # How often to fetch data

scrape_configs:
  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['host.docker.internal:8080']
```

**Note:** Replace `host.docker.internal:8080` with your Jenkins server IP if running on a different machine.

### 2. **Docker Compose Configuration (`docker-compose.yml`)**

```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    ports:
      - '9090:9090'
    restart: always

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - '3000:3000'
    volumes:
      - grafana_data:/var/lib/grafana
    restart: always

volumes:
  prometheus_data:
  grafana_data:
```

## 🏃‍♂️ Running the Stack

1. **Start the monitoring services:**
   ```bash
   docker-compose up -d
   ```

2. **Verify the services are running:**
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000

## 🔧 Configuration Steps

### Verify Prometheus
1. Open http://localhost:9090
2. Go to `Status` → `Targets`
3. Ensure Jenkins is listed as `UP`

### Configure Grafana
1. Open http://localhost:3000
   - Default credentials: `admin` / `admin`
2. Go to `Connections` → `Data Sources` → `Add Data Source`
3. Select `Prometheus`
4. **Important:** Set URL to `http://prometheus:9090` (Docker internal network name)
5. Click `Save & Test`

### Import Jenkins Dashboard
1. In Grafana, go to `Dashboards` → `New` → `Import`
2. Enter dashboard ID: `9964` (Jenkins Performance and Health Overview)
3. Select your Prometheus data source
4. Click `Import`

## 🐛 Troubleshooting Common Issues

### Error 1: DNS Resolution Error
```
Error scraping target: Get "http://host.docker.internal:8080/prometheus": 
dial tcp: lookup host.docker.internal on 127.0.0.11:53: no such host
```
**Solution:** Add `extra_hosts` configuration to Prometheus service in docker-compose.yml as shown above.

### Error 2: Connection Refused
```
Error scraping target: Get "http://localhost:8080/prometheus": 
dial tcp [::1]:8080: connect: connection refused
```
**Solution:** Ensure Jenkins is running and accessible from the Prometheus container. Use the correct IP address/hostname.

### Error 3: Grafana Cannot Connect to Prometheus
```
Post "http://localhost:9090/api/v1/query": dial tcp [::1]:9090: connect: connection refused
```
**Solution:** In Grafana data source configuration, use `http://prometheus:9090` instead of `http://localhost:9090`

## 📊 Jenkins Pipeline for Testing

Create a Jenkins pipeline to generate metrics:

```groovy
node('ubuntu-docker-jdk17-node18') {
  stage('Hello from ubuntu agent..!!') {
    sh 'echo "Using jenkins slave node to run a job"'
  }
}

node {
  stage('Hello from controller agent..!!') {
    sh 'echo "Using controller to run a job"'
  }
}
```

## 🌐 Access URLs

- **Jenkins:** `https://means-atlanta-convertible-explanation.trycloudflare.com`
- **Prometheus:** http://localhost:9090
- **Grafana:** http://localhost:3000
- **Jenkins Metrics Endpoint:** http://localhost:8080/prometheus/

## 📈 Monitoring Dashboard Features

The imported dashboard (ID: 9964) provides:
- Job queue speeds and rates
- Executors availability
- Nodes status
- Jenkins and JVM resource usage
- Jenkins Job Status
- Plugin information
- Build metrics and performance

## 🔍 Sample Prometheus Queries

You can run these queries in Prometheus:
- `jenkins_plugins_active` - Active plugin count
- `jenkins_plugins_withUpdate` - Plugins needing updates
- `jenkins_job_count_value` - Total job count

## 🧹 Cleanup

To stop and remove all containers:
```bash
docker-compose down
```

To remove volumes as well (⚠️ This will delete all data):
```bash
docker-compose down -v
```

## 📚 Resources

- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- [Jenkins Performance Dashboard](https://grafana.com/grafana/dashboards/9964-jenkins-performance-and-health-overview/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**Note:** This setup is configured for local development. For production deployments, consider security configurations, persistent storage, and network security measures.