# ✅ ShipYard — TODO

**Spec version:** 1.0 — 2026-09-23 (same version as [`README.md`](./README.md))

This checklist **is** the whole project. README = design; this file = build list. If you change a locked decision, bump the version in **both** files.

**Locked scope:**

- One TypeScript API: `GET /`, `GET /health`
- Multi-stage Docker → ECR → ECS Fargate + ALB
- Public subnets / public task IPs — **no NAT Gateway**
- Terraform + GitHub Actions (OIDC preferred)
- CloudWatch logs 7 days + one alarm
- $1 budget; destroy after every demo
- No EKS, RDS, custom domain, CodePipeline, Helm, ArgoCD, second env

---

## 💰 Cost guard (do this first)

- [x] Create a **$1** AWS Budget + email/SNS alert in Terraform (`ca-central-1`) — **activate on apply** with `alert_email` in tfvars
- [x] Plan to `terraform destroy` after each demo window (documented in README)
- [x] Confirm you will not leave ALB + Fargate up overnight (documented)

---

## 🏗️ Project setup

- [x] Repo layout: `app/`, `infra/`, `Dockerfile`, `.github/workflows/`
- [x] `.gitignore` (node_modules, dist, `.terraform/`, `*.tfstate*`, `.env`)
- [x] MIT `LICENSE`
- [x] `app/package.json` — TypeScript, test runner, lint
- [x] ESLint + Prettier (match NimbusFlow)

---

## 🌐 Application

- [x] `GET /` — short JSON (`{ "service": "shipyard", "ok": true }`)
- [x] `GET /health` — `200` + `{ "status": "ok" }` (ALB/ECS target)
- [x] Listen on `PORT` env (default `8080`)
- [x] Unit test for `/health` (no AWS required)
- [x] Structured log line on startup (service name + port)

---

## 🐳 Container

- [x] Multi-stage `Dockerfile` (build → runtime)
- [x] Runtime: Node alpine, **non-root** user
- [x] `EXPOSE 8080` + `CMD` that starts the compiled app
- [x] `.dockerignore` (node_modules, .git, infra state)
- [x] Local verify: `docker build` + `docker run` + `curl /health`

---

## 📦 Registry (ECR)

- [x] Terraform: ECR repository (scan on push)
- [x] Image tag strategy: git SHA (immutable) — documented in README
- [x] Lifecycle policy: keep last N images

---

## ☁️ Runtime (ECS + ALB)

- [x] Terraform: VPC + **public** subnets only (no NAT)
- [x] Security groups: ALB 80 from internet; tasks only from ALB SG
- [x] ALB + target group, health check path `/health`
- [x] ECS cluster + Fargate service, desired count **1**
- [x] Task definition: CPU/memory small, log driver `awslogs`
- [x] Deploy: new image tag → new task revision via Terraform apply (path A)
- [x] Documented: at count=1, min healthy 0% — bad rollout may drop to zero hosts (alarm); not a dual-task drain

---

## 🔑 IAM

- [x] ECS **execution** role: ECR pull + logs for this log group
- [x] ECS **task** role: logs only
- [x] GitHub Actions role via **OIDC** (no long-lived access keys in secrets)
- [x] OIDC role: push to this ECR repo + terraform plan/apply for this stack
- [x] No `Resource = "*"` on write actions unless AWS forces it — commented in `iam.tf` / `oidc.tf`

---

## 🔬 Observability

- [x] Log group, **7-day** retention
- [x] One alarm: unhealthy hosts > 0 → SNS
- [ ] Confirm SNS subscription once — **after first apply** with `alert_email`

---

## 🔄 CI/CD (GitHub Actions)

- [x] Workflow on push to `main` (and PR: lint/test only)
- [x] Job: `npm ci` → lint → test
- [x] Job: build + push image to ECR tagged with `github.sha` (skipped without `AWS_ROLE_ARN`)
- [x] Job: `terraform plan` / `apply` with new image tag (skipped without `AWS_ROLE_ARN`)
- [x] Document required GitHub secrets/vars (role ARN, region, state bucket if any)
- [x] PR check must **not** apply to AWS

**Deploy path lock (choose one when you implement — check the winner):**

- [x] A) Terraform apply on every main push (image tag variable)
- [ ] B) Terraform for infra once; Actions only pushes image + forces ECS deployment

---

## 🧪 Manual demo script

- [ ] Apply stack → hit ALB URL `/` and `/health` — **AWS-only** (needs creds + bootstrap)
- [ ] Push a trivial change → watch Actions → confirm new task — **AWS-only**
- [ ] Break `/health` on purpose in a branch — confirm behavior at count=1 (documented)
- [ ] `terraform destroy` → confirm ALB/ECS gone — **AWS-only**
- [ ] Screenshot or short notes for the demo (optional, not in git if they show account IDs)

---

## 📄 Documentation

- [x] README — design + honest deploy status
- [x] TODO — this file
- [x] Fill “Getting started” commands (local + bootstrap + destroy)
- [ ] Add resume bullets to Cloud Engineer resume **only after** demo + destroy works
- [x] Link from `Projects/5)DevOps/README.md` (status updated to code + CI ready)

---

## Out of scope (do not start)

- EKS / Kubernetes manifests
- RDS, Redis, multi-service mesh
- Custom domain / ACM (unless free and destroyable same day)
- Second environment (`prod`) until `dev` destroy cycle is muscle memory
- CodePipeline / CodeBuild (Actions is the CI)

---

*Last updated: 2026-11-08*
