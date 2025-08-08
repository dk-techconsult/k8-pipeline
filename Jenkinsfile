pipeline {
    agent any
    
    environment {
        DOCKER_REPO = 'princeshawtz/k8s-pipeline'
    }
    
    parameters {
        string(name: 'K8S_NAMESPACE', defaultValue: 'default', description: 'Kubernetes namespace to deploy to')
    }
    
    stages {
        stage('Install kubectl') {
            steps {
                script {
                    // Check if kubectl exists, install if not
                    def kubectlExists = sh(script: 'which kubectl', returnStatus: true) == 0
                    if (!kubectlExists) {
                        echo "Installing kubectl..."
                        sh '''
                            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                            chmod +x kubectl
                            sudo mv kubectl /usr/local/bin/ || mv kubectl /tmp/kubectl
                            export PATH="/tmp:$PATH"
                        '''
                    } else {
                        echo "kubectl already installed"
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    env.BUILD_ID = new Date().format('yyyyMMdd-HHmmss')
                    echo "Building Docker image: ${DOCKER_REPO}:${env.BUILD_ID}"
                    sh "docker build -t ${DOCKER_REPO}:${env.BUILD_ID} ."
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                echo "Pushing Docker image to Docker Hub"
                withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_REPO}:${BUILD_ID}
                        docker logout
                    '''
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying to Kubernetes namespace: ${params.K8S_NAMESPACE}"
                script {
                    // Check if deployment file exists
                    if (fileExists('deployment.yaml')) {
                        sh '''
                            # Add /tmp to PATH if kubectl was installed there
                            export PATH="/tmp:$PATH"
                            
                            # Apply the deployment
                            sed "s|__IMAGE__|${DOCKER_REPO}:${BUILD_ID}|g; s|__NAMESPACE__|${K8S_NAMESPACE}|g" k8s/deployment.yaml | kubectl apply -f -
                            
                            # Check deployment status
                            kubectl rollout status deployment/k8s-pipeline-app -n ${K8S_NAMESPACE}
                        '''
                    } else {
                        error "Deployment file deployment.yaml not found!"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed successfully with build ID: ${env.BUILD_ID}"
            echo "Application deployed to Kubernetes namespace: ${params.K8S_NAMESPACE}"
            // Clean up local Docker image to save space
            sh "docker rmi ${DOCKER_REPO}:${env.BUILD_ID} || true"
        }
        failure {
            echo "Pipeline failed."
            // Clean up local Docker image on failure too
            sh "docker rmi ${DOCKER_REPO}:${env.BUILD_ID} || true"
        }
        always {
            // Cleanup any dangling images
            sh "docker system prune -f || true"
        }
    }
}
