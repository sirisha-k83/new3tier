pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        // --- SonarQube Variables ---
        SONARQUBE_SERVER = 'Sonar_Server'
        SONAR_PROJECT_KEY = '3-tier-new'
        SONAR_PROJECT_NAME = '3-tier-new'
        DB_HOST = 'mysql-db'
        DB_USER = 'app_user'
        DB_NAME = 'crud_app'
        DB_PASS = 'app_pass123' // Hardcoded password - SECURITY WARNING
        DB_PORT = '3306'
    }

    stages { // Main stages block starts here

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sirisha-k83/new3tier.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                nodejs('NodeJS 22.0.0') {
                    dir('web-tier') {
                        sh 'npm install'
                        sh 'npm run build'
                    }
                    dir('app-tier') {
                        sh 'npm install'
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'Sonar_Scanner'
                    withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_LOGIN_TOKEN')]) {
                        withSonarQubeEnv("${SONARQUBE_SERVER}") {
                            sh """
                                ${scannerHome}/bin/sonar-scanner \\
                                -Dsonar.projectKey=${SONAR_PROJECT_KEY} \\
                                -Dsonar.projectName=${SONAR_PROJECT_NAME} \\
                                -Dsonar.sources=web-tier,app-tier \\
                                -Dsonar.login=${SONAR_LOGIN_TOKEN}
                            """
                        }
                    }
                }
            }
        }

      stage('Quality Gate Check') {
          steps {
              echo "Skipping quality gate check"
                }
        }


        stage('TRIVY FS Scan') {
            steps {
                // Ensure Trivy is installed on the agent
                sh "trivy fs . > trivyfs.txt"
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {

                        // ----------- Build APP-TIER IMAGE -----------
                        sh """
                            docker build -t sirishak83/app-tier:latest ./app-tier
                            docker push sirishak83/app-tier:latest
                        """

                        // ----------- Build WEB-TIER IMAGE -----------
                        sh """
                            docker build -t sirishak83/web-tier:latest ./web-tier
                            docker push sirishak83/web-tier:latest
                        """
                        // ----------- Build NGINX IMAGE -----------
                        sh """
                            docker build -t sirishak83/nginx:latest -f nginx.Dockerfile .
                            docker push sirishak83/nginx:latest
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    // Stop previous stack (if running)
                    sh "docker compose down || true"

                    // Start new stack
                    sh "docker compose up -d"
                }
            }
        } // Deploy stage ends
    } // Main stages block ends here
} // Pipeline block ends here
