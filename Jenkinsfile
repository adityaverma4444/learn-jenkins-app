pipeline {
    agent any

    // ============================================================
    // ENVIRONMENT VARIABLES
    // These are available to all stages in the pipeline
    // ============================================================
    environment {
        NETLIFY_SITE_ID = '782f4c74-bb14-453f-bf73-61240c677ddb'      // Your Netlify site ID (unique identifier)
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')             // Jenkins credential for Netlify (stored securely)
        REACT_APP_VERSION = "1.0.$BUILD_ID"                           // ADDED: Version number using Jenkins build ID
    }

    stages {

        // ============================================================
        // STAGE 1: DOCKER - Build Custom Image
        // ============================================================
        // WHY: Instead of installing tools (netlify-cli, serve) every time,
        //      we build ONE image with everything pre-installed = FASTER builds!
        // ============================================================
        stage('Docker') {
            steps {
                sh 'docker build -t my-playwright .'    // Builds image from Dockerfile in project root
            }
        }

        // ============================================================
        // STAGE 2: BUILD - Compile the React App
        // ============================================================
        // This stage:
        // - Installs npm dependencies (npm ci = clean install for CI/CD)
        // - Builds the production-ready React app
        // - Output goes to /build folder
        // ============================================================
        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'    // Lightweight Node.js image
                    reuseNode true            // Reuse the same workspace (keeps files between stages)
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    npm install               # Install dependencies (faster than npm ci)
                    npm run build             # Creates production build in /build folder
                    ls -la
                '''
            }
        }

        // ============================================================
        // STAGE 3: TESTS - Run Unit Tests and E2E Tests in Parallel
        // ============================================================
        // parallel = both tests run at the SAME TIME (faster!)
        // ============================================================
        stage('Tests') {
            parallel {

                // ------------------------------------------
                // STAGE 3a: Unit Tests (Jest)
                // ------------------------------------------
                // Tests individual functions/components
                // ------------------------------------------
                stage('Unit tests') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                        }
                    }

                    steps {
                        sh '''
                            # test -f build/index.html     # Optional: verify build exists
                            CI=true npm test                # CI=true prevents watch mode (runs once and exits)
                        '''
                    }
                    post {
                        always {
                            junit 'jest-results/junit.xml'  // Publish test results to Jenkins
                        }
                    }
                }

                // ------------------------------------------
                // STAGE 3b: E2E Tests (Playwright) - LOCAL
                // ------------------------------------------
                // Tests the FULL app in a real browser
                // Runs against LOCAL server (not deployed yet)
                // ------------------------------------------
                stage('E2E') {
                    agent {
                        docker {
                            image 'my-playwright'           // CHANGED: Use our custom image (has serve pre-installed)
                            reuseNode true
                        }
                    }

                    steps {
                        sh '''
                            serve -s build &                # Start server in background
                            sleep 10                        # Wait for server to start
                            npx playwright test --reporter=html
                        '''
                    }

                    post {
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Local E2E', reportTitles: '', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }

        // ============================================================
        // STAGE 4: DEPLOY STAGING - Deploy to Test Environment First
        // ============================================================
        // WHY STAGING?
        // - Deploy to a preview/test URL first
        // - Run E2E tests on the DEPLOYED version
        // - If tests pass, THEN deploy to production
        // - This catches bugs BEFORE they hit real users!
        // ============================================================
        stage('Deploy staging') {
            agent {
                docker {
                    image 'my-playwright'       // Custom image has netlify-cli pre-installed
                    reuseNode true
                }
            }

            steps {
                sh '''
                    netlify --version
                    echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"
                    netlify status
                    
                    # Deploy WITHOUT --prod flag = creates a PREVIEW/STAGING URL
                    netlify deploy --dir=build --json > deploy-output.json
                    
                    # Extract the staging URL and EXPORT it so Playwright can use it
                    export CI_ENVIRONMENT_URL=$(node-jq -r '.deploy_url' deploy-output.json)
                    echo "Staging URL: $CI_ENVIRONMENT_URL"
                    
                    # Run E2E tests against the STAGING deployment
                    npx playwright test --reporter=html
                '''
            }

            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Staging E2E', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }

        // ============================================================
        // STAGE 5: DEPLOY PROD - Deploy to Production (Live Site!)
        // ============================================================
        // Only runs AFTER staging tests pass
        // Uses --prod flag = deploys to the REAL live URL
        // Then runs E2E tests on production to verify
        // ============================================================
        stage('Deploy prod') {
            agent {
                docker {
                    image 'my-playwright'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = 'https://inquisitive-tapioca-6bc1d4.netlify.app'    // Your LIVE site URL
            }

            steps {
                sh '''
                    node --version
                    netlify --version
                    echo "Deploying to production. Site ID: $NETLIFY_SITE_ID"
                    netlify status
                    
                    # --prod flag = deploy to PRODUCTION (live site!)
                    netlify deploy --dir=build --prod
                    
                    # Run E2E tests against PRODUCTION to verify deployment
                    npx playwright test --reporter=html
                '''
            }

            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod E2E', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
    }

    // ============================================================
    // POST ACTIONS - Run after ALL stages complete
    // ============================================================
    post {
        success {
            echo '🎉 Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above.'
        }
    }
}
