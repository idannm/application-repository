pipeline {
    agent any 

    environment {
        // --- שנה כאן את הנתונים שלך ---
        AWS_ACCOUNT_ID = 9923-8254-5251
        AWS_REGION     = us-east-1
        ECR_REPO       = idan-ecr
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
    }

    stages {
        stage('Build Image') {
            steps {
                script {
                    // הגדרת תגית לפי ה-PR או ה-Master
                    def tag = env.CHANGE_ID ? "pr-${env.CHANGE_ID}-build-${env.BUILD_NUMBER}" : "latest"
                    sh "docker build -t ${ECR_URL}:${tag} ."
                }
            }
        }

        stage('Test') {
            // דרישת המבחן: הרצה בתוך קונטיינר
            agent {
                docker { image 'python:3.9-slim' }
            }
            steps {
                sh 'pip install -r requirements.txt'
                sh 'pytest tests/' 
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    def tag = env.CHANGE_ID ? "pr-${env.CHANGE_ID}-build-${env.BUILD_NUMBER}" : "latest"
                    // התחברות ל-ECR
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"
                    sh "docker push ${ECR_URL}:${tag}"
                }
            }
        }

        stage('Deploy') {
            when { branch 'master' } // ירוץ רק אחרי שתעשה Merge למאסטר
            steps {
                sh 'echo "Starting Deployment to Production..."'
                // כאן תכניס את פקודת ה-SSH לשרת השני שלך בהמשך
            }
        }
    }
}
