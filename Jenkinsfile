pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        // --- SonarQube Variables ---
        SONARQUBE_SERVER = 'Sonar_Scanner'   # The server name should match the one configured in Jenkins
        SONAR_PROJECT_KEY = '3-Tier-DevopsShack' # The project key in SonarQube
        SONAR_PROJECT_NAME = '3-tier-devopsshack' # The project name in SonarQube
        DB_HOST = 'mysql-db'           // Docker bridge gateway IP to access MySQL on the host VM when db on host, when db is on docker-compose, use 'mysql-db'
        DB_USER = 'app_user'
        DB_NAME = 'crud_app'
        DB_PASS = 'app_pass123'                 // Hardcoded password
        DB_PORT = '3306'                 // MySQL default port
    }
    stages {

        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/sirisha-k83/3-Tier-AWSweb_project.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                nodejs('NodeJS 22.0.0') {  # Use the NodeJS installation configured in Jenkins, no need to install nginx here
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
                    def scannerHome = tool 'Sonar_Scanner' # The SonarQube scanner installation name in Jenkins
                    
                    withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_LOGIN_TOKEN')]) { # The SonarQube token stored in Jenkins credentials
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
            when { 
                expression { 
                    return false // Forces the stage to be skipped
                }
            }
            steps {
                script {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        }
        stage('TRIVY FS Scan') {
            steps {
                // Ensure Trivy is installed on the agent
                sh "trivy fs . > trivyfs.txt"
            }
        }

        // --- Docker Build & Push ---
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

        // --- Deploy to Container with DB Credentials ---
    stage('Deploy') {
    steps {
        script {
            // Stop previous stack (if running)
            sh "docker compose down || true"

            // Start new stack
            sh "docker compose up -d"
        }
    }
}
}
