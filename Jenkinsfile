pipeline {
    agent any
    options {
        timestamps()
    }

    environment {
        DEPLOY_ENV = "develop"
    }

    stages {
        stage('Checkout') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    git branch: 'deve', url: 'https://github.com/lamcm58/test_deploy_using_jenkins.git'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'composer install --no-interaction --prefer-dist --optimize-autoloader'
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
                    
                    sh '''
                        # Create deployment package
                        echo "📦 Creating deployment package: ${DEPLOY_PACKAGE}"
                        
                        # Exclude unnecessary files from deployment
                        # Note: vendor directory is included to avoid composer install on server
                        zip -r ${DEPLOY_PACKAGE} . \
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
                            -x "*ansible/*"
                        
                        echo "✅ Package created: ${DEPLOY_PACKAGE}"
                        ls -lh ${DEPLOY_PACKAGE}
                    '''
                }
            }
        }

        stage('Deploy with Ansible') {
            steps {
                script {
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
                            echo "🔐 Vault password is set: ${ANSIBLE_VAULT_PASSWORD:+YES}"
                            
                            # Run ansible-playbook with vault password and package path
                            ansible-playbook -i ansible/inventory ansible/deploy.yml \
                                --vault-password-file ansible/vault_password.sh \
                                --extra-vars "env=${DEPLOY_ENV} deploy_package=${DEPLOY_PACKAGE}" \
                                --limit ${DEPLOY_ENV}
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}
