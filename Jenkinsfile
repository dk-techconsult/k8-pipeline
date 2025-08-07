pipeline {
    agent any

    environment {
        DOCKER_REPO = 'princeshawtz/k8s-pipeline'
        BUILD_ID = "${new Date().format('yyyyMMdd-HHmmss')}"
    }

    parameters {
        string(name: 'K8S_NAMESPACE', defaultValue: 'default', description: 'Kubernetes namespace to deploy to')
    }

    stages {
        //stage('Checkout') {
            //steps {
                //echo "Checking out code from https://github.com/PrinceShawtz/k8s-pipeline.git"
               // git url: 'https://github.com/PrinceShawtz/k8s-pipeline.git'
           // }
        //}

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${DOCKER_REPO}:${BUILD_ID}"
                script {
                    docker.build("${DOCKER_REPO}:${BUILD_ID}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "Pushing Docker image to Docker Hub"
                script {
                    docker.withRegistry('', 'docker-hub') {
                        docker.image("${DOCKER_REPO}:${BUILD_ID}").push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying to Kubernetes namespace: ${params.K8S_NAMESPACE}"
                sh """
                    sed 's|__IMAGE__|${DOCKER_REPO}:${BUILD_ID}|g; s|__NAMESPACE__|${params.K8S_NAMESPACE}|g' k8s/deployment.yaml | kubectl apply -f -
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully with build ID: ${BUILD_ID}"
        }
        failure {
            echo "Pipeline failed."
        }
    }
}
