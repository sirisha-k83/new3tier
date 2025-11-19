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
        // DB_PASS is moved to a withCredentials block for security
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
                        
                        // --- Build and Push APP-TIER IMAGE ---
                        sh "docker build -t ${DOCKER_REPOSITORY}/app-tier:${tag} ./app-tier"
                        sh "docker push ${DOCKER_REPOSITORY}/app-tier:${tag}"

                        // --- Build and Push WEB-TIER IMAGE ---
                        sh "docker build -t ${DOCKER_REPOSITORY}/web-tier:${tag} ./web-tier"
                        sh "docker push ${DOCKER_REPOSITORY}/web-tier:${tag}"

                        // --- Build and Push NGINX IMAGE ---
                        sh "docker build -t ${DOCKER_REPOSITORY}/nginx:${tag} -f nginx.Dockerfile ."
                        sh "docker push ${DOCKER_REPOSITORY}/nginx:${tag}"
                        
                        // Optional: Tag and push as 'latest' as well
                        sh "docker tag ${DOCKER_REPOSITORY}/app-tier:${tag} ${DOCKER_REPOSITORY}/app-tier:latest"
                        sh "docker push ${DOCKER_REPOSITORY}/app-tier:latest"
                        sh "docker tag ${DOCKER_REPOSITORY}/web-tier:${tag} ${DOCKER_REPOSITORY}/web-tier:latest"
                        sh "docker push ${DOCKER_REPOSITORY}/web-tier:latest"
                        sh "docker tag ${DOCKER_REPOSITORY}/nginx:${tag} ${DOCKER_REPOSITORY}/nginx:latest"
                        sh "docker push ${DOCKER_REPOSITORY}/nginx:latest"
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    // 2. Security Fix: Use withCredentials to securely inject the DB_PASS for deployment
                    withCredentials([string(credentialsId: 'DB_PASS_CREDENTIAL_ID', variable: 'SECURE_DB_PASS')]) {
                        
                        // Set the secure password as an environment variable for the compose command scope
                        // Note: This requires the docker-compose file to use the DB_PASS variable.
                        sh """
                            # Stop previous stack (if running)
                            docker compose down || true
                            
                            # Start new stack with secure password
                            DB_PASS=${SECURE_DB_PASS} docker compose up -d
                        """
                        // Alternative: Use a deployment tool (e.g., kubectl apply for Kubernetes) if this is an orchestrator-based deployment
                    }
                }
            }
        }
    }
}
