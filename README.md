# ShipYard

### CI/CD that ships a container to AWS

Push to `main` → build image → push to ECR → Terraform rolls ECS. Idle cost stays near $0 when you destroy after the demo.

![Docker](https://img.shields.io/badge/Containers-Docker-2496ED?logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform&logoColor=white)
![ECS](https://img.shields.io/badge/Compute-ECS%20Fargate-FF9900?logo=amazonecs&logoColor=white)
![ECR](https://img.shields.io/badge/Registry-ECR-FF9900?logo=amazonecr&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

---

**Spec version:** 1.0 — 2026-09-23 (same version as [`TODO.md`](./TODO.md))

**README = design.** [`TODO.md`](./TODO.md) **= build list.** Change a locked decision → bump the version in both files.

**Deploy status:** Application, Dockerfile, Terraform, and GitHub Actions are implemented and pushed. **Live AWS** (ECR/ECS/ALB) exists only after you run a first local bootstrap apply with account credentials, set `AWS_ROLE_ARN`, and let CI apply — or apply locally end-to-end. Until then, CI lint/test runs; push/apply jobs no-op without the secret.

---

## Overview

ShipYard is a small TypeScript HTTP API packaged as a **Docker** image, stored in **ECR**, and run on **ECS Fargate** behind an ALB. **GitHub Actions** builds and pushes the image; **Terraform** defines the infrastructure and updates the service.

It fills the gap left by the other labs: NimbusFlow is serverless (SAM), CSPM is posture checks (Terraform). ShipYard is the container deploy path — image, registry, pipeline, health-checked rollout — without EKS.

| Lab | Shows | Does not show |
| --- | --- | --- |
| **NimbusFlow** | Serverless pipeline, SAM, queues, Step Functions | Containers, CI deploy of an image |
| **CSPM** | Terraform security posture checks | Shipping an app |
| **ShipYard** | Docker → ECR → ECS + GitHub Actions | EKS, multi-service mesh |

---

## Locked scope

- App: one TypeScript/Node HTTP service (`GET /`, `GET /health`)
- Image: multi-stage `Dockerfile`, non-root user
- Registry: Amazon ECR
- Runtime: ECS Fargate behind an Application Load Balancer
- Network: public subnets + public IPs on tasks — **no NAT Gateway** (NAT bills)
- IaC: Terraform only (no console clicks after bootstrap)
- CI/CD: GitHub Actions on push to `main` — lint/test → build → push → deploy
- **Deploy path (locked):** **A)** Terraform apply on every `main` push with `image_tag = github.sha`
- Observability: CloudWatch logs (7-day retention), one alarm on unhealthy hosts → SNS
- Cost: **$1** monthly budget + SNS; **destroy after every demo**
- Out of scope: EKS, RDS, Redis, custom domain, CodePipeline, Helm, ArgoCD, second environment beyond `dev`

---

## Architecture

```
Developer
   │  git push main
   ▼
GitHub Actions
   │  lint + test
   │  docker build (multi-stage)
   │  docker push ──► ECR (tag = git SHA)
   │  terraform apply -var=image_tag=<sha>
   ▼
Application Load Balancer
   │  /health → healthy targets only
   ▼
ECS Fargate service (desired count 1)
   │  task role: CloudWatch logs only
   ▼
CloudWatch Logs + unhealthy-host alarm → SNS
```

**Notes**

1. Multi-stage Docker: TypeScript build → Node alpine runtime, non-root. `/health` is the ALB target.
2. Image tags are **immutable git SHAs**.
3. At `desired_count = 1`, ECS cannot keep an old task during a 100% min-healthy rollout. This stack uses `min 0% / max 200%`. A bad `/health` replace can briefly leave zero healthy hosts (alarm fires). With count ≥ 2 you get a true rolling keep-old-task behavior — out of lab cost scope.
4. Public subnets avoid NAT. Two ECS roles: execution (ECR + logs), task (logs only). GitHub Actions uses **OIDC**.
5. Destroy after every demo window.

---

## Default cost

| While demoing | After `terraform destroy` |
| --- | --- |
| ALB + Fargate (256/512) + ECR storage + logs | Near **$0** |

Never leave the stack up overnight. Region: `ca-central-1`.

---

## Getting started

### App locally (no AWS)

```bash
cd app
npm ci
npm run lint
npm test
npm run dev
# curl -s localhost:8080/health
# curl -s localhost:8080/
```

### Image locally

```bash
# From repo root — Docker Desktop daemon must be running (`docker info`)
docker build -t shipyard:local .
docker run --rm -p 8080:8080 shipyard:local
curl -s localhost:8080/health
```

### AWS bootstrap (once per account)

Chicken-and-egg: CI needs the OIDC role that Terraform creates, and ECS needs an image in ECR.

```bash
# 0) Cost guard: set alert_email in tfvars ($1 budget + SNS)
cd infra
cp terraform.tfvars.example terraform.tfvars
# edit alert_email, github_org/repo if needed

# 1) Create ECR (+ optional OIDC/IAM) first
terraform init
terraform apply -target=aws_ecr_repository.app -target=aws_ecr_lifecycle_policy.app

# 2) Build + push a bootstrap image (local AWS creds + docker)
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGION=ca-central-1
REPO=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/shipyard")
TAG=$(git rev-parse HEAD)
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT.dkr.ecr.$REGION.amazonaws.com
docker build -t "$REPO:$TAG" ..
docker push "$REPO:$TAG"

# 3) Full apply with that tag
terraform apply -var="image_tag=$TAG"

# 4) Wire CI
# GitHub → Settings → Secrets: AWS_ROLE_ARN = terraform output -raw github_actions_role_arn
# Confirm SNS email if alert_email was set

# 5) Demo
curl -s "$(terraform output -raw alb_url)/health"
curl -s "$(terraform output -raw alb_url)/"

# 6) Tear down when done
terraform destroy
```

After bootstrap, every push to `main` runs lint/test → build/push SHA tag → `terraform apply` with that tag. PRs run lint/test only (and optional plan if `AWS_ROLE_ARN` is set); **PRs never apply**.

### Required GitHub configuration

| Name | Type | Purpose |
| --- | --- | --- |
| `AWS_ROLE_ARN` | Secret | OIDC role ARN from `github_actions_role_arn` output |
| (optional) remote state | `infra/versions.tf` backend | Uncomment S3 backend for durable CI state |

Without `AWS_ROLE_ARN`, CI still runs lint/test; image push and Terraform are skipped.

---

## Project structure

```text
ShipYard/
├── README.md
├── TODO.md
├── LICENSE
├── .gitignore
├── Dockerfile
├── .dockerignore
├── app/
│   ├── package.json
│   ├── src/
│   │   ├── index.ts
│   │   ├── server.ts
│   │   └── health.ts
│   └── test/
├── infra/
│   ├── versions.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── network.tf
│   ├── ecr.tf
│   ├── alb.tf
│   ├── ecs.tf
│   ├── iam.tf
│   ├── oidc.tf
│   ├── observability.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
└── .github/workflows/
    └── deploy.yml
```

---

## Resume line (when live demo + destroy works)

**ShipYard — CI/CD container deploy to ECS Fargate** · 2026  
Docker, ECR, ECS Fargate, ALB, Terraform, GitHub Actions, CloudWatch  

- Built a multi-stage Docker image and pushed it to ECR from GitHub Actions on every `main` push.  
- Defined ECS Fargate + ALB in Terraform with health checks; destroy after each demo.  
- Scoped execution/task/OIDC roles; CloudWatch logs + a $1 budget.

Add to the Cloud / DevOps resume when you have completed a live apply → hit ALB → destroy cycle — not the Security Analyst resume.

---

## License

MIT. See [LICENSE](./LICENSE).
