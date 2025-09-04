pipeline {
    agent any

    stages {
        stage('Build') {
            agent{
                image 'node:18-alpine'
                reuseNode true
            }
            steps {
                sh'''
                ls -la
                node --version
                npm --version
                npm ci  //as node modules not a part we use this
                npm run build
                ls -la
                '''
            }
        }
    }
}
