# 📝 Text Analyzer App

A simple web-based text analyzer built using **Python (Flask)**. This application allows users to analyze textual input for word counts, character frequencies, and more.

---

## 🚀 Features

- Analyze text for word and character counts.
- View character frequency statistics.
- Simple and user-friendly web interface.
- Built with Flask for lightweight web development.
- Includes CI pipeline configuration using Jenkins.
- Includes CD part deployed using ArgoCD as GitOps tool .
- We are using Kubernetes as a target platform for deploying our application in the form of pods .

---

## 📂 Project Structure

```plaintext
text-analyzer-app/
├── app/
│   ├── __init__.py                 # Initializes the Flask app and loads configuration
│   ├── routes.py                   # Defines the web routes (URL endpoints) and logic
│   ├── analyzer.py                 # Contains core text analysis logic
│   └── templates/
│       └── index.html              # HTML template rendered by Flask (user interface)
│
├── Dockerfile                      # Instructions to build a Docker image for the app
├── requirements.txt                # Python dependencies for the app
├── wsgi.py                         # Entry point for running the app in production (e.g., with Gunicorn)
├── Jenkinsfile                     # Jenkins pipeline stages for CI implementation
├── .dockerignore                   # Files/folders to exclude from Docker build context
├── .gitattributes                  # Git attributes configuration (e.g., end-of-line handling)
├── implementation.md               # End-to-end implementation details of the project
└── README.md                       # Project overview and documentation
```

---

## 🛠️ Technologies Used

- **Programming Language**: Python (Flask Framework)
- **Frontend**: HTML
- **Git**: SCM / VCS
- **Containerization**: Docker
- **CI Tool**: Jenkins (Pipeline defined in `Jenkinsfile`)
- **CD/GitOps Tool**: ArgoCD
- **Target Platform**: Kubernetes (Deployed via minikube)

---

## 📦 Setup Instructions

### Prerequisites and required packages 

- sudo apt update && sudo apt upgrade -y
- sudo apt install python3-pip python3-venv git -y
- sudo apt  install docker.io -y

#### Steps to run application locally onto your server in my case I'm using EC2 Server .

1. **Clone the Repository**
   ```bash
   git clone https://github.com/khannashiv/Jenkins-Practice.git
   cd Jenkins-Practice/Project-3/text-analyzer-app
   ```

2. **Setup a Virtual Environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # For Windows: venv\Scripts\activate
   ```

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the Application**
   ```bash
   gunicorn --bind 0.0.0.0:8000 wsgi:app
   ```
   The app will be available on the web-browser via `http://<Public-IP-of-EC2-instance>:8000`

---

#### 🐳 Docker Setup : Here again we are trying to deploy same application using docker as a containerization paltform.

1. **Build the Docker Image**
   ```bash
   docker build -t text-analyzer-app:v1 .
   ```

2. **Run the Docker Container**
   ```bash
   docker run -d -p 8000:8000 --name text-analyzer text-analyzer:v1
   ```
    The app will be available on the web-browser via `http://<Public-IP-of-EC2-instance>:8000`

---

## 📄 Documentation contains entire CICD deployment where target platform for deploying an applicaiton is Kubernetes.

For detailed implementation information, refer to the [Implementation Guide](./implementation.md).

---
