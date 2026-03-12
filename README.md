# fullstack-cicd-pipeline — COMET Orders API

Node.js/Express API containerized with Docker and deployed to AWS ECS Fargate via automated GitHub Actions CI/CD pipeline.

## Pipeline Architecture

```
Developer pushes code
        │
        ▼
┌───────────────────────────────────────────────────────┐
│                  GitHub Actions                        │
│                                                        │
│  Job 1: test                                           │
│  └── npm ci → Jest tests (fail = stop here)           │
│                                                        │
│  Job 2: build-push                                     │
│  └── Docker build                                     │
│      → Trivy scan (CRITICAL/HIGH = fail)              │
│      → OIDC → ECR push (tagged with commit SHA)       │
│                                                        │
│  Job 3: deploy-staging     Job 4: deploy-production   │
│  (dev branch only)         (main branch only)         │
│  └── ECS staging update    └── ⚠️ Manual approval    │
│      (no approval)             → ECS prod update      │
│                                → AI summary artifact   │
└───────────────────────────────────────────────────────┘
        │                           │
        ▼                           ▼
┌──────────────┐           ┌──────────────────┐
│  ALB :80     │           │  ALB :8080       │
│  (staging)   │           │  (production)    │
└──────┬───────┘           └────────┬─────────┘
       │                            │
       ▼                            ▼
┌──────────────────────────────────────────────┐
│              ECS Fargate Cluster             │
│                                              │
│  ┌─────────────────┐  ┌──────────────────┐  │
│  │ Staging Service │  │ Production       │  │
│  │ (dev branch)    │  │ Service          │  │
│  │ 256 CPU/512 MB  │  │ (main branch)    │  │
│  └────────┬────────┘  └────────┬─────────┘  │
└───────────┼────────────────────┼────────────┘
            │                    │
            ▼                    ▼
┌───────────────────────────────────────────────┐
│              Private Subnets (VPC)            │
│         (referenced from P1 remote state)     │
└───────────────────────────────────────────────┘
            │
            ▼
┌───────────────────┐     ┌────────────────────┐
│  ECR Repository   │     │  CloudWatch Logs   │
│  comet-orders-api │     │  /ecs/fullstack-.. │
└───────────────────┘     └────────────────────┘
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /health | Health check |
| GET | /orders | Get all orders |
| POST | /orders | Create an order |
| PUT | /orders/:id | Update an order |
| DELETE | /orders/:id | Delete an order |

**Order schema:**
```json
{
  "supplier": "Acme Corp",
  "amount": 5000,
  "status": "pending"
}
```

## Branching Strategy

| Branch | Deploys to | Approval required |
|--------|------------|-------------------|
| `dev` | Staging (port 80) | No |
| `main` | Production (port 8080) | Yes — manual approval |

## Rollback Procedure

Target: complete rollback in under 10 minutes.

### Step 1 — Find previous task definition revision
```bash
aws ecs describe-task-definition \
  --task-definition fullstack-cicd-pipeline-prod \
  --query "taskDefinition.revision"
```

### Step 2 — Roll back to previous revision
```bash
aws ecs update-service \
  --cluster fullstack-cicd-pipeline-dev \
  --service fullstack-cicd-pipeline-prod \
  --task-definition fullstack-cicd-pipeline-prod:<PREVIOUS_REVISION>
```

### Step 3 — Verify rollback
```bash
aws ecs describe-services \
  --cluster fullstack-cicd-pipeline-dev \
  --services fullstack-cicd-pipeline-prod \
  --query "services[0].deployments"
```

Watch for `runningCount` to return to 1 on the previous revision. Expected time: 2-5 minutes.

## Infrastructure

All infrastructure is managed via Terraform.

```
terraform/environments/dev/
├── main.tf       — ECR repo + GitHub Actions IAM role
├── ecs.tf        — ECS cluster, ALB, services (staging + prod)
├── variables.tf  — Input variables
├── outputs.tf    — ALB URLs, ECS names
└── terraform.tfvars
```

State stored in S3: `vziraka-terraform-state/fullstack-cicd-pipeline/dev/terraform.tfstate`

## Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `ECR_ROLE_ARN` | IAM role for GitHub Actions to push/pull ECR + update ECS |
| `AWS_ACCOUNT_ID` | AWS account ID (817952731382) |
| `ANTHROPIC_API_KEY` | For AI deployment summary generation |

## Security

- Zero hardcoded AWS credentials — OIDC only
- Docker image scanned by Trivy on every build
- Non-root user in container (`appuser`)
- ECR image tags are immutable
- ECS tasks run in private subnets — no direct internet access
- npm removed from production image to reduce attack surface
