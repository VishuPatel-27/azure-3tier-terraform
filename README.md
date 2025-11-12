# AZURE-3TIER-TERRAFORM

#### In this project I have deployed a secure and scalable 3-tier application, consisting of frontend, backend and database tiers, on Azure platform using Terraform. I created this production ready infrastructure on Azure using Terraform custom modules and best practices.


## Application Demo
https://github.com/user-attachments/assets/a78776f3-9665-4392-9c5c-aaa39779cddd


## Application Architecture
![Application Architecuture](<application_architecture.png>)


## Directory Structure

```text
azure-3tier-terraform/                          # root project directory
├─ README.md                                    # project README
├─ azure-3tier-terraform-project.mp4            # demo video
├─ application_architecture.png                 # architecture diagram
├─ .gitignore
├─ frontend-svc/                                # presentation layer: Node.js + static frontend
│  ├─ package.json
│  ├─ package-lock.json
│  ├─ server.js                                 # Express server entry
│  ├─ Dockerfile
│  ├─ public/
│  │  ├─ index.html
│  └─ README.md
├─ backend-svc/                                 # business logic: Go API service
│  ├─ go.mod
│  ├─ go.sum
│  ├─ main.go
│  └─ Dockerfile
├─ docker-local-deployment/                     # local docker-compose for development
│  ├─ docker-compose.yml
│  └─ database/
│     └─ init.sql                               # DB schema & seed data
├─ prerequisites-setup/                         # setup helpers for Azure and Terraform
│  ├─ sp_creation.sh                            # create Azure service principal
│  └─ tf_backend_creation.sh                    # create Terraform remote backend
├─ azure-infra/                                 # Terraform entrypoint for Azure deployment
│  ├─ main.tf
│  ├─ providers.tf
│  ├─ variables.tf
│  ├─ outputs.tf
│  └─ environments/
│     └─ prod/
│        └─ terraform.tfvars                    # production variable values
├─ modules/                                     # custom reusable Terraform modules
│  ├─ compute/                                  # VMSS, load balancer / app gateway, autoscale
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  ├─ outputs.tf
│  │  └─ scripts/
│  │     ├─ frontend_provision.sh               # provisions frontend VM instances
│  │     └─ backend_provision.sh                # provisions backend VM instances, KeyVault integration
│  ├─ database/                                 # Postgres Flexible Server + replica
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  └─ outputs.tf
│  ├─ dns/                                      # private DNS zone & VNet links
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  └─ outputs.tf
│  ├─ keyvault/                                 # Key Vault with access policies
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  └─ outputs.tf
│  └─ networking/                               # VNet, subnets, NSGs, NAT, Bastion
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  └─ outputs.tf
|_________
```


## 3-Tier Application Overview and guide to run on local

### This application demonstrates a modern three-tier-architecture: 
1) Presentation Layer (Frontend):
    * Node.js/Express server serving a JavaScript frontend
    * Serves static files from the /public directory
    * Provides API proxying to the backend
    * Handles all user interactions
    #### Building frontend application

    ```console
    cd frontend-svc/
    npm install
    npm start
    ```
2) Business Logic Layer (Backend): Go API service
    * Provides JSON REST API endpoints
    * Connects to the PostgreSQL database
    * Implements business logic
    * Exposes metrics for monitoring
    ```console
    cd backend-svc/
    go mode download
    go run main.go
    ```
3) Data Layer: PostgreSQL database
    * Stores goal tracking data
    * Initializes with the schema defined in docker-local-deployment/database/init.sql
    * Use official postgres docker image

### Useful API Endpoints:

1) Backend API (Go Service)
    * GET /goals - Get all goals
    * POST /goals - Add a new goal
    * DELETE /goals/:id - Delete a goal by ID
    * GET /health - Health check endpoint
    * GET /metrics - Prometheus metrics endpoint
2) Frontend API Proxy (Node.js)
    * GET /api/goals - Proxy to backend's GET /goals
    * POST /api/goals - Proxy to backend's POST /goals
    * DELETE /api/goals/:id - Proxy to backend's DELETE /   goals/:id


## Local Deployment using Docker Compose

### Prerequisites
* Docker (version 20.10+)
* Docker Compose (version 2.0+)

#### Step 1: Go to the docker-local-deployment directory
```console
cd docker-local-deployment
```
#### Step 2: Copy paste the below command to run the application
```console
docker-compose up -d
```
#### Step 3: Access the application
* Frontend: http://localhost:3000
* Backend API: http://localhost:8080
* Database: http://localhost:5432 (use pgAdmin or any other client to connect )

## Terraform Custom Modules Overview

### 1. Compute Module
* **Overview:** The Compute Module automates creation and management of **scalable, secure, and self-healing compute infrastructure** in Azure. It dynamically provisions either a frontend (public-facing) or backend (internal) environment based on the **var.is_frontend flag**.
* It includes,
    * Virtual Machine Scale Set (VMSS) for containerized application hosting
	* Load balancer or Application Gateway for traffic management
	* Managed identity for secure authentication
	* Custom provisioning scripts for automated Docker setup
	* Autoscaling rules for performance optimization
    * Frontend Provisioning Script – frontend_provision.sh
        * **Purpose:** Sets up frontend VM instances in the VM Scale Set to host a containerized web application. Handles Docker installation, authentication, image deployment, and backend connectivity.
    * Backend Provisioning Script – backend_provision.sh
        * **Purpose:** Configures backend VM instances for secure deployment of backend microservices. Integrates with Azure Key Vault via Managed Identity for database credentials.
### 2. Database Module
* **Overview**: The Database Module provisions a PostgreSQL Flexible Server setup designed for fault tolerance, data durability, and security.
* It **creates**:
    * One Primary PostgreSQL Server (Zone 1)
    * One Read Replica (Zone 2)
    * One Initial Database
    * Secure configuration for SSL, logging, and performance

* It ensures zone redundancy by distributing resources across two availability zones, reducing downtime during maintenance or zone-level failures.
* Some key features:
    * Zero public exposure
	* Automated failover
	* Operational resilience
	* Configurable performance and monitoring
### 3. DNS Module
* This module provisions a Private DNS Zone for Azure PostgreSQL Flexible Server and establishes a VNet link so that compute resources (such as backend VMs or containers) can resolve the server’s private FQDN inside the virtual network.
* It ensures name resolution stays internal, removing any dependency on public DNS and preventing data exposure outside your VNet.
* Private DNS Zone creation: Provides private DNS entries for all PostgreSQL Flexible Servers deployed in private mode within the same VNet or linked networks.

### 4. KeyVault Module
* **Overview**: This module creates an Azure Key Vault for storing secrets your app needs. It gives you a unique vault name, basic access policies, optional managed identity permissions for backend, and permissive network ACLs by default.
* **Features and purpose**
	* Creates a Key Vault named with your resource prefix plus a short random suffix.
	* Uses soft delete with a 7 day retention window.
	* Uses standard SKU.
	* Enables disk encryption usage.
	* Provides an access policy for a primary principal defined by var.object_id.
	* Optionally grants read access to a backend VM managed identity when var.backend_identity_principal_id is provided.
	* Network ACLs default to Allow with AzureServices bypass. That makes initial access easy.
	* Tags are attached for cost and ownership tracking.

### 5. Networking Module
* **Purpose**: builds your VNet, subnets, NSGs, Bastion, NAT gateway, and associations.
* **Result**: isolated network fabric ready for frontend, backend, and database tiers.
* What it **creates**: public subnets for frontend, private subnets for backend, database subnet for database, app gateway for application gateway, bastion subnet, network security groups for all subnets, NAT gateway, and public IPs.

## 3-Tier Application Infrastructure on Azure

### Prerequisites

* Azure CLI installed and configured
* Terraform v1.5.0 or later
* Azure subscription and permissions to create resources
* Docker installed locally for building and pushing container images

### Service Principal Setup for Terraform

* We need to create a service principal for deploying infrastructure on Azure. Following industry best practices, infrastructure deployments should be performed using a dedicated service principal with only the required permissions, rather than root or owner account credentials.

* This improves security, ensures better access control, and aligns with least-privilege principles.

* Steps to create service principal: 

1) change directory to prerequisites-setup
    ```console
    cd prerequisites-setup/
    ```
2) run the sp_creation bash script (make sure it has executable permission)
    ```python
    ./sp_creation.sh
    ```

### Remote Terraform backend creation

* We need a remote backend in Terraform for collaboration, durability, and security when working in a team or managing infrastructure beyond a single local machine

* Steps to create remote backend: 

1) change directory to prerequisites-setup
    ```console
    cd prerequisites-setup/
    ```
2) run the tf_backend_creation bash script (make sure it has executable permission)
    ```console
    ./tf_backend_creation.sh
    ```

### One-Step Deployment Approach

* Since we're now using Docker Hub instead of Azure Container Registry, we can deploy the entire infrastructure in one step. First, make sure your Docker images are pushed to Docker Hub:

```console
# Log in to Docker Hub
docker login -u YOUR_DOCKERHUB_USERNAME

# Build and tag your images (Run from the root of the project)
docker build -t YOUR_DOCKERHUB_USERNAME/frontend-svc:1.0 ./frontend-svc
docker build -t YOUR_DOCKERHUB_USERNAME/backend-svc:1.0 ./backend-svc

# Push to Docker Hub
docker push YOUR_DOCKERHUB_USERNAME/frontend-svc:1.0
docker push YOUR_DOCKERHUB_USERNAME/backend-svc:1.0
```

1) Initialize Terraform
* Make sure you initilize the terraform from azure-infra directory 
```console
cd azure-infra
terraform init
```

2) Format and validate terraform code
```console
terraform fmt .
terraform validate -test-directory=.
```

3) Terraform plan will give you resource details, provision by this code
```console
terraform plan
```

4) Deploy infrastructure with dockerhub credentials as environment variables
```console
cd azure-infra
terraform apply \
  -var-file="environments/prod/terraform.tfvars" \
  -var="dockerhub_username=YOUR_DOCKERHUB_USERNAME" \
  -var="dockerhub_password=YOUR_DOCKERHUB_PAT"
```

### Access the application

* After deployment completes, access your application:

* Frontend: Use the Application Gateway public IP address:

    ```console
    echo "Frontend URL: http://$(terraform output -raw frontend_public_ip)"
    ```
* Backend: Access via internal load balancer (from within the VNet):

    ```console
    echo "Backend internal endpoint: http://$(terraform output -raw backend_internal_lb_ip):8080"
    ```
* Database: Access via private endpoints from the backend tier:

    ```console
    echo "PostgreSQL Server: $(terraform output -raw postgres_server_fqdn)"
    echo "PostgreSQL Replica: $(terraform output -raw postgres_replica_name)"
    ```
* SSH into the Bastion host to access the backend and frontend:

    ```console
    terraform output -raw frontend_ssh_private_key > frontend_key.pem
    terraform output -raw backend_ssh_private_key > backend_key.pem 
    ```
### Infrastructure Management
#### Scaling
* The VM Scale Sets will automatically scale based on CPU usage. You can modify the scaling rules in the compute module.
#### Monitoring
* The deployment includes Azure Monitor integration. Configure alerts and dashboards in the Azure Portal.
#### Security
* All subnets are protected with Network Security Groups
* Application Gateway has WAF enabled
* PostgreSQL is only accessible via private endpoints
* Key Vault stores sensitive information (including Docker Hub credentials)
* SSH access is only available via Bastion Host

### Cleanup

* Once you done with implementation don't forget to destroy the deployment otherwise, will cost you fortune!!

```console
terraform destroy -auto-approve
```
*If You get a error in the destrucion process rerun the above command again*

### Contribution

* Please follow the standard Git workflow:

    1) Fork the repository
    2) Create a feature branch
    3) Make your changes
    4) Submit a pull request

