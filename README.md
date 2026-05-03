# Final Project — DevOps CI/CD Platform on AWS

A complete production-grade CI/CD platform deployed on AWS using Terraform, Kubernetes, Helm, Jenkins, Argo CD, and Prometheus/Grafana.

---

## Architecture overview

```
Developer pushes code
        ↓
   Jenkins Pipeline
        ↓
  Kaniko builds Docker image
        ↓
  Push to Amazon ECR
        ↓
  Update image tag in Git (values.yaml)
        ↓
   Argo CD detects change
        ↓
  Auto-sync to EKS cluster
        ↓
  Django app is live
        ↓
  Prometheus + Grafana monitor everything
```

---

## Infrastructure components

| Component | Description |
|-----------|-------------|
| VPC | Isolated network with public and private subnets across 3 AZs |
| EKS | Managed Kubernetes cluster (v1.31) with auto-scaling node group |
| ECR | Private Docker registry for application images |
| RDS | PostgreSQL 15.4 database in private subnets |
| Jenkins | CI server running inside Kubernetes via Helm |
| Argo CD | GitOps continuous delivery tool |
| Prometheus | Metrics collection for the entire cluster |
| Grafana | Dashboards and visualization for Prometheus metrics |
| S3 + DynamoDB | Terraform remote state storage with locking |

---

## Project structure

```
ci-cd/
├── main.tf               # Root module — connects all modules
├── backend.tf            # S3 remote state backend
├── outputs.tf            # Root-level outputs
├── .gitignore
│
├── modules/
│   ├── s3-backend/       # S3 bucket + DynamoDB for Terraform state
│   ├── vpc/              # VPC, subnets, IGW, NAT Gateway, route tables
│   ├── ecr/              # ECR repository with lifecycle policy
│   ├── eks/              # EKS cluster, node group, EBS CSI driver
│   ├── rds/              # RDS / Aurora database (see modules/rds/README.md)
│   ├── jenkins/          # Jenkins via Helm
│   ├── argo_cd/          # Argo CD via Helm + app definitions
│   └── monitoring/       # Prometheus + Grafana via kube-prometheus-stack
│
├── charts/
│   └── django-app/       # Helm chart for the Django application
│
└── Django/
    ├── Dockerfile
    ├── Jenkinsfile
    ├── docker-compose.yaml
    ├── nginx.conf
    └── app/              # Django source code
        ├── manage.py
        ├── requirements.txt
        ├── myproject/
        └── myapp/
```

---

## How to deploy

### Prerequisites

- AWS CLI configured with sufficient permissions
- Terraform >= 1.0
- kubectl
- helm

### Step 1 — Bootstrap the backend

Comment out `backend.tf`, then run:

```bash
terraform init
terraform apply -target=module.s3_backend
```

Uncomment `backend.tf` and migrate state:

```bash
terraform init -migrate-state
```

### Step 2 — Deploy all infrastructure

```bash
terraform apply
```

This creates VPC, EKS, ECR, RDS, Jenkins, Argo CD, and monitoring in one run. EKS takes ~15 minutes.

### Step 3 — Connect to the cluster

```bash
aws eks update-kubeconfig \
  --region eu-central-1 \
  --name final-project-cluster
```

### Step 4 — Verify all components

```bash
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
kubectl get all -n default
```

### Step 5 — Access the services

**Jenkins:**
```bash
kubectl get svc -n jenkins
# Open EXTERNAL-IP:8080
# Login: admin / admin123
```

**Argo CD:**
```bash
kubectl get svc -n argocd
# Open EXTERNAL-IP in browser
# Login: admin / initial password:
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

**Grafana:**
```bash
kubectl get svc -n monitoring
# Open EXTERNAL-IP:80 in browser
# Login: admin / admin123
```

---

## CI/CD flow

1. Developer pushes code to `final-project` branch
2. Jenkins builds Docker image using Kaniko (no Docker daemon needed)
3. Image is pushed to ECR with tag = `BUILD_NUMBER`
4. Jenkins updates `charts/django-app/values.yaml` with the new tag
5. Argo CD detects the Git change and syncs the deployment to EKS
6. New pods roll out automatically

---

## Monitoring

Prometheus scrapes metrics from all namespaces. Grafana includes pre-built dashboards for:
- Kubernetes cluster health
- Node CPU / memory / disk usage
- Pod and deployment status
- HPA scaling events

Access Grafana via the LoadBalancer service in the `monitoring` namespace.

---

## Autoscaling

The Django application uses a `HorizontalPodAutoscaler` configured to scale between 2 and 6 replicas when CPU utilization exceeds 70%.

---

## Teardown

```bash
helm uninstall django-app -n default
terraform destroy
```

> ⚠️ Always run `terraform destroy` after testing to avoid unexpected AWS charges. Note that destroying also removes the S3 bucket and DynamoDB table used for state — follow Step 1 again on next deployment.
