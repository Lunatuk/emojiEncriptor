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

        stage('Publish to Web Server') {
            steps {
                sh 'cp build/emojiEncriptor /var/www/emojiEncriptor/'
            }
        }
    }
}
