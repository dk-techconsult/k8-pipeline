def buildAndPushDockerImage(imageName, dockerfilePath, repositoryName, buildTag) {
    def buildDir = dockerfilePath.substring(0, dockerfilePath.lastIndexOf('/'))
    def fullTag = "${repositoryName}:${imageName}-${buildTag}"

    dir(buildDir) {
        sh "docker build -t ${fullTag} ."
    }

    sh "docker push ${fullTag}"
}

pipeline {
    agent any
    
    environment {
        DOCKER_REPO = 'dktc419/kube'
    }
    
    parameters {
        string(name: 'K8S_NAMESPACE', defaultValue: 'default', description: 'Kubernetes namespace to deploy to')
        choice(
            name: 'DOCKER_CREDENTIAL_ID',
            choices: ['docker-hub', 'docker-credentials', 'docker-access-token'],
            description: 'Select Docker credentials to use for login'
        )
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
                    env.buildTag = env.BUILD_ID  // Set buildTag for the function
                    
                    echo "Building Docker image: ${DOCKER_REPO}:${env.BUILD_ID}"
                    sh "docker build -t ${DOCKER_REPO}:${env.BUILD_ID} ."
                    sh "docker tag ${DOCKER_REPO}:${env.BUILD_ID} ${DOCKER_REPO}:latest"
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                echo "Pushing Docker image to Docker Hub"
                withCredentials([usernamePassword(credentialsId: params.DOCKER_CREDENTIAL_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_REPO}:${BUILD_ID}
                        docker push ${DOCKER_REPO}:latest
                        docker logout
                    '''
                }
            }
        }
        
        stage('Load Image to Kind') {
            steps {
                echo "Loading Docker image into Kind cluster"
                sh '''
                    # Load the image into Kind cluster
                    kind load docker-image ${DOCKER_REPO}:latest --name kind
                    
                    # Verify image is loaded
                    docker exec kind-control-plane crictl images | grep ${DOCKER_REPO} || echo "Image may not be visible via crictl"
                '''
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying to Kubernetes namespace: ${params.K8S_NAMESPACE}"
                script {
                    // Check if deployment file exists in root directory
                    if (fileExists('deployment.yaml')) {
                        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                            sh '''
                                # Set up kubectl path and config
                                export PATH="/tmp:$PATH"
                                export KUBECONFIG=${KUBECONFIG}
                                
                                # Test cluster connection with timeout
                                echo "Testing Kind cluster connection..."
                                if timeout 30s kubectl cluster-info; then
                                    echo "✅ Kind cluster is accessible!"
                                    
                                    # Show current context
                                    kubectl config current-context
                                    
                                    # Create namespace if it doesn't exist
                                    kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                                    
                                    # Apply the deployment (use latest tag for Kind)
                                    echo "Applying deployment to Kind cluster..."
                                    sed "s|__IMAGE__|${DOCKER_REPO}:latest|g; s|__NAMESPACE__|${K8S_NAMESPACE}|g" deployment.yaml | kubectl apply -f -
                                    
                                    # Wait for deployment to be ready
                                    echo "Waiting for deployment to be ready..."
                                    kubectl wait --for=condition=available --timeout=300s deployment/k8s-pipeline-app -n ${K8S_NAMESPACE}
                                    
                                    # Show deployment status
                                    echo "Deployment successful! Current status:"
                                    kubectl get deployments,pods,services -n ${K8S_NAMESPACE} -l app=k8s-pipeline-app
                                    
                                    # Get service info
                                    echo "Service details:"
                                    kubectl describe service k8s-pipeline-service -n ${K8S_NAMESPACE} || echo "Service not found"
                                    
                                    # Show how to access the application locally (Kind specific)
                                    echo ""
                                    echo "🚀 Application deployed successfully!"
                                    echo "📝 To access your app locally with Kind:"
                                    echo "   kubectl port-forward service/k8s-pipeline-service 8282:80 -n ${K8S_NAMESPACE}"
                                    echo "   Then visit: http://localhost:8282"
                                    
                                else
                                    echo "❌ Cannot connect to Kind cluster"
                                    echo "🔧 Make sure Kind cluster is running: kind get clusters"
                                    echo "📦 Docker image was still built: ${DOCKER_REPO}:latest"
                                    currentBuild.result = 'UNSTABLE'
                                fi
                            '''
                        }
                    } else {
                        error "Deployment file deployment.yaml not found in root directory!"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline completed successfully!"
            echo "🐳 Docker image: ${DOCKER_REPO}:${env.BUILD_ID}"
            echo "☸️  Deployed to Kind cluster in namespace: ${params.K8S_NAMESPACE}"
            echo "🔗 Docker Hub: https://hub.docker.com/r/dktc419/kube/tags"
            echo ""
            echo "💡 Next steps:"
            echo "   • Test your app: kubectl port-forward service/k8s-pipeline-service 8282:80 -n ${params.K8S_NAMESPACE}"
            echo "   • View logs: kubectl logs -l app=k8s-pipeline-app -n ${params.K8S_NAMESPACE}"
            echo "   • Scale up: kubectl scale deployment k8s-pipeline-app --replicas=3 -n ${params.K8S_NAMESPACE}"
            
            // Clean up local Docker image to save space
            sh "docker rmi ${DOCKER_REPO}:${env.BUILD_ID} || true"
        }
        failure {
            echo "❌ Pipeline failed."
            sh "docker rmi ${DOCKER_REPO}:${env.BUILD_ID} || true"
        }
        always {
            sh "docker system prune -f || true"
        }
    }
}
