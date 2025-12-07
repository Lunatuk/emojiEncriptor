pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'go mod tidy'
                sh 'go build -o build/emojiEncriptor'
            }
        }

        stage('Deploy app container') {
            steps {
                sh 'docker-compose -f docker-compose.yml up -d --build app'
            }
        }
    }
}
