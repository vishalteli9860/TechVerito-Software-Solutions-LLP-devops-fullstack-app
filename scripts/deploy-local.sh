#!/bin/bash
set -euo pipefail

DOCKER_USER="${DOCKER_USER:?Set DOCKER_USER}"
TAG="${TAG:-latest}"

docker build -t "$DOCKER_USER/devops-backend:$TAG" backend
docker build -t "$DOCKER_USER/devops-frontend:$TAG" frontend
docker push "$DOCKER_USER/devops-backend:$TAG"
docker push "$DOCKER_USER/devops-frontend:$TAG"

rm -rf target-k8s
mkdir target-k8s
cp k8s/*.yaml target-k8s/
sed -i "s|REPLACE_DOCKER_USER|$DOCKER_USER|g" target-k8s/20-backend.yaml target-k8s/21-frontend.yaml
sed -i "s|:latest|:$TAG|g" target-k8s/20-backend.yaml target-k8s/21-frontend.yaml
kubectl apply -f target-k8s/
kubectl rollout status deployment/backend -n employee-app --timeout=5m
kubectl rollout status deployment/frontend -n employee-app --timeout=5m
kubectl get pods,svc,ingress -n employee-app
