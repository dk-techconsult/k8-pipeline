def buildAndPushDockerImage(imageName, dockerfilePath, repositoryName, buildTag) {
    def buildDir = dockerfilePath.substring(0, dockerfilePath.lastIndexOf('/'))
    def fullTag = "${repositoryName}:${imageName}-${buildTag}"

    dir(buildDir) {
        sh "docker build -t ${fullTag} ."
    }

    sh "docker push ${fullTag}"
}

pipeline {
    agent { label 'build-agent' }

    parameters {
        choice(
            name: 'DOCKER_REPO_NAME', 
            choices: ['dktc419/kube'], 
            description: 'Select the full Docker repository name to use'
        )
        choice(
            name: 'DOCKER_CREDENTIAL_ID',
            choices: none,
            description: 'Select Docker credentials to use for login'
        )
    }
}
