pipeline {
    agent any

    tools { 
        maven 'Maven 3.8.4' 
    }
    
    environment {
        AWS_ID = credentials("aws.id")
        AWS_DEFAULT_REGION = credentials("deployment.region")
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

                configFileProvider([configFile(fileId: "backend.env", targetLocation: 'env.groovy', variable: 'ENV_CONFIG')]) {
                    load "env.groovy"
                }
            }
        }
        
        stage('Tests') {
            steps {
                sh "git submodule init"
                sh "git submodule update"
                sh "mvn clean test -Dmaven.test.failure.ignore=true"
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

        stage('Build'){
            steps {
                sh "mvn clean package -Dmaven.test.skip=true"
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


        stage('Cleanup') {
            steps {
                sh "docker image rm ${MICROSERVICE_NAME}:latest"
                sh 'docker image rm $AWS_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$MICROSERVICE_NAME'
                sh "docker image ls"
                sh "mvn clean"
            }
        }
    }
}
