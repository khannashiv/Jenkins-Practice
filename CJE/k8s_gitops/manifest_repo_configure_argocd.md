# Solar System GitOps with ArgoCD

## 🚀 Demo: Manifest Repository and Configure ArgoCD

This repository demonstrates a GitOps workflow using ArgoCD to manage Kubernetes manifests for a Solar System application, including secure secret management with Bitnami Sealed Secrets.

## 📋 Prerequisites

Before you begin, ensure you have the following tools installed:

- **Docker** - [Installation Guide](https://docs.docker.com/engine/install/)
- **Minikube** - [Installation Guide](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download)
- **kubectl** - [Installation Guide](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- **Helm** - [Installation Guide](https://helm.sh/docs/intro/install/)
- **kubeseal** - [Installation Guide](https://notes.kodekloud.com/docs/Introduction-to-Sealed-Secrets-in-Kubernetes/Sealed-Secrets-Fundamentals/Installation-of-Kubeseal-CLI)

## 🔧 Setup Instructions

### 1. Start Minikube with Docker Driver

```bash
minikube start --driver=docker
```

### 2. Install ArgoCD

Follow the [official ArgoCD installation guide](https://argo-cd.readthedocs.io/en/stable/getting_started/).

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 3. Expose ArgoCD Server as NodePort

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

### 4. Retrieve ArgoCD Admin Password

```bash
# Decode the initial admin password
echo "Rk1ZQnVULUo5OTVHZVhuaA==" | base64 -d
# Output: FMYBuT-J995GeXnh
```

**ArgoCD Login Credentials:**
- Username: `admin`
- Password: `FMYBuT-J995GeXnh`

### 5. Install Sealed Secrets Controller

Add the Bitnami Helm repository and install Sealed Secrets:

```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system
```

## 🔐 Managing Secrets with Sealed Secrets

### Step 1: Create a Kubernetes Secret

Create a secret manifest for MongoDB credentials:

```bash
kubectl -n solar-system create secret generic mongo-db-creds \
  --from-literal=MONGO_URI="mongodb://testUser:testPass@mongodb:27017/solarSystemDB?authSource=admin" \
  --from-literal=MONGO_USERNAME=testUser \
  --from-literal=MONGO_PASSWORD=testPass \
  --save-config \
  --dry-run=client \
  -o yaml > mongo-creds_k8s-secret.yaml
```

### Step 2: Extract the Sealed Secrets Controller Certificate

```bash
# Get the secret name from kube-system
kubectl get secrets -n kube-system

# Extract the TLS certificate
kubectl -n kube-system get secrets sealed-secrets-key<tab-complete> -o json | jq -r '.data."tls.crt"' | base64 -d > sealedSecret.crt
```

### Step 3: Seal the Secret

Encrypt the secret with cluster-wide scope (usable in any namespace):

```bash
kubeseal --cert sealedSecret.crt --scope cluster-wide -o yaml < mongo-creds_k8s-secret.yaml > mongo-creds_k8s-secret-sealed.yaml
```

### Step 4: Verify the Sealed Secret

```bash
cat mongo-creds_k8s-secret-sealed.yaml
```

The output should be a `SealedSecret` custom resource with encrypted data that is safe to store in Git.

### Step 5: Push to Git Repository

Push the sealed secret manifest to your Git repository:

```bash
git add mongo-creds_k8s-secret-sealed.yaml
git commit -m "Add sealed secret for MongoDB credentials"
git push origin main
```

## 📦 Repository Structure

```
solar-system-gitops-argocd-gitea/
├── README.md
├── mongo-creds_k8s-secret-sealed.yaml    # Encrypted sealed secret
└── (other application manifests)
```

## 🎯 Creating ArgoCD Application

1. Access the ArgoCD UI or use the CLI
2. Create a new application named `solar-system`
3. Configure:
   - **Repository URL**: `https://github.com/sidd-harth/solar-system-gitops-argocd-gitea`
   - **Path**: `/` (or specific directory)
   - **Destination**: `https://kubernetes.default.svc`
   - **Namespace**: `solar-system`

## 🔍 Verifying the Setup

```bash
# Check sealed secrets controller
kubectl get pods -n kube-system | grep sealed-secrets

# Check ArgoCD application status
kubectl get applications -n argocd

# Check secrets (should not show raw secrets, only sealed secret)
kubectl get sealedsecrets -n solar-system
```

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Sealed Secrets GitHub Repository](https://github.com/bitnami-labs/sealed-secrets)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [GitOps with ArgoCD - KodeKloud Notes](https://notes.kodekloud.com/docs/GitOps-with-ArgoCD)

## ⚠️ Important Notes

- Never commit raw Kubernetes secrets to Git repositories
- Always seal secrets before storing them in version control
- The sealed secret certificate (`sealedSecret.crt`) should be kept secure
- Consider rotating the sealed secret encryption key periodically

## 📄 License

This project is for demonstration purposes only.