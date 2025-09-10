#!/bin/bash

# Script to build and push Docker images with linux/amd64 platform support

set -e

# Configuration
AWS_REGION=${AWS_REGION:-"us-east-1"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Docker build and push process...${NC}"

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$ACCOUNT_ID" ]; then
    echo -e "${RED}Failed to get AWS account ID. Make sure you're logged in to AWS.${NC}"
    exit 1
fi

ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Login to ECR
echo -e "${YELLOW}Logging in to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}

# Function to build and push image
build_and_push() {
    local REPOSITORY_NAME=$1
    local DOCKERFILE_PATH=$2
    local CONTEXT_PATH=$3
    
    echo -e "${GREEN}Building ${REPOSITORY_NAME}...${NC}"
    
    # Check if repository exists, create if it doesn't
    if ! aws ecr describe-repositories --repository-names "${REPOSITORY_NAME}-${ENVIRONMENT}" --region ${AWS_REGION} >/dev/null 2>&1; then
        echo -e "${YELLOW}Creating ECR repository ${REPOSITORY_NAME}-${ENVIRONMENT}...${NC}"
        aws ecr create-repository --repository-name "${REPOSITORY_NAME}-${ENVIRONMENT}" --region ${AWS_REGION}
    fi
    
    FULL_IMAGE_URI="${ECR_URI}/${REPOSITORY_NAME}-${ENVIRONMENT}:${IMAGE_TAG}"
    
    # Build with explicit platform specification for AMD64
    echo -e "${YELLOW}Building image for linux/amd64 platform...${NC}"
    
    # Check if buildx is available
    if docker buildx version >/dev/null 2>&1; then
        # Use buildx for cross-platform build
        docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder
        docker buildx build \
            --platform linux/amd64 \
            -t ${FULL_IMAGE_URI} \
            -f ${DOCKERFILE_PATH} \
            --push \
            ${CONTEXT_PATH}
    else
        # Fallback to regular docker build with platform flag
        docker build \
            --platform linux/amd64 \
            -t ${FULL_IMAGE_URI} \
            -f ${DOCKERFILE_PATH} \
            ${CONTEXT_PATH}
        
        # Push the image
        echo -e "${YELLOW}Pushing image to ECR...${NC}"
        docker push ${FULL_IMAGE_URI}
    fi
    
    echo -e "${GREEN}Successfully pushed ${FULL_IMAGE_URI}${NC}"
}

# Build and push FFavors API
if [ -d "../../ffavorsapi" ]; then
    echo -e "${GREEN}Building FFavors API...${NC}"
    build_and_push "ffavorsapi" "../../ffavorsapi/Dockerfile" "../../ffavorsapi"
else
    echo -e "${YELLOW}FFavors API directory not found at ../../ffavorsapi${NC}"
fi

# Build and push Telerik Report Generator (if it has a Dockerfile)
if [ -f "../src/ReportGenerator/Dockerfile" ]; then
    echo -e "${GREEN}Building Telerik Report Generator...${NC}"
    build_and_push "telerik-report-generator" "../src/ReportGenerator/Dockerfile" "../src/ReportGenerator"
elif [ -f "../Dockerfile.ReportGenerator" ]; then
    echo -e "${GREEN}Building Telerik Report Generator...${NC}"
    build_and_push "telerik-report-generator" "../Dockerfile.ReportGenerator" "../"
else
    echo -e "${YELLOW}Telerik Report Generator Dockerfile not found${NC}"
    echo -e "${YELLOW}Please ensure you have a Dockerfile for the Report Generator Lambda function${NC}"
fi

echo -e "${GREEN}Docker build and push process completed!${NC}"

# Verify the images
echo -e "${YELLOW}Verifying pushed images...${NC}"
aws ecr describe-images --repository-name "ffavorsapi-${ENVIRONMENT}" --region ${AWS_REGION} --query 'imageDetails[?imageTags[?contains(@, `'${IMAGE_TAG}'`) == `true`]].[imageTags[0], imagePushedAt, imageScanStatus.status, registryId, repositoryName]' --output table

if aws ecr describe-repositories --repository-names "telerik-report-generator-${ENVIRONMENT}" --region ${AWS_REGION} >/dev/null 2>&1; then
    aws ecr describe-images --repository-name "telerik-report-generator-${ENVIRONMENT}" --region ${AWS_REGION} --query 'imageDetails[?imageTags[?contains(@, `'${IMAGE_TAG}'`) == `true`]].[imageTags[0], imagePushedAt, imageScanStatus.status, registryId, repositoryName]' --output table
fi

echo -e "${GREEN}All done! You can now run 'terraform apply' to deploy with the new images.${NC}"