pipeline {
    agent any // מאפשר לג'נקינס להריץ את ה-Pipeline

    environment {
        // --- שנה את הפרטים האלו לפי ה-AWS שלך ---
        AWS_ACCOUNT_ID = "123456789012" 
        AWS_REGION     = "us-east-1"
        ECR_REPO       = "calculator-app"
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
        
        // יצירת תגית לפי דרישת המבחן: pr-<id>-build-<number> או latest למאסטר
        IMAGE_TAG = env.CHANGE_ID ? "pr-${env.CHANGE_ID}-build-${env.BUILD_NUMBER}" : "latest"
    }

    stages {
        // שלב 1: בנייה (חלק מ-Part C ו-D)
        stage('Build Image') {
            steps {
                script {
                    sh "docker build -t ${ECR_URL}:${IMAGE_TAG} ."
                }
            }
        }

        // שלב 2: טסטים - חייב לרוץ בתוך Docker Agent לפי המבחן!
        stage('Test') {
            agent {
                docker { 
                    image 'python:3.9-slim' 
                    // מחבר את התיקייה הנוכחית לקונטיינר
                }
            }
            steps {
                sh 'pip install -r requirements.txt'
                sh 'pytest tests/' 
            }
        }

        // שלב 3: דחיפה ל-ECR (חלק מ-Part C ו-D)
        stage('Push to ECR') {
            steps {
                script {
                    // התחברות ל-ECR בעזרת ה-Instance Role (הכי פשוט במבחן)
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"
                    sh "docker push ${ECR_URL}:${IMAGE_TAG}"
                }
            }
        }

        // שלב 4: פריסה - רק כשעושים Merge למאסטר (Part D)
        stage('Deploy to Production') {
            when {
                branch 'master'
            }
            steps {
                // התחברות לשרת הפרודקשן (צריך להחליף ל-IP האמיתי)
                // כאן כדאי להשתמש ב-Credentials ששמרת בג'נקינס
                sh 'echo "Deploying to Production EC2..."'
                /* דוגמה לפקודה (אם הגדרת SSH):
                sh "ssh -o StrictHostKeyChecking=no ec2-user@PROD_IP 'docker pull ${ECR_URL}:${IMAGE_TAG} && docker run -d -p 80:5000 ${ECR_URL}:${IMAGE_TAG}'"
                */
            }
        }

        // שלב 5: בדיקת תקינות (Health Verification - Part D)
        stage('Health Check') {
            when {
                branch 'master'
            }
            steps {
                sh 'sleep 10' // מחכים רגע שהאפליקציה תעלה
                sh 'curl -f http://44.223.6.17:PORT/health || exit 1'
            }
        }
    }

    post {
        always {
            cleanWs() // מנקה את מרחב העבודה בסוף
        }
    }
}
