# terraform-vpc-module

A reusable Terraform module for provisioning a production-ready AWS VPC with public, private, and database subnet tiers, a NAT Gateway, and optional VPC peering with the default VPC.

---

## Architecture Overview

```
                        ┌─────────────────────────────────────────────┐
                        │                  AWS VPC                    │
                        │           (var.vpc_cidr_block)              │
                        │                                             │
                        │  ┌──────────────┐  ┌──────────────┐        │
                        │  │ Public Subnet│  │ Public Subnet│        │
                        │  │   (AZ-1)     │  │   (AZ-2)     │        │
                        │  └──────┬───────┘  └──────────────┘        │
                        │         │  IGW ──── Internet                │
                        │  ┌──────▼───────┐                          │
                        │  │ NAT Gateway  │ ◄── Elastic IP            │
                        │  └──────┬───────┘                          │
                        │         │                                   │
                        │  ┌──────▼───────┐  ┌──────────────┐        │
                        │  │Private Subnet│  │Private Subnet│        │
                        │  │   (AZ-1)     │  │   (AZ-2)     │        │
                        │  └──────────────┘  └──────────────┘        │
                        │                                             │
                        │  ┌──────────────┐  ┌──────────────┐        │
                        │  │  DB Subnet   │  │  DB Subnet   │        │
                        │  │   (AZ-1)     │  │   (AZ-2)     │        │
                        │  └──────────────┘  └──────────────┘        │
                        └─────────────────────────────────────────────┘
                                       │ (optional peering)
                                  ┌────▼────┐
                                  │ Default │
                                  │   VPC   │
                                  └─────────┘
```

Resources created by this module:

- **VPC** with DNS hostnames enabled
- **Internet Gateway** attached to the VPC
- **Public subnets** (one per AZ, `map_public_ip_on_launch = true`)
- **Private subnets** (one per AZ)
- **Database subnets** (one per AZ)
- **Route tables** — separate tables for public, private, and database tiers
- **Elastic IP** for the NAT Gateway
- **NAT Gateway** placed in the first public subnet
- **VPC Peering Connection** with the default VPC (optional, controlled by `is_peering_required`)
- **Peering routes** in public, private, and default VPC route tables when peering is enabled

Subnets are automatically distributed across the first **two** available Availability Zones in the region.

---

## File Structure

| File | Purpose |
|------|---------|
| `vpc.tf` | Core VPC, subnets, route tables, IGW, EIP, NAT Gateway, and route table associations |
| `peering.tf` | Optional VPC peering with the AWS default VPC and associated routes |
| `variables.tf` | All input variable declarations |
| `locals.tf` | Common tags, name suffix, and AZ slice logic |
| `data.tf` | Data sources for available AZs, default VPC, and its main route table |
| `output.tf` | Exported values: VPC ID and subnet IDs |

---

## Usage

```hcl
module "vpc" {
  source = "github.com/Shankar-codes/terraform-vpc-module"

  # Required
  vpc_cidr_block        = "10.0.0.0/16"
  project_name          = "myapp"
  environment           = "dev"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]

  # Optional — disable peering with the default VPC
  is_peering_required = false

  # Optional — extra tags per resource type
  vpc_tags                  = { "CostCenter" = "platform" }
  public_subnet_tags        = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags       = { "kubernetes.io/role/internal-elb" = "1" }
  database_subnet_tags      = {}
  public_route_table_tags   = {}
  private_route_table_tags  = {}
  database_route_table_tags = {}
  eip_tags                  = {}
  nat_gateway_tags          = {}
  igttags                   = {}
}
```

### Referencing outputs in other modules

```hcl
resource "aws_instance" "app" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.private_subnet_id[0]
}
```

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.0 |
| AWS Provider | >= 4.0 |

Configure the AWS provider before calling the module:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `vpc_cidr_block` | `string` | — | ✅ | CIDR block for the VPC |
| `project_name` | `string` | — | ✅ | Project name used for tagging and resource naming |
| `environment` | `string` | — | ✅ | Environment name (e.g. `dev`, `staging`, `prod`) |
| `public_subnet_cidrs` | `list` | — | ✅ | List of CIDR blocks for public subnets (one per AZ) |
| `private_subnet_cidrs` | `list` | — | ✅ | List of CIDR blocks for private subnets (one per AZ) |
| `database_subnet_cidrs` | `list` | — | ✅ | List of CIDR blocks for database subnets (one per AZ) |
| `is_peering_required` | `bool` | `true` | ❌ | Whether to create a peering connection with the default VPC |
| `vpc_tags` | `map` | `{}` | ❌ | Additional tags for the VPC |
| `igttags` | `map` | `{}` | ❌ | Additional tags for the Internet Gateway |
| `public_subnet_tags` | `map` | `{}` | ❌ | Additional tags for public subnets |
| `private_subnet_tags` | `map` | `{}` | ❌ | Additional tags for private subnets |
| `database_subnet_tags` | `map` | `{}` | ❌ | Additional tags for database subnets |
| `public_route_table_tags` | `map` | `{}` | ❌ | Additional tags for the public route table |
| `private_route_table_tags` | `map` | `{}` | ❌ | Additional tags for the private route table |
| `database_route_table_tags` | `map` | `{}` | ❌ | Additional tags for the database route table |
| `eip_tags` | `map` | `{}` | ❌ | Additional tags for the Elastic IP |
| `nat_gateway_tags` | `map` | `{}` | ❌ | Additional tags for the NAT Gateway |

---

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the created VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_id` | List of private subnet IDs |
| `database_subnet_id` | List of database subnet IDs |

---

## Tagging Convention

All resources are automatically tagged with:

```hcl
{
  Project     = var.project_name
  Environment = var.environment
  Terraform   = "true"
  Name        = "<project_name>-<environment>"   # or with AZ/tier suffix
}
```

Additional tags passed via the `*_tags` variables are merged on top using `merge()`, so they can override or extend the defaults.

---

## VPC Peering

When `is_peering_required = true` (the default), the module:

1. Creates a peering connection between the new VPC and the AWS **default VPC** in the same account/region.
2. Enables DNS resolution across both sides of the peering (`allow_remote_vpc_dns_resolution = true`).
3. Adds a route in the **public** and **private** route tables pointing to the default VPC's CIDR via the peering connection.
4. Adds a return route in the **default VPC's main route table** pointing back to `var.vpc_cidr_block`.

Set `is_peering_required = false` to skip all peering resources.

---

## Notes

- **Two AZs only** — `locals.tf` slices the available AZ list to the first two. Ensure your subnet CIDR lists contain exactly two entries.
- **Single NAT Gateway** — to reduce cost, a single NAT Gateway is deployed in `public[0]`. For high-availability production setups, consider extending the module to provision one NAT Gateway per AZ.
- **Default VPC must exist** — when peering is enabled, the module reads the default VPC via a data source. If the default VPC has been deleted in your account, disable peering or restore the default VPC.

---

## License

MIT
