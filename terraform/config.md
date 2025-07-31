# Centralized AWS Infrastructure (Core Networking & Shared Services)

This Terraform configuration module establishes the foundational networking and shared service infrastructure within our AWS account. These resources are designed to be consumed by multiple application services (e.g., `clue-api`, `random-word-api`, backend ECS/EKS clusters, monitoring tools) deployed in separate, application-specific Terraform workflows.

By centralizing these common components, we ensure consistency, enforce security best practices, simplify network topology, and optimize costs across our AWS environment.

## Table of Contents
1.  [Core VPC Network Configuration](#1-core-vpc-network-configuration)
2.  [VPC Endpoints (PrivateLink)](#2-vpc-endpoints-privatelink)
3.  [Main REST API Gateway](#3-main-rest-api-gateway)
4.  [Reusable IAM Policy Definitions](#4-reusable-iam-policy-definitions)
5.  [Reusable IAM Role Definitions](#5-reusable-iam-role-definitions)
6.  [Usage & Integration](#6-usage--integration)

1. Core VPC Network Configuration
This section defines the fundamental network infrastructure that all applications will leverage.

Resources Managed:
Virtual Private Cloud (VPC):
- Defines the isolated network space for all resources.
- Configures a specific CIDR block to accommodate future growth.

Subnets:
- Public Subnets:
    - Supports resources requiring direct internet access, including Application Load Balancers (ALBs) and NAT Gateways.
    - Each public subnet is associated with a route table that directs internet-bound traffic to the Internet Gateway.
    - Deployed across multiple Availability Zones for high availability.

- Private Application Subnets:
    - Hosts application compute resources such as Lambda functions, ECS tasks, and ENIs.
    - These subnets lack a direct route to the Internet Gateway; outbound internet access is provided via the NAT Gateway.
    - Deployed across multiple Availability Zones.

- Private Data Subnets:
    - Dedicated for sensitive data storage solutions, such as Redis.
    - These subnets also lack a direct route to the Internet Gateway and are secured with stricter security group rules.
    - Deployed across multiple Availability Zones.

- Internet Gateway (IGW):
    - Attached to the VPC to facilitate communication between resources in public subnets and the internet.

- NAT Gateway(s):
    - Deployed in public subnets (at least one per AZ for high availability) to provide outbound internet connectivity for resources in private subnets (e.g., Lambda functions requiring access to external APIs).
    - Each NAT Gateway is associated with an Elastic IP address.

- Route Tables:
    - Public Route Tables: Associated with public subnets, containing a default route (0.0.0.0/0) pointing to the Internet Gateway.
    - Private Route Tables: Associated with private subnets, containing a default route (0.0.0.0/0) pointing to the NAT Gateway. Also contain specific routes for VPC Gateway Endpoints.

- VPC Flow Logs:
    - Enabled for the VPC to capture IP traffic information, supporting network monitoring, troubleshooting, and security analysis.
    - Logs are delivered to CloudWatch Logs.

- Security Groups:
    - Core security groups are defined to provide basic network isolation and access for common patterns (e.g., `sg-alb-ingress`, `sg-lambda-egress-to-endpoints`).
    - More granular, application-specific security groups are managed by individual service deployments.

2. VPC Endpoints (PrivateLink)
These endpoints enable private and secure communication between resources within our VPC and specified AWS services, eliminating the need for traffic to traverse the public internet.

Resources Managed:
- Amazon S3 Gateway Endpoint (com.amazonaws.<region>.s3):
    - Provides private connectivity from the VPC to the S3 service.
    - Cost: Free.
    - Mechanism: Traffic is routed using prefix lists within the VPC's route tables.
    - Usage: All S3 buckets in the region are privately accessible.
    - Access control to specific buckets is handled via IAM policies.

- Amazon DynamoDB Gateway Endpoint (com.amazonaws.<region>.dynamodb):
    - Provides private connectivity from the VPC to the DynamoDB service.
    - Cost: Free of charge.
    - Mechanism: Traffic is routed using prefix lists within the VPC's route tables.
    - Usage: All DynamoDB tables in the region are privately accessible.
    - Access control to specific tables is handled via IAM policies.

- Amazon SQS Interface Endpoint (com.amazonaws.<region>.sqs):
    - Provides private connectivity to the SQS service.
    - Cost: Hourly charges + data processing.

    - Mechanism: Creates Elastic Network Interfaces (ENIs) with private IPs in specified subnets. DNS resolution for SQS service endpoints is handled privately within the VPC.

    - Usage: Enables private communication for Lambda functions or other services to send/receive messages from SQS queues (e.g., for asynchronous logging or event-driven flows).

*   **AWS Secrets Manager Interface Endpoint (com.amazonaws.<region>.secretsmanager):**
    *   Provides private connectivity to the AWS Secrets Manager service.
    *   Cost: Hourly charges + data processing.
    *   Mechanism: Creates ENIs in specified subnets with private DNS resolution for Secrets Manager.
    *   Usage: Enables Lambda functions and other services to securely retrieve secrets (e.g., API keys, database credentials) without exposing traffic to the internet.

*   **AWS Key Management Service (KMS) Interface Endpoint (com.amazonaws.<region>.kms):**
    *   Provides private connectivity to the AWS KMS service.
    *   Cost: Hourly charges + data processing.
    *   Mechanism: Creates ENIs in specified subnets with private DNS resolution for KMS.
    *   Usage: Required for services in private subnets to perform KMS encryption/decryption operations, particularly when using Customer Managed Keys (CMKs) for data protection (e.g., encrypting DynamoDB data, S3 objects, or Secrets Manager secrets).

*   **Amazon CloudWatch Logs Interface Endpoint (com.amazonaws.<region>.logs):**
    *   Essential for Lambda functions within a VPC to send logs to CloudWatch Logs via a private path.
    *   Cost: Hourly charges + data processing.
    *   Mechanism: Creates ENIs in specified subnets with private DNS resolution for CloudWatch Logs.
    *   Usage: Ensures secure delivery of all application logs from Lambda, ECS, EKS, etc., to CloudWatch Logs for monitoring and debugging.

*   **AWS Lambda Interface Endpoint (com.amazonaws.<region>.lambda - Optional):**
    *   Provides private connectivity to the Lambda API itself.
    *   Cost: Hourly charges + data processing.
    *   Usage: For Lambda functions invoking other Lambda functions directly via the Lambda API, this endpoint ensures private communication within the AWS network, avoiding public API endpoints. While not strictly necessary for typical client-invoked APIs, it is recommended for internal Lambda-to-Lambda calls.

3. Main REST API Gateway
This module defines the central AWS API Gateway (REST API) resource, serving as the primary ingress point for all external API traffic into the application suite. Individual application teams or service-specific Terraform modules extend this central API Gateway.

Resources Managed:
*   **`aws_api_gateway_rest_api`**:
    *   The top-level API Gateway resource (e.g., `main-game-api`).
    *   Configures the API's base path, name, description, and endpoint configuration (e.g., `REGIONAL` or `EDGE`).
    *   Does not define specific resources or methods at this level.

*   **`aws_api_gateway_account` (Optional but Recommended):**
    *   Configures account-level settings for API Gateway, including CloudWatch logging roles and throttling limits.

*   **`aws_api_gateway_usage_plan` / `aws_api_gateway_api_key` (Optional):**
    *   If you plan to implement API key-based access or usage metering, these can be centrally managed.

*   **Custom Domain Name Configuration (Optional):**
    *   If a custom domain (e.g., `api.yourgame.com`) is desired, this module can provision:
        *   `aws_api_gateway_domain_name`
        *   `aws_api_gateway_base_path_mapping` (to map sub-paths to stages of this API)
        *   `aws_acm_certificate` and `aws_route53_record` for TLS and DNS records.

**Integration with Other Services:**
*   **Shared Reference:** Other application-specific Terraform modules (e.g., `clue-api-module`, `random-word-api-module`) will retrieve the `id` and `root_resource_id` of this central `aws_api_gateway_rest_api` using a Terraform data source or remote state.

*   **Resource & Method Creation:** Each application module will then use these IDs to create their own:
    *   `aws_api_gateway_resource` (e.g., `/clue`, `/random-word`) as children of the main API's root resource.
    *   `aws_api_gateway_method` (e.g., `GET`, `POST`) on those resources.
    *   `aws_api_gateway_integration` (e.g., connecting to a Lambda function, ECS service).

*   **Deployment & Stages:** Each service can deploy its own changes to a common stage (e.g., `prod`, `dev`) of this central API Gateway, or separate stages if required by the deployment strategy.
4. Reusable IAM Policy Definitions
This section defines common, reusable IAM policies for attachment to various roles across different services, promoting the principle of least privilege and consistency.

Examples of Policies Managed:
*   **`CommonLambdaExecutionPolicy`:**
    *   Grants basic permissions required by all Lambda functions deployed within a VPC (e.g., permissions to create/manage ENIs for VPC access, basic CloudWatch Logs write permissions).
    
*   **`SecretsReaderPolicy`:**
    *   Grants `secretsmanager:GetSecretValue` on secrets matching a specified tag or naming convention. This policy is attached to application-specific roles, restricted to the necessary secret ARNs.

*   **`SqsSenderPolicy`:**
    *   Grants `sqs:SendMessage` on a common logging or notification queue.

*   **`KmsDecryptPolicy`:**
    *   Grants `kms:Decrypt` access to a specific KMS key (or keys matching a tag) for common encryption tasks across multiple services.

5. Reusable IAM Role Definitions
This section defines common IAM roles or role patterns that can be assumed by various AWS services or trusted entities.

Examples of Roles Managed:
*   **`LambdaBaseExecutionRole`:**
    *   A foundational role for all Lambda functions, which can then have additional, specific permissions attached via managed policies or inline policies by the individual application modules. This role would typically include the `AWSLambdaBasicExecutionRole` and `AWSLambdaVPCAccessExecutionRole` managed policies.
*   **`ECSTaskExecutionRole`**:
    *   A base role for ECS tasks, enabling ECS to pull images from ECR and send logs to CloudWatch.
*   **`AlbServiceLinkedRole`:**
    *   Ensures the ALB has the necessary permissions to operate (though often created automatically by AWS).
*   **`ApiGatewayCloudWatchRole`:**
    *   Role for API Gateway to write access logs and execution logs to CloudWatch.

6. Usage & Integration
Other Terraform modules representing individual application services will perform the following:

*   **Reference Outputs:** Use `terraform_remote_state` or data sources to fetch outputs from this centralized module (e.g., VPC ID, subnet IDs, security group IDs, endpoint IDs, main API Gateway ID).

*   **Attach Resources:** Deploy their application-specific resources (Lambda functions, ECS services, DynamoDB tables, SQS queues) into the private subnets defined here, configured with the relevant security groups and leveraging the centralized VPC endpoints and main API Gateway.

*   **Apply Granular IAM:** Attach specific, least-privilege IAM policies to their service roles, potentially leveraging the reusable IAM policies defined in this module.