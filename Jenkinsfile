pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_USER = 'docker2582'
        BACKEND_IMAGE = "${DOCKER_USER}/devops-backend"
        FRONTEND_IMAGE = "${DOCKER_USER}/devops-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        KUBECONFIG = credentials('k3s-kubeconfig')
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Test') {
            parallel {
                stage('Backend') {
                    steps {
                        dir('backend') {
                            sh 'go test ./...'
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        dir('frontend') {
                            sh 'npm ci'
                            sh 'CI=true npm test -- --watchAll=false --passWithNoTests'
                            sh 'npm run build'
                        }
                    }
                }
            }
        }

        stage('Build and Push Images') {
            steps {
                sh 'echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin'
                sh 'docker build -t $BACKEND_IMAGE:$IMAGE_TAG -t $BACKEND_IMAGE:latest backend'
                sh 'docker build -t $FRONTEND_IMAGE:$IMAGE_TAG -t $FRONTEND_IMAGE:latest frontend'
                sh 'docker push $BACKEND_IMAGE:$IMAGE_TAG'
                sh 'docker push $BACKEND_IMAGE:latest'
                sh 'docker push $FRONTEND_IMAGE:$IMAGE_TAG'
                sh 'docker push $FRONTEND_IMAGE:latest'
            }
        }

        stage('Deploy to K3s') {
            steps {
                sh '''
set -e
export KUBECONFIG="$KUBECONFIG"
mkdir -p target-k8s
cp k8s/*.yaml target-k8s/
sed -i "s|REPLACE_DOCKER_USER|$DOCKER_USER|g" target-k8s/20-backend.yaml target-k8s/21-frontend.yaml
sed -i "s|:latest|:$IMAGE_TAG|g" target-k8s/20-backend.yaml target-k8s/21-frontend.yaml
kubectl apply -f target-k8s/
kubectl rollout status deployment/backend -n employee-app --timeout=5m
kubectl rollout status deployment/frontend -n employee-app --timeout=5m
'''
            }
        }

        stage('Verify') {
            steps {
                sh '''
export KUBECONFIG="$KUBECONFIG"
kubectl get pods,svc,ingress -n employee-app
'''
            }
        }
    }

    post {
        always { sh 'docker logout || true' }
    }
}
