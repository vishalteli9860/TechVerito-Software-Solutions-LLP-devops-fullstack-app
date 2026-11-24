pipeline {
    agent any

    environment {
        DOCKER_USER = 'docker2582'
        BACKEND_IMAGE = "${DOCKER_USER}/devops-backend"
        FRONTEND_IMAGE = "${DOCKER_USER}/devops-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
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
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER_FROM_CREDENTIAL', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                    sh 'echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKER_USER_FROM_CREDENTIAL" --password-stdin'
                    sh 'docker build -t $BACKEND_IMAGE:$IMAGE_TAG -t $BACKEND_IMAGE:latest backend'
                    sh 'docker build -t $FRONTEND_IMAGE:$IMAGE_TAG -t $FRONTEND_IMAGE:latest frontend'
                    sh 'docker push $BACKEND_IMAGE:$IMAGE_TAG'
                    sh 'docker push $BACKEND_IMAGE:latest'
                    sh 'docker push $FRONTEND_IMAGE:$IMAGE_TAG'
                    sh 'docker push $FRONTEND_IMAGE:latest'
                }
            }
        }

        stage('Deploy to K3s') {
            steps {
                withCredentials([file(credentialsId: 'k3s-kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
set -e
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
        }

        stage('Verify') {
            steps {
                withCredentials([file(credentialsId: 'k3s-kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
set -e
kubectl get pods,svc,ingress -n employee-app
'''
                }
            }
        }
    }

    post {
        always {
            node {
                sh 'docker logout || true'
            }
        }
    }
}
