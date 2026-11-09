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
- Observability: CloudWatch logs (7-day retention), one alarm on unhealthy host / 5xx
- Cost: **$1** monthly budget + email; **destroy after every demo**
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
   │  docker push ──► ECR
   │  terraform apply (image tag)
   ▼
Application Load Balancer
   │  /health → healthy targets only
   ▼
ECS Fargate service (desired count 1)
   │  task role: CloudWatch logs only (no wildcards)
   ▼
CloudWatch Logs + alarm → SNS email (optional)
```

**Flow**

1. App stays small so the lab stays on the pipeline: multi-stage Docker (TypeScript build → Node alpine runtime, non-root). `/health` is the ALB/ECS target so an unhealthy container does not get traffic.
2. On `main`, Actions runs tests, builds an image tagged with the git SHA, pushes to ECR, then Terraform updates the ECS task definition and forces a new deployment. If the new task fails health checks, ECS keeps the previous task when desired count allows a rolling replace.
3. Two ECS roles: **execution** pulls from ECR and writes logs; **task** only what the app needs (logs). GitHub Actions uses **OIDC** to push to one ECR repo and run Terraform — no long-lived AWS keys in the repo.
4. Public subnets avoid a NAT Gateway on a portfolio lab. A production setup would use private tasks with NAT or VPC endpoints.
5. This is a destroyable lab, not a production account. Private networking, dual-AZ sizing, and a real staging env stay out of scope until the destroy cycle is solid.

---

## Default cost

| While demoing | After `terraform destroy` |
| --- | --- |
| ALB + Fargate (small) + ECR storage + logs | Near **$0** |

Never leave the stack up overnight. Region: `ca-central-1`.

---

## IAM (target design)

| Principal | Allowed to |
| --- | --- |
| ECS task execution role | `ecr:GetAuthorizationToken`, pull from this repo, write to this log group |
| ECS task role | Create log streams in this log group only |
| GitHub Actions (OIDC) | Push to this ECR repo; plan/apply this Terraform state |

No `*:*` on writes. No access keys in GitHub secrets if OIDC is wired.

---

## Getting started (when TODO is done)

```bash
# 0) Cost guard first
# Create a $1 budget + email in the account

# 1) App locally
cd app
npm ci
npm test
npm run dev

# 2) Image
docker build -t shipyard:local .
docker run --rm -p 8080:8080 shipyard:local
curl -s localhost:8080/health

# 3) Infra
cd ../infra
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply

# 4) Demo window ends
terraform destroy
```

CI: push to `main` after the first apply; Actions owns image + deploy.

---

## Project structure (target)

```text
ShipYard/
├── README.md
├── TODO.md
├── LICENSE
├── .gitignore
├── app/
│   ├── package.json
│   ├── src/
│   │   ├── index.ts
│   │   └── health.ts
│   └── test/
├── Dockerfile
├── infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
└── .github/workflows/
    └── deploy.yml
```

---

## Resume line (when TODO is green)

**ShipYard — CI/CD container deploy to ECS Fargate** · 2026  
Docker, ECR, ECS Fargate, ALB, Terraform, GitHub Actions, CloudWatch  

- Built a multi-stage Docker image and pushed it to ECR from GitHub Actions on every `main` push.  
- Defined ECS Fargate + ALB in Terraform with health checks so a failed rollout keeps the previous task.  
- Scoped execution/task/OIDC roles; CloudWatch logs + a $1 budget; destroy after each demo.

Add to the Cloud / DevOps resume when the checklist is done — not the Security Analyst resume.

---

## License

MIT. See [LICENSE](./LICENSE).
