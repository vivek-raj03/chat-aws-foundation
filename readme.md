# chat-aws-foundation

Terraform repository for the foundational AWS networking layer of a production-grade chat application. This repo builds the VPC and all core networking required before any compute (EKS), data (RDS/ElastiCache), or application layer is deployed.

## Purpose

This repo is scoped strictly to **networking infrastructure**. It does not create EKS clusters, databases, Helm releases, or application resources — those are handled in separate repos that consume this repo's outputs. Following a module-based Terraform architecture: a reusable module (`modules/vpc`) and environment-specific root modules (`env/prod`, `env/dev`) that call it with real values.

## What this repo creates

### Networking core
- VPC with a primary CIDR block
- Secondary CIDR block associated with the VPC, dedicated to EKS pod IP addresses (VPC CNI custom networking)

### Subnets (×3, one per Availability Zone)
- Public subnets — for NAT Gateways, load balancers
- Private app subnets — for EKS worker nodes
- Private data subnets — for RDS, ElastiCache
- Pod subnets — on the secondary CIDR, for EKS pod IPs

### Internet access
- 1 Internet Gateway
- 3 Elastic IPs (one per AZ)
- 3 NAT Gateways (one per AZ, for full HA — no shared single point of failure)

### Route tables
- 1 public route table (routes `0.0.0.0/0` → Internet Gateway), shared across public subnets
- 3 private-app route tables (one per AZ, each routing `0.0.0.0/0` → its own AZ's NAT Gateway)
- 3 private-data route tables (one per AZ, same per-AZ NAT routing)
- Pod subnets share their AZ's private-app route table
- All associated route table ↔ subnet associations

### VPC Endpoints
- S3 Gateway endpoint
- DynamoDB Gateway endpoint (optional, controlled by `enable_dynamodb_endpoint`)
- Interface endpoints: ECR API, ECR DKR, STS, Secrets Manager, CloudWatch Logs
- Dedicated security group for interface endpoints

### Observability
- VPC Flow Logs → CloudWatch Logs
- Supporting IAM role and policy for the Flow Logs service

### EKS readiness (tags only, no EKS resources)
- Subnets tagged for EKS/AWS Load Balancer Controller auto-discovery (`kubernetes.io/role/elb`, `kubernetes.io/role/internal-elb`, `kubernetes.io/cluster/<cluster_name>`)

## Design decisions

- **3 Availability Zones** — production HA standard; limits blast radius of an AZ failure, important for this app's persistent WebSocket connections.
- **NAT Gateway per AZ** — avoids a single NAT Gateway becoming a cross-AZ single point of failure.
- **Secondary CIDR for pods** — prevents IP exhaustion, a common EKS production failure mode when pods consume the primary VPC CIDR directly.
- **Separate data-tier subnets** — network-level isolation between application and data layers.
- **`for_each` over `count`** — used throughout for AZ-scoped resources (subnets, NAT, route tables) to avoid resource recreation issues from list reordering, and to guarantee resources across different types (e.g. a subnet and its NAT Gateway) stay correctly paired to the same AZ.

## What this repo does NOT include (by design)

EKS cluster and node groups, Security Groups for workloads, NACLs, RDS/ElastiCache, Helm charts, ArgoCD/GitOps, workload IAM/IRSA, observability stack (Prometheus/Grafana), WAF/edge security. These are handled in separate repos, which will consume this repo's outputs (VPC ID, subnet IDs, etc.) via Terraform remote state.

## Outputs

This repo exposes (via `env/prod/output.tf`): VPC ID, VPC CIDR, pod CIDR, subnet ID maps (all 4 tiers, keyed by AZ), route table ID maps, Internet Gateway ID, NAT Gateway ID/public IP maps, and the VPC endpoints security group ID — for consumption by future repos (EKS, RDS, etc.).