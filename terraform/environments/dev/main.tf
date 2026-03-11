terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
 # tells what terrafomr version and provider version are required to run 
 # states what provider we are using which is aws
  backend "s3" {
    bucket         = "vziraka-terraform-state"
    key            = "fullstack-cicd-pipeline/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
# this stores our state file in the S3 bucket with all other S3 files 
provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {} # this verify your aws credentials in your local machine

data "aws_iam_openid_connect_provider" "github" { 
  url = "https://token.actions.githubusercontent.com"
}
#  fetches the IAM OIDC provider for github actions in the terreaform-starter-kit
#  use the URl as a server token to verify aws authenticates 



resource "aws_ecr_repository" "app" { # creates the ECR repo for my app 
  name                 = var.ecr_repo_name
  image_tag_mutability = "IMMUTABLE" # this means images cant be overwritten using the same tags
                                     # this is good knowing who the authro is 
                                     # and making sure you push the right image 
  image_scanning_configuration {
    scan_on_push = true # scans the image for vulnerabilties 
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = var.ecr_repo_name
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
  }
} 

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
# keeps the last 10 images in the repo and deletes the rest to save space and cost 


resource "aws_iam_role" "ecr_push_pull" { #Role for push and pull policies 
  name = "github-actions-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity" 
        # Allows an external identity (GitHub Actions) to assume this AWS role 
        #using a web identity token instead of AWS credentials. 
        #This is the OIDC handshake action.
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        # this attaches the github provider to the role  

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          } # verifies the token with AWS


          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Vziraka/fullstack-cicd-pipeline:*"
          } # restrics only to my github repo 
        }
      }
    ]
  })

  tags = {
    Name        = "github-actions-ecr-role"
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "ecr_push_pull" { # policy for push and pull for the role
  name = "ecr-push-pull-policy"
  role = aws_iam_role.ecr_push_pull.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",# checks image if has all layers to run
          "ecr:GetDownloadUrlForLayer", # gets download link for certain layer
          "ecr:BatchGetImage", # pulls the full image from ECR 
          "ecr:PutImage", # saves complete image with tags 
          "ecr:InitiateLayerUpload", # tells ECR "im about to upload a new layer"
          "ecr:UploadLayerPart", # uoload layer in chunks
          "ecr:CompleteLayerUpload", # tell ECR all parts uploaded assemble a complete layer
          "ecr:DescribeRepositories", # reads info about in the repo
          "ecr:DescribeImages", # reads info about images 
          "ecr:ListImages" # list all images currently stores 
        ]
        Resource = aws_ecr_repository.app.arn 
      }
    ]
  })
}

# What is a layer for a Docker file ? 
# A Docker image isn't one big file. It's a stack of layers, each representing a step in your Dockerfile
#Each layer is stored separately in ECR.


# ECR takes your image 

#  ECR stores:
#  ├── Layer 1: node:20-alpine base
#  ├── Layer 2: WORKDIR /app
#  ├── Layer 3: node_modules (dependencies)
#  └── Layer 4: your app code

#  ECS pulls:
#  ↓
#  Downloads Layer 1 first
#  ↓
#  Downloads Layer 2
#  ↓
#  Downloads Layer 3
#  ↓
#  Downloads Layer 4
#  ↓
#  Stacks them all together
#  ↓
#  Runs as a container