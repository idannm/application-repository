pipeline {
    agent none
    stages {
        stage('CI/CD') {
            parallel {
                stage('CI (PR)') {
                    when { changeRequest() }
                    agent { docker { image 'docker:20.10.16' } }
                    stages {
                        stage('Build Image') {
                            steps { sh 'docker build -t my-app:${BRANCH_NAME} .' }
                        }
                        stage('Test') {
                            steps { sh 'echo "Running tests..."' }
                        }
                        stage('Push to ECR') {
                            steps {
