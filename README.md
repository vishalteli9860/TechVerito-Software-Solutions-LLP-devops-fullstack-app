# Employee Management System
  It's an application to add and view employee Details.

# Backend
    backend is written in go version 1.19
    backend server starts at port 8080
  
    ## How to run
        1. Make sure you have go version 1.19 installed
        2. go get ./...
        3. DB_HOST=<POSTGRES_HOST> DB_USER=<POSTGRES_USER> DB_PASSWORD=<POSTGRES_PASSWORD> DB_NAME=<POSTGRES_DB_NAME> DB_PORT=<POSTGRES_PORT> ALLOWED_ORIGINS=<ALLOWED_ORGINS_VALUE> go run main.go

# Frontend
    Frontend is written in ReactJS
    Frontend server starts at port 3000
    
        ## How to run
            1. Make sure you have node version 14.17.0 installed
            2. npm install
            3. npm start

# AWS CI/CD Implementation

## Architecture

- Jenkins runs on a separate Ubuntu EC2 instance.
- K3s runs on a separate Ubuntu EC2 instance.
- PostgreSQL, the Go backend, and the React/Nginx frontend run in Kubernetes.
- Nginx Ingress exposes the application.
- Terraform creates the VPC, public subnet, security groups, EC2 instances, Docker installation, Jenkins installation, and K3s installation.
- Jenkins builds Docker images, pushes them to Docker Hub, updates Kubernetes deployments, and verifies rollout.

## 1. Local prerequisites

Install:

- AWS CLI
- Terraform 1.5+
- Docker
- an existing AWS EC2 key pair
- an AWS IAM user with permissions for EC2, VPC, Security Groups, and related networking resources

Configure AWS:

```powershell
aws configure
aws sts get-caller-identity
```

## 2. Create the infrastructure

Create a private `terraform.tfvars` file:

```powershell
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set `key_pair_name` to the EC2 key-pair name. Restrict `allowed_ssh_cidrs` to your public IP when possible, for example `["203.0.113.10/32"]`.

Initialize and apply:

```powershell
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Record the Jenkins and application URLs from the Terraform outputs.

## 3. Open Jenkins

Wait 3–5 minutes after EC2 creation, then visit:

```text
http://<jenkins_public_ip>:8081
```

Get the initial password through SSH:

```powershell
ssh -i <key.pem> ubuntu@<jenkins_public_ip>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Install the suggested plugins and create an administrator account.

## 4. Configure Jenkins credentials

Create a Jenkins **Username with password** credential with ID `dockerhub-credentials` using your Docker Hub username and access token.

Copy the K3s kubeconfig from the K3s server:

```powershell
ssh -i <key.pem> ubuntu@<k3s_public_ip>
sudo cat /home/ubuntu/.kube/config
```

In Jenkins, create a **Secret file** credential with ID `k3s-kubeconfig` and upload this file. K3s `k3s.yaml` must contain the EC2 public IP rather than `127.0.0.1`; the installation script rewrites it as `0.0.0.0`, so if necessary replace `0.0.0.0` with the K3s public IP or use the K3s server's HTTPS endpoint.

Install Jenkins plugins:
- Docker Pipeline
- Kubernetes CLI
- Git

Also ensure Jenkins can run Docker. The installation script adds `ubuntu` to the Docker group; restart Jenkins after this step if required:

```powershell
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

## 5. Configure Docker Hub and Jenkins parameters

Replace `REPLACE_DOCKER_USER` in `Jenkinsfile` with your Docker Hub username.

Do not commit a real Docker password or AWS key. The repository must remain private and credentials must be Jenkins-managed.

## 6. Create the Jenkins pipeline

1. Create a Jenkins **Pipeline** job.
2. Configure **Pipeline script from SCM**.
3. Select Git and enter the private repository URL.
4. Set the Script Path to `Jenkinsfile`.
5. Add Jenkins credentials for private Git access if required.
6. Run **Build Now**.

The pipeline performs:
- Go tests
- React tests and build
- Docker image build
- Docker Hub push
- Kubernetes manifest deployment
- backend/frontend rollout verification

## 7. Kubernetes deployment

The manifests in `k8s/` create:
- the `employee-app` namespace
- PostgreSQL, persistent storage, and a Kubernetes service
- the backend deployment and service
- the frontend deployment and service
- Nginx Ingress routing `/employees` to the backend and `/` to the frontend

To deploy manually from a machine with Docker and `kubectl`:

```powershell
$env:DOCKER_USER = "your-dockerhub-user"
$env:TAG = "v1"
bash scripts/deploy-local.sh
```

## 8. Verify the application

Open:

```text
http://<k3s_public_ip>:30080
```

Verify the endpoints:

```text
GET  http://<k3s_public_ip>:30080/employees
POST http://<k3s_public_ip>:30080/employees
```

A POST body example:

```json
{
  "name": "Jane Doe",
  "employee_id": 101
}
```

The frontend should display newly added employee records. Use the browser's Network tab if a request fails.

## 9. Docker Compose test

Run locally before cloud deployment:

```powershell
docker compose up --build
```

Open `http://localhost:3000`.

## 10. Production hardening

Before submitting or sharing externally:

- Restrict SSH CIDRs to a known IP.
- Store PostgreSQL credentials in Jenkins or an external secret manager; the included Secret is only for assignment use.
- Replace the HTTP Ingress with HTTPS and TLS certificates.
- Pin container image tags instead of `latest`.
- Add backend readiness/liveness probes and resource limits.
- Add a DNS name for the application and Jenkins.
- Restrict Jenkins credentials and Docker socket access.

## 11. Cleanup

To destroy AWS resources:

```powershell
cd terraform
terraform destroy
```

Keep private credentials and kubeconfig outside the source repository.
