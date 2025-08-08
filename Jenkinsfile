pipeline {
    agent any

    environment {
        DOCKER_REPO = 'princeshawtz/k8s-pipeline'
    }

    parameters {
        string(name: 'K8S_NAMESPACE', defaultValue: 'default', description: 'Kubernetes namespace to deploy to')
    }

    stages {
        // Optional: Checkout stage (uncomment if needed)
        /*
        stage('Checkout') {
            steps {
                echo "Checking out code from https://github.com/PrinceShawtz/k8s-pipeline.git"
                git url: 'https://github.com/PrinceShawtz/k8s-pipeline.git'
            }
        }
        */

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
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_REPO}:${env.BUILD_ID}
                        docker logout
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying to Kubernetes namespace: ${params.K8S_NAMESPACE}"
                sh """
                    sed 's|__IMAGE__|${DOCKER_REPO}:${env.BUILD_ID}|g; s|__NAMESPACE__|${params.K8S_NAMESPACE}|g' k8s/deployment.yaml | kubectl apply -f -
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully with build ID: ${env.BUILD_ID}"
        }
        failure {
            echo "Pipeline failed."
        }
    }
}
