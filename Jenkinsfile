pipeline {
    agent {
        docker {
            // משתמשים באימג' שיש בו דוקר ופייתון (או דוקר רגיל ומתקינים פייתון)
            image 'docker:latest' 
            // קריטי: מאפשר לקונטיינר של ג'נקינס להפעיל פקודות דוקר על המארח
            args '-v /var/run/docker.sock:/var/run/docker.sock -u root'
        }
    }

    environment {
        // הגדרות כלליות
        ECR_REGISTRY = 'YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com' // שנ לכתובת שלך
        REPO_NAME    = 'calculator-app'
        AWS_CREDS_ID = 'aws-credentials' // ה-ID שנתת ב-Jenkins Credentials
        REGION       = 'us-east-1'
        
        // הגדרות לשרת הפרודקשן (לחלק D)
        PROD_IP      = '1.2.3.4' // ה-IP של שרת הפרודקשן
        PROD_USER    = 'ec2-user'
        PROD_SSH_ID  = 'prod-ssh-key' // ה-ID של המפתח הפרטי ב-Jenkins
    }

    stages {
        // שלב 1: בנייה (משותף לכולם)
        stage('Build Image') {
            steps {
                script {
                    // קביעת שם התגית בהתאם לסוג הריצה
                    if (env.CHANGE_ID) {
                        // אם זה PR - תגית עם מספר ה-PR
                        env.IMAGE_TAG = "pr-${env.CHANGE_ID}-${env.BUILD_NUMBER}"
                        echo "Building PR image: ${env.IMAGE_TAG}"
                    } else {
                        // אם זה Master - תגית בילד רגילה
                        env.IMAGE_TAG = "build-${env.BUILD_NUMBER}"
                        echo "Building Production image: ${env.IMAGE_TAG}"
                    }
                    
                    // פקודת הבנייה
                    sh "docker build -t ${ECR_REGISTRY}/${REPO_NAME}:${env.IMAGE_TAG} ."
                }
            }
        }

        // שלב 2: טסטים (משותף לכולם)
        stage('Test') {
            steps {
                script {
                    echo "Running tests on image..."
                    // מריץ קונטיינר זמני, מפעיל pytest, ומוחק אותו בסוף
                    // וודא שב-Dockerfile שלך מותקן pytest
                    sh "docker run --rm ${ECR_REGISTRY}/${REPO_NAME}:${env.IMAGE_TAG} python -m pytest"
                }
            }
        }

        // שלב 3: דחיפה ל-ECR (משותף לכולם)
        stage('Push to ECR') {
            steps {
                script {
                    // התחברות ל-AWS ודחיפת האימג'
                    withCredentials([usernamePassword(credentialsId: env.AWS_CREDS_ID, passwordVariable: 'AWS_SECRET', usernameVariable: 'AWS_KEY')]) {
                        sh "export AWS_ACCESS_KEY_ID=$AWS_KEY"
                        sh "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET"
                        sh "export AWS_DEFAULT_REGION=${REGION}"
                        
                        // Login to ECR
                        sh "aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                        
                        // Push
                        sh "docker push ${ECR_REGISTRY}/${REPO_NAME}:${env.IMAGE_TAG}"
                        
                        // אם זה Master, נדחוף גם תגית 'latest' שיהיה קל לפרוס
                        if (env.BRANCH_NAME == 'master') {
                            sh "docker tag ${ECR_REGISTRY}/${REPO_NAME}:${env.IMAGE_TAG} ${ECR_REGISTRY}/${REPO_NAME}:latest"
                            sh "docker push ${ECR_REGISTRY}/${REPO_NAME}:latest"
                        }
                    }
                }
            }
        }

        // שלב 4: פריסה לפרודקשן (רץ רק ב-Master!!)
        stage('Deploy to Production') {
            when {
                branch 'master' // התנאי שמבדיל בין CI ל-CD
            }
            steps {
                sshagent([env.PROD_SSH_ID]) {
                    script {
                        def dockerCmd = "docker run -d -p 80:5000 --name app ${ECR_REGISTRY}/${REPO_NAME}:latest"
                        
                        sh """
                        ssh -o StrictHostKeyChecking=no ${PROD_USER}@${PROD_IP} '
                            # 1. Login to ECR on Prod Server
                            aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            
                            # 2. Pull latest image
                            docker pull ${ECR_REGISTRY}/${REPO_NAME}:latest
                            
                            # 3. Stop and remove old container (if exists)
                            docker stop app || true
                            docker rm app || true
                            
                            # 4. Run new container
                            ${dockerCmd}
                        '
                        """
                    }
                }
            }
        }

        // שלב 5: בדיקת תקינות (רץ רק ב-Master!!)
        stage('Health Verification') {
            when {
                branch 'master'
            }
            steps {
                script {
                    // נותנים לאפליקציה כמה שניות לעלות
                    sleep 10 
                    
                    // בודקים שהשרת מחזיר תשובה (למשל סטטוס 200)
                    // הנחה: יש ראוט /health או / באפליקציה
                    sh "curl -f http://${PROD_IP}:80/" 
                }
            }
        }
    }
    
    post {
        always {
            // ניקוי האימג'ים מג'נקינס כדי לא לסתום את הדיסק
            sh "docker rmi ${ECR_REGISTRY}/${REPO_NAME}:${env.IMAGE_TAG} || true"
        }
    }
}
