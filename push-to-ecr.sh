#!/bin/bash
# ============================================================
# Local Setup Script — Run on YOUR LAPTOP first
# Creates ECR repo and pushes first Docker image
# Usage: chmod +x push-to-ecr.sh && ./push-to-ecr.sh YOUR_ACCOUNT_ID
# ============================================================
set -e

ACCOUNT_ID="$1"
REGION="${2:-us-east-1}"
REPO_NAME="nodejs-k8s-app"

if [ -z "$ACCOUNT_ID" ]; then
  echo "Usage: ./push-to-ecr.sh YOUR_AWS_ACCOUNT_ID [REGION]"
  echo "Find your Account ID: aws sts get-caller-identity --query Account --output text"
  exit 1
fi

ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"

echo "============================================"
echo " Pushing to ECR: $ECR_URI"
echo "============================================"

# Create ECR repository (ignore error if already exists)
echo "[1/4] Creating ECR repository..."
aws ecr create-repository \
  --repository-name $REPO_NAME \
  --region $REGION \
  --image-scanning-configuration scanOnPush=true 2>/dev/null || \
  echo "Repository already exists — continuing..."

# Login to ECR
echo "[2/4] Authenticating Docker to ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin \
  "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Build image
echo "[3/4] Building Docker image..."
docker build -t $REPO_NAME:latest .

# Tag and push
echo "[4/4] Tagging and pushing to ECR..."
docker tag $REPO_NAME:latest $ECR_URI:latest
docker push $ECR_URI:latest

echo ""
echo "============================================"
echo " ✅  Image pushed successfully!"
echo " URI: $ECR_URI:latest"
echo "============================================"
echo ""
echo "Now update k8s/deployment.yaml:"
echo "  Replace YOUR_ACCOUNT_ID with: $ACCOUNT_ID"
echo "  Replace YOUR_REGION with: $REGION"
echo ""
echo "Your deployment image line should be:"
echo "  image: $ECR_URI:latest"
echo ""
