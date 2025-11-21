        pipeline {
    // 1. Agent: Use a specific label for better control, or keep 'any' if generic is fine.
    agent any

    triggers {
        // Triggers the pipeline on every push to the GitHub repository.
        githubPush()
    }

    environment {
        // --- SonarQube Variables ---
        SONARQUBE_SERVER = 'Sonar_Server'
        SONAR_PROJECT_KEY = '3-tier-new'
        SONAR_PROJECT_NAME = '3-tier-new'
        
        // --- Database Variables (NON-SECRET) ---
        DB_HOST = 'mysql-db'
        DB_USER = 'app_user'
        DB_NAME = 'crud_app'
        DB_PASS = 'app_pass123'
        DB_PORT = '3306'

        // --- Docker Registry Variables ---
        // Define repository name as a variable for consistency
        DOCKER_REPOSITORY = 'sirishak83'
    }

    stages {
        
        stage('Checkout') {
            steps {
                // Ensure the correct Git plugin syntax is used
                git branch: 'main', url: 'https://github.com/sirisha-k83/new3tier.git'
            }
        }

        stage('Install Dependencies & Build') {
            // Using a `node` tool block in steps is correct for running JS/Node commands.
            steps {
                nodejs('NodeJS 22.0.0') {
                    // Install and Build Web-tier
                    dir('web-tier') {
                        sh 'npm install'
                        // Assuming 'npm run build' generates production assets
                        sh 'npm run build'
                    }
                    // Install App-tier dependencies
                    dir('app-tier') {
                        sh 'npm install'
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    // Use a more modern and simplified approach for SonarQube Scanner setup
                    // The 'tool' step is wrapped in the Jenkins SonarQube plugin's context
                    def scannerHome = tool 'Sonar_Scanner'
                    
                    // Securely pass the SonarQube token using the withCredentials block
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
                // Run Trivy File System scan and output to a file
                sh "trivy fs . > trivyfs.txt"
                // Optional: Archive the report for later inspection
                archiveArtifacts artifacts: 'trivyfs.txt', onlyIfSuccessful: true
            }
        }
        
       stage('Docker Build & Push') {
    steps {
        script {
            // Use withDockerRegistry for authentication to the Docker registry (e.g., Docker Hub)
            withDockerRegistry(credentialsId: 'docker', url: '') {
                
                // Define a common tag (e.g., current build number) for versioning
                def tag = "${env.BUILD_NUMBER}"
                def repo = "${DOCKER_REPOSITORY}" // Use a short variable for clarity

                // --- BUILD AND PUSH APP-TIER IMAGE ---
                sh "docker build -t ${repo}/app-tier:${tag} ./app-tier"
                sh "docker tag ${repo}/app-tier:${tag} ${repo}/app-tier:latest" // Tag as latest
                sh "docker push ${repo}/app-tier:${tag}"
                sh "docker push ${repo}/app-tier:latest" // PUSH latest (making it available immediately)

              // --- BUILD AND PUSH WEB-TIER IMAGE ---
                sh "docker build -t ${repo}/web-tier:${tag} ./web-tier"
                sh "docker tag ${repo}/web-tier:${tag} ${repo}/web-tier:latest"
                sh "docker push ${repo}/web-tier:${tag}"
                 sh "docker push ${repo}/web-tier:latest"

               // --- BUILD AND PUSH NGINX IMAGE ---
                sh "docker build -t ${repo}/nginx:${tag} -f web-tier/Dockerfile web-tier"
                sh "docker tag ${repo}/nginx:${tag} ${repo}/nginx:latest"
                sh "docker push ${repo}/nginx:${tag}"
                sh "docker push ${repo}/nginx:latest"
            }
        }
    }
}
        
        stage('Deploy') {
           steps {
               script {
             // Hardcoded password for testing
                dir("${env.WORKSPACE}") {   // ensures we are in the repo folder
                sh """
                    docker compose down || true
                    DB_PASS=${DB_PASS} docker compose up -d
                """
            }
        }
    }
}
}
        }
