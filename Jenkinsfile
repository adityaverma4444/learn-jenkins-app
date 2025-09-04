pipeline {
    agent none

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    npm ci  # as node_modules not a part we use this
                    npm run build
                    ls -la
                '''
            }
        }
        stage('Test'){
            agent any
            steps{
                echo 'Test stage'
                sh 'test -f build/index.html && echo "✅ index.html exists." || echo "❌ index.html not found."'
                sh 'npm test'
            }
        }
    }
}
