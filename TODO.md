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

- [ ] Create a **$1** AWS Budget + email alert (`ca-central-1` or your account default)
- [ ] Plan to `terraform destroy` after each demo window
- [ ] Confirm you will not leave ALB + Fargate up overnight

---

## 🏗️ Project setup

- [ ] Repo layout: `app/`, `infra/`, `Dockerfile`, `.github/workflows/`
- [ ] `.gitignore` (node_modules, dist, `.terraform/`, `*.tfstate*`, `.env`)
- [x] MIT `LICENSE`
- [ ] `app/package.json` — TypeScript, test runner, lint
- [ ] ESLint + Prettier (match NimbusFlow if easy)

---

## 🌐 Application

- [ ] `GET /` — short JSON (`{ "service": "shipyard", "ok": true }`)
- [ ] `GET /health` — `200` + `{ "status": "ok" }` (ALB/ECS target)
- [ ] Listen on `PORT` env (default `8080`)
- [ ] Unit test for `/health` (no AWS required)
- [ ] Structured log line on startup (service name + port)

---

## 🐳 Container

- [ ] Multi-stage `Dockerfile` (build → runtime)
- [ ] Runtime: Node alpine (or distroless), **non-root** user
- [ ] `EXPOSE 8080` + `CMD` that starts the compiled app
- [ ] `.dockerignore` (node_modules, .git, infra state)
- [ ] Local verify: `docker build` + `docker run` + `curl /health`

---

## 📦 Registry (ECR)

- [ ] Terraform: ECR repository (scan on push optional, keep cheap)
- [ ] Image tag strategy: git SHA (immutable) — document in README if you tweak
- [ ] Lifecycle policy: keep last N images so ECR storage doesn’t grow forever

---

## ☁️ Runtime (ECS + ALB)

- [ ] Terraform: VPC or default VPC + **public** subnets only (no NAT)
- [ ] Security groups: ALB 80 from internet; tasks only from ALB SG
- [ ] ALB + target group, health check path `/health`
- [ ] ECS cluster + Fargate service, desired count **1**
- [ ] Task definition: CPU/memory small, log driver `awslogs`
- [ ] Deploy: new image tag → new task revision → rolling replace
- [ ] Confirm failed health check does **not** drain all healthy tasks

---

## 🔑 IAM

- [ ] ECS **execution** role: ECR pull + logs for this log group
- [ ] ECS **task** role: logs only (tighten if app needs nothing else)
- [ ] GitHub Actions role via **OIDC** (no long-lived access keys in secrets)
- [ ] OIDC role: push to this ECR repo + terraform plan/apply for this stack only
- [ ] No `Resource = "*"` on write actions unless AWS forces it — comment why

---

## 🔬 Observability

- [ ] Log group, **7-day** retention
- [ ] One alarm: unhealthy hosts > 0 **or** ALB 5xx spike → SNS email
- [ ] Confirm SNS subscription once

---

## 🔄 CI/CD (GitHub Actions)

- [ ] Workflow on push to `main` (and PR: lint/test only)
- [ ] Job: `npm ci` → lint → test
- [ ] Job: build + push image to ECR tagged with `github.sha`
- [ ] Job: `terraform plan` / `apply` with new image tag (or `aws ecs update-service --force-new-deployment` after first bootstrap — pick one and lock it here)
- [ ] Document required GitHub secrets/vars (role ARN, region, state bucket if any)
- [ ] PR check must **not** apply to AWS

**Deploy path lock (choose one when you implement — check the winner):**

- [ ] A) Terraform apply on every main push (image tag variable)
- [ ] B) Terraform for infra once; Actions only pushes image + forces ECS deployment

---

## 🧪 Manual demo script

- [ ] Apply stack → hit ALB URL `/` and `/health`
- [ ] Push a trivial change → watch Actions → confirm new task
- [ ] Break `/health` on purpose in a branch — confirm bad rollout doesn’t take all traffic (or document what Fargate actually does at count=1)
- [ ] `terraform destroy` → confirm ALB/ECS gone
- [ ] Screenshot or short notes for the demo (optional, not in git if they show account IDs)

---

## 📄 Documentation

- [x] README — design
- [x] TODO — this file
- [ ] Fill “Getting started” commands after first successful apply
- [ ] Add resume bullets to Cloud Engineer resume **only after** demo + destroy works
- [ ] Link from `Personal/Projects/5)DevOps/README.md` and Cloud labs index

---

## Out of scope (do not start)

- EKS / Kubernetes manifests
- RDS, Redis, multi-service mesh
- Custom domain / ACM (unless free and destroyable same day)
- Second environment (`prod`) until `dev` destroy cycle is muscle memory
- CodePipeline / CodeBuild (Actions is the CI)

---

*Last updated: 2026-09-23*
