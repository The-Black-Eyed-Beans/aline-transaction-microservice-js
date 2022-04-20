pipeline {
    agent any

    tools { 
        maven 'Maven 3.8.4' 
    }
    
    environment {
        AWS_ID = credentials("aws.id")
        AWS_DEFAULT_REGION = credentials("deployment.region")
        MICROSERVICE_NAME = "transaction-microservice-js"
        ECS_SERVICE_NAME = "transaction-service-js"
    }

    stages {
        stage ('Initialize') {
            steps {

                // Verify path variables for mvn
                sh '''
                    echo "Preparing to build, test and deploy ${MICROSERVICE_NAME}"
                    echo "PATH = ${PATH}"
                    echo "M2_HOME = ${M2_HOME}"
                ''' 
                sh "docker context use default" 
                sh "aws s3 cp s3://js-env-vars/backend.env ."
                sh "ls -a"
            }
        }
        
        stage('Build') {
            steps {
                sh "git submodule init"
                sh "git submodule update"
                sh "mvn install -Dmaven.test.skip=true"
            }
        }
        stage('Sonar Scan'){
            steps{
                withSonarQubeEnv('SonarQube-Server'){
                    sh 'mvn verify sonar:sonar -Dmaven.test.failure.ignore=true'
                }
            }
        }
        
        stage('Quality Gate'){
            steps{
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Push') {
            steps {
                script {
                    docker.withRegistry("https://${AWS_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com", "ecr:${AWS_DEFAULT_REGION}:jenkins.aws.credentials.js") {
                        def image = docker.build("${MICROSERVICE_NAME}")
                        image.push('latest')
                    } 
                }  
            }
        }

        stage('Deploy'){
            steps {  
                withAWS(credentials: 'js-aws-credentials', region: 'us-west-1') { 
                    sh "docker context use js-ecs"
                    sh "aws ecr get-login-password | docker login --username AWS --password-stdin 086620157175.dkr.ecr.us-west-1.amazonaws.com"
                    sh "docker compose up -d"
                }
            }
        }

        stage ('Update Cluster'){
            steps {
                script{
                    try{
                        withAWS(credentials: 'js-aws-credentials', region: 'us-west-1') { 
                            sh "aws ecs update-service --cluster ECScluster-js --service ${ECS_SERVICE_NAME} --force-new-deployment" 
                            sh "echo 'Updating existing service'"
                        }
                    }catch(exc){
                        sh "echo 'Did not find existing service to update, a new one will be created'"
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh "docker context use default" 
                sh "docker image rm ${MICROSERVICE_NAME}:latest"
                sh 'docker image rm $AWS_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$MICROSERVICE_NAME'
                sh "docker image prune -f"
                sh "mvn clean"
            }
        }
    }
}
