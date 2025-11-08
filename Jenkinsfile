pipeline {
    agent any
    options {
        timestamps()
    }

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['develop', 'staging', 'production'],
            description: 'Select deployment environment'
        )
    }

    environment {
        DEPLOY_ENV = "${params.DEPLOY_ENV ?: 'develop'}"
        PACKAGES_DIR = "${WORKSPACE}/../packages"
    }

    stages {
        stage('Display Deployment Info') {
            steps {
                script {
                    echo "Starting deployment to: ${DEPLOY_ENV}"
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "Git Branch: ${env.GIT_BRANCH ?: 'N/A'}"
                }
            }
        }

        stage('Checkout') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    git branch: 'deve', url: 'https://github.com/lamcm58/test_deploy_using_jenkins.git'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    // Debug: Show environment info
                    sh '''
                        echo "=== Environment Debug Info ==="
                        echo "PATH: $PATH"
                        echo "USER: $USER"
                        echo "HOME: $HOME"
                        echo "PWD: $PWD"
                        echo ""
                        echo "=== Checking for Composer ==="
                        which composer || echo "composer not in PATH"
                        ls -la /usr/local/bin/composer 2>/dev/null || echo "/usr/local/bin/composer not found"
                        ls -la /usr/bin/composer 2>/dev/null || echo "/usr/bin/composer not found"
                        ls -la ~/.composer/vendor/bin/composer 2>/dev/null || echo "~/.composer/vendor/bin/composer not found"
                        echo ""
                    '''
                    
                    // Find Composer path
                    def composerPath = sh(
                        script: '''
                            # Try to find composer in common locations
                            if command -v composer &> /dev/null; then
                                command -v composer
                            elif [ -f /usr/local/bin/composer ]; then
                                echo /usr/local/bin/composer
                            elif [ -f /usr/bin/composer ]; then
                                echo /usr/bin/composer
                            elif [ -f ~/.composer/vendor/bin/composer ]; then
                                echo ~/.composer/vendor/bin/composer
                            elif [ -f ~/.config/composer/vendor/bin/composer ]; then
                                echo ~/.config/composer/vendor/bin/composer
                            else
                                # Try to find it using which or whereis
                                which composer 2>/dev/null || whereis -b composer 2>/dev/null | awk '{print $2}' | head -1
                            fi
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (!composerPath || composerPath.isEmpty()) {
                        error("Composer not found. Please ensure Composer is installed and accessible.")
                    }
                    
                    echo "Found Composer at: ${composerPath}"
                    
                    // Verify Composer works
                    sh "${composerPath} --version"
                    
                    // Install dependencies
                    sh "${composerPath} install --no-interaction --prefer-dist --optimize-autoloader"
                }
            }
        }

        stage('Run Tests') {
            steps {
                sh 'php artisan test'
            }
        }

        stage('Create Deployment Package') {
            steps {
                script {
                    // Create timestamp for versioning
                    def timestamp = sh(script: 'date +%Y%m%d_%H%M%S', returnStdout: true).trim()
                    def version = "${BUILD_NUMBER}_${timestamp}"
                    env.DEPLOY_PACKAGE = "laravel-app-${version}.zip"
                    env.DEPLOY_PACKAGE_PATH = "${env.PACKAGES_DIR}/${env.DEPLOY_PACKAGE}"
                    
                    sh '''
                        # Create packages directory outside workspace
                        mkdir -p ${PACKAGES_DIR}
                        
                        # Create deployment package
                        echo "Creating deployment package: ${DEPLOY_PACKAGE}"
                        echo "Package location: ${DEPLOY_PACKAGE_PATH}"
                        
                        # Create zip file outside workspace
                        # Note: vendor directory is included to avoid composer install on server
                        cd ${WORKSPACE}
                        zip -r ${DEPLOY_PACKAGE_PATH} . \
                            -x "*.git*" \
                            -x "*node_modules*" \
                            -x "*tests*" \
                            -x "*.env*" \
                            -x "*storage/logs/*" \
                            -x "*storage/framework/cache/*" \
                            -x "*storage/framework/sessions/*" \
                            -x "*storage/framework/views/*" \
                            -x "*vendor/*/.git*" \
                            -x "*.DS_Store*" \
                            -x "*Jenkinsfile*" \
                            -x "*ansible/*" \
                            -x "../packages/*"
                        
                        echo "Package created: ${DEPLOY_PACKAGE_PATH}"
                        ls -lh ${DEPLOY_PACKAGE_PATH}
                    '''
                }
            }
        }

        stage('Deploy with Ansible') {
            steps {
                script {
                    // Verify deployment package exists
                    if (!env.DEPLOY_PACKAGE_PATH) {
                        error("DEPLOY_PACKAGE_PATH is not set. Please ensure 'Create Deployment Package' stage completed successfully.")
                    }
                    
                    // Verify package file exists
                    def packageExists = sh(
                        script: "test -f ${env.DEPLOY_PACKAGE_PATH}",
                        returnStatus: true
                    ) == 0
                    
                    if (!packageExists) {
                        error("Deployment package not found at: ${env.DEPLOY_PACKAGE_PATH}")
                    }
                    
                    // Use Ansible Vault instead of passing secrets via command line
                    withCredentials([
                        string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASS')
                    ]) {
                        sh '''
                            # Make vault password script executable
                            chmod +x ansible/vault_password.sh
                            
                            # Export vault password for the script to use
                            export ANSIBLE_VAULT_PASSWORD="${VAULT_PASS}"
                            
                            # Debug: Check if password is set (remove in production)
                            echo "Vault password is set: ${ANSIBLE_VAULT_PASSWORD:+YES}"
                            echo "Deployment environment: ${DEPLOY_ENV}"
                            echo "Deployment package: ${DEPLOY_PACKAGE}"
                            echo "Deployment package path: ${DEPLOY_PACKAGE_PATH}"
                            ls -lh ${DEPLOY_PACKAGE_PATH} || echo "Package file not found!"
                            
                            # Run ansible-playbook with vault password and package path
                            ansible-playbook -i ansible/inventory ansible/deploy.yml \
                                --vault-password-file ansible/vault_password.sh \
                                --extra-vars "env=${DEPLOY_ENV} deploy_package=${DEPLOY_PACKAGE} deploy_package_path=${DEPLOY_PACKAGE_PATH}" \
                                --limit ${DEPLOY_ENV}
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Deployment successful to ${DEPLOY_ENV}!"
            // Optional: Clean up package file after successful deployment
            script {
                if (env.DEPLOY_PACKAGE_PATH) {
                    sh "rm -f ${env.DEPLOY_PACKAGE_PATH} || true"
                }
            }
        }
        failure {
            echo "Deployment failed to ${DEPLOY_ENV}!"
        }
        always {
            // Optional: Clean up package file (uncomment if you want to remove after each build)
            script {
                if (env.DEPLOY_PACKAGE_PATH) {
                    sh "rm -f ${env.DEPLOY_PACKAGE_PATH} || true"
                }
            }
        }
    }
}
