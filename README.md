# Lesson 7 — Kubernetes on AWS (EKS) + Helm

## Опис проєкту

Розгортання Django-застосунку в кластері Kubernetes на AWS з використанням:
- **EKS** — керований Kubernetes кластер
- **ECR** — реєстр Docker-образів
- **VPC** — мережева інфраструктура
- **S3 + DynamoDB** — зберігання Terraform state
- **Helm** — деплой застосунку в кластер

---

## Структура проєкту

```
├── main.tf                  # Підключення модулів
├── backend.tf               # S3 backend для state
├── outputs.tf               # Outputs
├── Dockerfile               # Docker образ Django застосунку
├── manage.py                # Django management script
├── requirements.txt         # Python залежності
│
├── myproject/               # Django проєкт
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
│
├── myapp/                   # Django застосунок
│   ├── __init__.py
│   ├── admin.py
│   ├── apps.py
│   ├── models.py
│   ├── views.py
│   ├── urls.py
│   ├── tests.py
│   └── migrations/
│
├── modules/
│   ├── s3-backend/          # S3 + DynamoDB для Terraform state
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpc/                 # VPC, підмережі, IGW, NAT
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecr/                 # ECR репозиторій
│   │   ├── ecr.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── eks/                 # EKS кластер + Node Group
│       ├── eks.tf
│       ├── variables.tf
│       └── outputs.tf
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

## Модулі

### `eks`
Створює EKS кластер та Node Group:
- IAM ролі для кластера та нод
- EKS кластер версії 1.30
- Node Group з `t3.medium` інстансами
- Автоматичне масштабування від 1 до 3 нод

### `ecr`
Репозиторій для Django Docker-образу з автоматичним скануванням.

### `vpc`
VPC з 3 публічними та 3 приватними підмережами, IGW, NAT Gateway.

### `s3-backend`
S3 бакет + DynamoDB для зберігання та блокування Terraform state.

---

## Helm Chart

### Компоненти
- **Deployment** — Django застосунок з образом з ECR, змінні через ConfigMap
- **Service** — LoadBalancer для зовнішнього доступу
- **HPA** — автомасштабування від 2 до 6 подів при CPU > 70%
- **ConfigMap** — змінні середовища Django

---

## Інструкція з розгортання

### 1. Передумови
```bash
aws configure
terraform --version
helm version
kubectl version
```

### 2. Розгорни інфраструктуру
```bash
# Закоментуй backend.tf
terraform init
terraform apply
```

### 3. Підключись до кластера
```bash
aws eks update-kubeconfig \
  --region eu-central-1 \
  --name lesson-7-cluster

kubectl get nodes
```

### 4. Збери і запуш Docker образ
```bash
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin \
  419772658013.dkr.ecr.eu-central-1.amazonaws.com

docker buildx build --platform linux/amd64 \
  -t 419772658013.dkr.ecr.eu-central-1.amazonaws.com/lesson-7-ecr:latest \
  --push .
```

### 5. Деплой через Helm
```bash
helm install django-app ./charts/django-app
kubectl get pods
kubectl get svc
```

### 6. Знищення ресурсів
```bash
helm uninstall django-app
terraform destroy
```

---

## Команди для перевірки

```bash
# Статус подів
kubectl get pods

# Зовнішній IP
kubectl get svc

# Логи поду
kubectl logs -l app=django-app

# HPA статус
kubectl get hpa
```