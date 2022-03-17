pipeline {
    agent any

    tools { 
        maven 'Maven 3.8.4' 
    }
    
    environment {
        AWS_ID = credentials("aws.id")
        DEPLOYMENT_REGION = credentials("deployment.region")
        MICROSERVICE_NAME = "transaction-microservice-js"
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
            }
        }
        
        stage('Build') {
            steps {
                sh "git submodule init"
                sh "git submodule update"
                sh "mvn clean package -Dmaven.test.skip=true"
            }
        }
        stage('Sonar Scan'){
            steps{
                withSonarQubeEnv('SonarQube-Server'){
                    sh 'mvn verify sonar:sonar'
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
                    docker.withRegistry("https://${AWS_ID}.dkr.ecr.${DEPLOYMENT_REGION}.amazonaws.com", "ecr:${DEPLOYMENT_REGION}:jenkins.aws.credentials.js") {
                        def image = docker.build("${MICROSERVICE_NAME}")
                        image.push('latest')
                    } 
                }  
            }
        }
        stage('Cleanup') {
            steps {
                sh "docker image rm ${MICROSERVICE_NAME}:latest"
                sh 'docker image rm $AWS_ID.dkr.ecr.$DEPLOYMENT_REGION.amazonaws.com/$MICROSERVICE_NAME'
                sh "docker image ls"
                sh "mvn clean"
            }
        }
    }
}
