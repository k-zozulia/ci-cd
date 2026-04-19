# Lesson 5 — Terraform Infrastructure on AWS

## Опис проєкту

Terraform-конфігурація для розгортання базової інфраструктури на AWS, що включає:
- **S3 + DynamoDB** — зберігання та блокування Terraform state
- **VPC** — мережева інфраструктура з публічними та приватними підмережами
- **ECR** — реєстр Docker-образів

---

## Структура директорій

```
lesson-5/
├── main.tf              # Підключення всіх модулів та provider
├── backend.tf           # Налаштування S3 backend для state
├── outputs.tf           # Зведені outputs з усіх модулів
│
└── modules/
    ├── s3-backend/      # S3 bucket + DynamoDB для state locking
    │   ├── s3.tf
    │   ├── dynamodb.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── vpc/             # VPC, підмережі, IGW, NAT, маршрутизація
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── ecr/             # ECR репозиторій для Docker-образів
        ├── ecr.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Модулі

### `s3-backend`
Створює S3-бакет для зберігання Terraform state-файлів та таблицю DynamoDB для блокування.

- S3: версіювання, шифрування AES256, блокування публічного доступу
- DynamoDB: `PAY_PER_REQUEST`, hash key `LockID`

| Змінна       | Опис                          | За замовчуванням   |
|--------------|-------------------------------|--------------------|
| `bucket_name`| Ім'я S3 бакета                | —                  |
| `table_name` | Ім'я таблиці DynamoDB         | `terraform-locks`  |

---

### `vpc`
Створює повноцінну мережеву інфраструктуру:

- VPC з заданим CIDR блоком
- 3 публічні підмережі (з автопризначенням публічних IP)
- 3 приватні підмережі
- Internet Gateway для публічного трафіку
- NAT Gateway + Elastic IP для приватних підмереж
- Route Tables для публічних і приватних підмереж

| Змінна              | Опис                        | За замовчуванням   |
|---------------------|-----------------------------|--------------------|
| `vpc_cidr_block`    | CIDR блок VPC               | `10.0.0.0/16`      |
| `public_subnets`    | Список CIDR публічних підмереж | —               |
| `private_subnets`   | Список CIDR приватних підмереж | —               |
| `availability_zones`| Список AZ                   | —                  |
| `vpc_name`          | Ім'я VPC                    | `main-vpc`         |

---

### `ecr`
Створює ECR-репозиторій для зберігання Docker-образів:

- Автоматичне сканування образів при завантаженні
- Lifecycle policy (видалення старих untagged образів)
- Repository policy для доступу в межах AWS-акаунту

| Змінна        | Опис                             | За замовчуванням |
|---------------|----------------------------------|------------------|
| `ecr_name`    | Ім'я ECR репозиторію             | —                |
| `scan_on_push`| Сканування образів при push      | `true`           |

---

## Попередні вимоги

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- AWS CLI налаштований (`aws configure`)
- IAM permissions: S3, DynamoDB, VPC, ECR

> **Важливо:** Перед використанням `backend.tf` потрібно спочатку створити S3-бакет і DynamoDB вручну або через модуль `s3-backend` без backend-конфігурації.

---

## Команди

### Ініціалізація

```bash
terraform init
```

### Перевірка плану

```bash
terraform plan
```

### Застосування змін

```bash
terraform apply
```

### Знищення ресурсів

```bash
terraform destroy
```

---

## Порядок першого розгортання

1. Закоментуйте вміст `backend.tf` (або видаліть файл тимчасово)
2. Запустіть `terraform init && terraform apply` — створяться S3 і DynamoDB
3. Розкоментуйте `backend.tf`
4. Запустіть `terraform init` — Terraform перенесе state у S3

---
