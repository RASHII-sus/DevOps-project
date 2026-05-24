# Node.js on Kubernetes — AWS Free Tier + GitHub Actions CI/CD

## Project Structure
```
nodejs-k8s-app/
├── server.js                        # Node.js application
├── package.json                     # Dependencies
├── Dockerfile                       # Container definition
├── .dockerignore
├── .gitignore
├── push-to-ecr.sh                   # Run on YOUR LAPTOP first
├── setup-ec2.sh                     # Run on EC2 after SSH
├── k8s/
│   ├── deployment.yaml              # Kubernetes Deployment
│   └── service.yaml                 # Kubernetes Service (NodePort)
└── .github/
    └── workflows/
        └── deploy.yml               # GitHub Actions CI/CD pipeline
```

---

## Step-by-Step Commands

### LAPTOP — Phase 1: Test app locally
```bash
npm install
node server.js
# Open http://localhost:3000
```

### LAPTOP — Phase 2 & 3: Docker + ECR
```bash
# 1. Build and test Docker locally
docker build -t nodejs-k8s-app .
docker run -p 3000:3000 nodejs-k8s-app
# Open http://localhost:3000 — verify it works, then Ctrl+C

# 2. Push to ECR (replace with your Account ID)
chmod +x push-to-ecr.sh
./push-to-ecr.sh YOUR_ACCOUNT_ID us-east-1

# 3. Update k8s/deployment.yaml — replace this line:
#    image: YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/nodejs-k8s-app:latest
# with the URI printed by push-to-ecr.sh
```

### AWS CONSOLE — Phase 4: Launch EC2
1. EC2 → Launch Instance
2. Name: `k8s-node`
3. AMI: Amazon Linux 2 (Free Tier eligible)
4. Instance type: `t2.micro`
5. Key pair: Create new → download `.pem` file → save safely
6. Security group — Add these inbound rules:
   - SSH (22) — My IP
   - Custom TCP (8080) — Anywhere
   - Custom TCP (30000-32767) — Anywhere
7. Launch!

### EC2 — Phase 5: Install everything
```bash
# SSH into EC2 (use your .pem file and EC2 public IP)
chmod 400 my-key.pem
ssh -i my-key.pem ec2-user@YOUR_EC2_PUBLIC_IP

# Upload and run setup script (on EC2):
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup-ec2.sh
chmod +x setup-ec2.sh
./setup-ec2.sh YOUR_ACCOUNT_ID us-east-1

# Or paste the script contents manually
```

### EC2 — Phase 6 & 7: Deploy to Kubernetes
```bash
# 1. Create ECR pull secret
kubectl create secret docker-registry ecr-secret \
  --docker-server=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --docker-email=you@email.com

# 2. Apply Kubernetes manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# 3. Check everything is running
kubectl get pods
kubectl get services

# 4. Make app publicly accessible
kubectl port-forward svc/nodejs-service 8080:80 --address 0.0.0.0 &

# App is now live at: http://YOUR_EC2_PUBLIC_IP:8080
```

### GITHUB — Phase 8: CI/CD Setup
Add these secrets to GitHub → Settings → Secrets → Actions:
```
AWS_ACCESS_KEY_ID      = your AWS key
AWS_SECRET_ACCESS_KEY  = your AWS secret
AWS_REGION             = us-east-1
EC2_HOST               = your EC2 public IP
EC2_SSH_PRIVATE_KEY    = full contents of your .pem file
```

Then push code to main branch — pipeline runs automatically!

### Verify CI/CD works
```bash
# Make any small change (e.g. change a word in server.js)
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
# Watch GitHub Actions → refresh browser → see update!
```

---

## Useful kubectl commands
```bash
kubectl get pods                        # List pods
kubectl get services                    # List services
kubectl describe pod POD_NAME           # Pod details
kubectl logs -l app=nodejs-app          # View logs
kubectl scale deployment nodejs-app --replicas=2   # Scale up
kubectl rollout status deployment/nodejs-app       # Deployment status
kubectl rollout restart deployment/nodejs-app      # Restart pods
minikube ip                             # Get Minikube IP
```

## GitHub Actions Secrets Required
| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `AWS_REGION` | e.g. `us-east-1` |
| `EC2_HOST` | EC2 public IP address |
| `EC2_SSH_PRIVATE_KEY` | Full content of `.pem` key file |

## Cost Analysis — $0.00
| Service | Free Tier | Used | Cost |
|---------|-----------|------|------|
| EC2 t2.micro | 750 hrs/month (12 months) | ~50 hrs | $0.00 |
| Amazon ECR | 500MB storage | ~50MB | $0.00 |
| GitHub Actions | 2000 min/month | ~20 min | $0.00 |
| Minikube | Open source | Free | $0.00 |
| **TOTAL** | | | **$0.00** |

## Cleanup (after submission!)
```bash
# On EC2:
kubectl delete deployment nodejs-app
kubectl delete service nodejs-service
minikube stop && minikube delete

# On laptop:
aws ec2 terminate-instances --instance-ids YOUR_INSTANCE_ID
aws ecr delete-repository --repository-name nodejs-k8s-app --force --region us-east-1
```
