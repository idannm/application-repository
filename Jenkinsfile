pipeline {
    agent any
    stages {
        stage('Login to ECR') {
            steps {
                withCredentials([string(credentialsId: 'aws-secret', variable: 'AWS_SECRET')]) {
                    sh 'aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_SECRET' 
    agent none
    options {
        skipDefaultCheckout() // נמנע מ-checkout אוטומטי של git כדי לשלוט בזה בעצמנו
        timestamps()
    }

    environment {
        // שם התמונה ב-ECR, ניתן לשנות כפרמטר
        IMAGE_NAME = 'my-app'
        // Branch-specific tag: PR number או commit hash
        IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        // שם פרודקשן host (Parameterizable)
        PROD_HOST = credentials('prod-host-ssh') // Jenkins credential מסוג SSH username/private key
        AWS_CREDENTIALS = 'aws-ecr-creds'        // Jenkins AWS Credentials ID
        ECR_REPO = '123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app'
    }

    stages {

        stage('Checkout') {
            agent { docker { image 'alpine/git' } }
            steps {
                checkout scm
            }
        }

        stage('CI/CD') {
            parallel {

                stage('CI Flow (PR)') {
                    when { expression { !env.BRANCH_NAME.equals('main') } }
                    agent { docker { image 'docker:24-dind' 
                                     args '-v /var/run/docker.sock:/var/run/docker.sock' } }
                    stages {
                        stage('Build Docker Image') {
                            steps {
                                sh """
                                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                                """
                            }
                        }

                        stage('Run Tests') {
                            agent { docker { image "${IMAGE_NAME}:${IMAGE_TAG}" } }
                            steps {
                                sh 'pytest tests/' // או פקודת בדיקות מתאימה לשפה שלך
                            }
                        }

                        stage('Push to ECR') {
                            environment {
                                AWS_DEFAULT_REGION = 'us-east-1'
                            }
                            steps {
                                withAWS(credentials: "${AWS_CREDENTIALS}", region: 'us-east-1') {
                                    sh """
                                    aws ecr get-login-password --region us-east-1 | \
                                    docker login --username AWS --password-stdin ${ECR_REPO}
                                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                                    docker push ${ECR_REPO}:${IMAGE_TAG}
                                    """
                                }
                            }
                        }
                    }
                }

                stage('CD Flow (Main)') {
                    when { branch 'main' }
                    agent { docker { image 'docker:24-dind' 
                                     args '-v /var/run/docker.sock:/var/run/docker.sock' } }
                    stages {
                        stage('Build Docker Image') {
                            steps {
                                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                            }
                        }

                        stage('Run Tests') {
                            agent { docker { image "${IMAGE_NAME}:${IMAGE_TAG}" } }
                            steps {
                                sh 'pytest tests/'
                            }
                        }

                        stage('Push to ECR') {
                            steps {
                                withAWS(credentials: "${AWS_CREDENTIALS}", region: 'us-east-1') {
                                    sh """
                                    aws ecr get-login-password --region us-east-1 | \
                                    docker login --username AWS --password-stdin ${ECR_REPO}
                                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                                    docker push ${ECR_REPO}:${IMAGE_TAG}
                                    """
                                }
                            }
                        }

                        stage('Deploy to Production') {
                            steps {
                                sshagent (credentials: ['prod-host-ssh']) {
                                    sh """
                                    ssh -o StrictHostKeyChecking=no ec2-user@${PROD_HOST} \\
                                    'docker pull ${ECR_REPO}:${IMAGE_TAG} && \\
                                     docker stop my-app || true && \\
                                     docker rm my-app || true && \\
                                     docker run -d --name my-app -p 80:80 ${ECR_REPO}:${IMAGE_TAG}'
                                    """
                                }
                            }
                        }

                        stage('Health Check') {
                            steps {
                                sh """
                                STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://${PROD_HOST})
                                if [ "\$STATUS" -ne 200 ]; then
                                  echo "Health check failed"
                                  exit 1
                                else
                                  echo "Deployment successful"
                                fi
                                """
                            }
                        }
                    }
 6cda1ae (this henkins)
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
 6cda1ae (this henkins)
}
