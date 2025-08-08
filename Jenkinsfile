pipeline {
    agent any
    
    environment {
        DOCKER_REPO = 'princeshawtz/k8s-pipeline'
    }
    
    parameters {
        string(name: 'K8S_NAMESPACE', defaultValue: 'default', description: 'Kubernetes namespace to deploy to')
    }
    
    stages {
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
                sh '''
                    sed "s|__IMAGE__|${DOCKER_REPO}:${BUILD_ID}|g; s|__NAMESPACE__|${K8S_NAMESPACE}|g" deployment.yaml | kubectl apply -f -
                '''
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed successfully with build ID: ${env.BUILD_ID}"
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
