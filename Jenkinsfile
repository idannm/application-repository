pipeline {
    agent any
    stages {
        stage('Login to ECR') {
            steps {
                withCredentials([string(credentialsId: 'aws-secret', variable: 'AWS_SECRET')]) {
                    sh 'aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_SECRET'
                }
            }
        }
    }
}
