#!/bin/bash
# ============================================================
# EC2 Setup Script — Run this ONCE after SSH-ing into EC2
# Usage: chmod +x setup-ec2.sh && ./setup-ec2.sh
# ============================================================
set -e

ACCOUNT_ID="$1"      # Your AWS Account ID
REGION="${2:-us-east-1}"
REPO_NAME="nodejs-k8s-app"

if [ -z "$ACCOUNT_ID" ]; then
  echo "Usage: ./setup-ec2.sh YOUR_AWS_ACCOUNT_ID [REGION]"
  echo "Example: ./setup-ec2.sh 123456789012 us-east-1"
  exit 1
fi

ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"

echo "============================================"
echo " EC2 Setup: Docker + kubectl + Minikube"
echo " ECR: $ECR_URI"
echo "============================================"

# ── 1. System update ──────────────────────────
echo "[1/8] Updating system packages..."
sudo yum update -y

# ── 2. Install Docker ─────────────────────────
echo "[2/8] Installing Docker..."
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
echo "Docker installed: $(docker --version)"

# ── 3. Install AWS CLI ────────────────────────
echo "[3/8] Installing AWS CLI..."
sudo yum install awscli -y
echo "AWS CLI: $(aws --version)"

# ── 4. Install kubectl ────────────────────────
echo "[4/8] Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
echo "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# ── 5. Install conntrack (Minikube dependency) ─
echo "[5/8] Installing conntrack..."
sudo yum install conntrack -y

# ── 6. Install Minikube ───────────────────────
echo "[6/8] Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
echo "Minikube: $(minikube version)"

# ── 7. Start Minikube ─────────────────────────
echo "[7/8] Starting Minikube (this takes ~2 min)..."
# Need to re-run docker group permissions
newgrp docker << EOF
minikube start --driver=docker --memory=1800 --cpus=1
EOF

# ── 8. ECR login + create K8s secret ─────────
echo "[8/8] Authenticating to ECR and creating K8s pull secret..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin \
  "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

kubectl create secret docker-registry ecr-secret \
  --docker-server="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com" \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region $REGION) \
  --docker-email=setup@local.local || echo "Secret may already exist — skipping"

echo ""
echo "============================================"
echo " ✅  EC2 Setup Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Apply Kubernetes manifests:"
echo "     kubectl apply -f k8s/deployment.yaml"
echo "     kubectl apply -f k8s/service.yaml"
echo ""
echo "  2. Check pods:"
echo "     kubectl get pods"
echo ""
echo "  3. Access app (port-forward for public access):"
echo "     kubectl port-forward svc/nodejs-service 8080:80 --address 0.0.0.0 &"
echo "     Then open: http://$(curl -s ifconfig.me):8080"
echo ""
