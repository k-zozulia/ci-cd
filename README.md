# Lesson 8-9 — CI/CD Pipeline: Jenkins + Argo CD + Terraform + Helm

## Опис проєкту

Повний CI/CD pipeline для Django-застосунку на AWS з використанням:
- **Terraform** — інфраструктура як код (EKS, ECR, VPC, S3)
- **Jenkins** — автоматичне збирання Docker-образу та оновлення Helm chart
- **Kaniko** — збірка Docker-образів всередині Kubernetes
- **Argo CD** — GitOps-деплой застосунку в кластер
- **Helm** — пакетний менеджер для Kubernetes

---

## Схема CI/CD

```
Developer pushes code
        ↓
   Jenkins Pipeline
        ↓
  Kaniko builds image
        ↓
  Push to Amazon ECR
        ↓
  Update values.yaml tag in Git
        ↓
   Argo CD detects change
        ↓
  Auto-sync to EKS cluster
        ↓
  Django app is live 🚀
```

---

## Структура проєкту

```
├── Jenkinsfile              # CI pipeline (build, push, update tag)
├── Dockerfile               # Docker образ Django застосунку
├── manage.py                # Django management script
├── requirements.txt         # Python залежності
├── main.tf                  # Підключення всіх Terraform модулів
├── backend.tf               # S3 backend для Terraform state
├── outputs.tf               # Terraform outputs
│
├── myproject/               # Django проєкт
├── myapp/                   # Django застосунок
│
├── modules/
│   ├── s3-backend/          # S3 + DynamoDB для Terraform state
│   ├── vpc/                 # VPC, підмережі, IGW, NAT Gateway
│   ├── ecr/                 # ECR репозиторій для Docker-образів
│   ├── eks/                 # EKS кластер + Node Group + EBS CSI Driver
│   ├── jenkins/             # Jenkins через Helm
│   │   ├── jenkins.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── values.yaml
│   │   └── outputs.tf
│   └── argo_cd/             # Argo CD через Helm
│       ├── argocd.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── values.yaml
│       ├── outputs.tf
│       └── charts/
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
│
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

---

## Модулі Terraform

### `eks`
EKS кластер версії 1.31 з Node Group (`t3.medium`), IAM ролями, OIDC провайдером та EBS CSI Driver addon.

### `jenkins`
Jenkins через Helm з Kubernetes agent, Kaniko для збірки образів, LoadBalancer сервісом та persistent storage (EBS gp2, 8Gi).

### `argo_cd`
Argo CD через Helm з автоматичною синхронізацією `django-app` з гілки `lesson-8-9`.

### `ecr`
ECR репозиторій з автоматичним скануванням та lifecycle policy.

### `vpc`
VPC (`10.0.0.0/16`) з 3 публічними та 3 приватними підмережами, IGW та NAT Gateway.

---

## Як застосувати Terraform

```bash
# 1. Закоментуй backend.tf
terraform init
terraform apply

# 2. Підключись до кластера
aws eks update-kubeconfig \
  --region eu-central-1 \
  --name lesson-8-9-cluster

# 3. Створи ECR secret для Jenkins
kubectl create secret docker-registry docker-credentials \
  --docker-server=AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region eu-central-1) \
  --namespace=jenkins

# 4. Створи PVC для Jenkins
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 8Gi
EOF

# 5. Патч Argo CD на LoadBalancer
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "LoadBalancer"}}'
```

---

## Як перевірити Jenkins job

```bash
# Отримай URL
kubectl get svc -n jenkins
# Відкрий EXTERNAL-IP:8080
```

Логін: `admin` / `admin123`

Перед першим запуском додай GitHub credentials:
- Manage Jenkins → Credentials → Global → Add Credentials
- Kind: `Secret text`, ID: `github-token`

Запуск: `django-pipeline` → **Build Now**

Pipeline виконує:
1. Клонує репозиторій
2. Збирає образ через Kaniko
3. Пушить в ECR з тегом `BUILD_NUMBER`
4. Оновлює `tag` в `charts/django-app/values.yaml`
5. Пушить зміни в GitHub

---

## Як побачити результат в Argo CD

```bash
# Отримай URL
kubectl get svc -n argocd | grep argocd-server
# Відкрий EXTERNAL-IP в браузері
```

Логін: `admin` / пароль:
```bash
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

Application `django-app` має статус **Synced** після кожного Jenkins build.

---

## Команди для перевірки

```bash
kubectl get pods -A
kubectl get pods -n default
kubectl get svc -n default
kubectl get pods -n jenkins
kubectl get pods -n argocd
kubectl get hpa -n default
kubectl logs -l app=django-app -n default
```

---

## Знищення ресурсів

```bash
helm uninstall django-app -n default
terraform destroy
```
