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
                    // Find PHP path
                    def phpPath = sh(
                        script: '''
                            # Try to find PHP in common locations
                            if command -v php &> /dev/null; then
                                command -v php
                            elif [ -f /usr/local/bin/php ]; then
                                echo /usr/local/bin/php
                            elif [ -f /usr/bin/php ]; then
                                echo /usr/bin/php
                            elif [ -f /opt/homebrew/bin/php ]; then
                                echo /opt/homebrew/bin/php
                            elif [ -f /usr/local/opt/php@8.2/bin/php ]; then
                                echo /usr/local/opt/php@8.2/bin/php
                            else
                                # Try to find it using which or whereis
                                which php 2>/dev/null || whereis -b php 2>/dev/null | awk '{print $2}' | head -1
                            fi
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (!phpPath || phpPath.isEmpty()) {
                        error("PHP not found. Please ensure PHP is installed and accessible.")
                    }
                    
                    echo "Found PHP at: ${phpPath}"
                    sh "${phpPath} --version"
                    
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
                    
                    // Update PATH to include /usr/local/bin and other common locations
                    def updatedPath = "/usr/local/bin:/opt/homebrew/bin:/usr/local/opt/php@8.2/bin:${env.PATH}"
                    
                    // Verify Composer works with updated PATH
                    sh """
                        export PATH="${updatedPath}"
                        ${composerPath} --version
                    """
                    
                    // Install dependencies with updated PATH
                    sh """
                        export PATH="${updatedPath}"
                        ${composerPath} install --no-interaction --prefer-dist --optimize-autoloader
                    """
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    // Find PHP path (same as in Install Dependencies)
                    def phpPath = sh(
                        script: '''
                            if command -v php &> /dev/null; then
                                command -v php
                            elif [ -f /usr/local/bin/php ]; then
                                echo /usr/local/bin/php
                            elif [ -f /usr/bin/php ]; then
                                echo /usr/bin/php
                            elif [ -f /opt/homebrew/bin/php ]; then
                                echo /opt/homebrew/bin/php
                            elif [ -f /usr/local/opt/php@8.2/bin/php ]; then
                                echo /usr/local/opt/php@8.2/bin/php
                            else
                                which php 2>/dev/null || whereis -b php 2>/dev/null | awk '{print $2}' | head -1
                            fi
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (!phpPath || phpPath.isEmpty()) {
                        error("PHP not found. Please ensure PHP is installed and accessible.")
                    }
                    
                    // Update PATH
                    def updatedPath = "/usr/local/bin:/opt/homebrew/bin:${env.PATH}"
                    
                    // Run tests with updated PATH
                    sh """
                        export PATH="${updatedPath}"
                        ${phpPath} artisan test
                    """
                }
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
                    // Find ansible-playbook path
                    def ansiblePlaybookPath = sh(
                        script: '''
                            # Try to find ansible-playbook in common locations
                            if command -v ansible-playbook &> /dev/null; then
                                command -v ansible-playbook
                            elif [ -f /usr/local/bin/ansible-playbook ]; then
                                echo /usr/local/bin/ansible-playbook
                            elif [ -f /usr/bin/ansible-playbook ]; then
                                echo /usr/bin/ansible-playbook
                            elif [ -f /opt/homebrew/bin/ansible-playbook ]; then
                                echo /opt/homebrew/bin/ansible-playbook
                            elif [ -f ~/.local/bin/ansible-playbook ]; then
                                echo ~/.local/bin/ansible-playbook
                            else
                                # Try to find it using which or whereis
                                which ansible-playbook 2>/dev/null || whereis -b ansible-playbook 2>/dev/null | awk '{print $2}' | head -1
                            fi
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (!ansiblePlaybookPath || ansiblePlaybookPath.isEmpty()) {
                        error("ansible-playbook not found. Please ensure Ansible is installed. You can install it with: pip3 install ansible")
                    }
                    
                    echo "Found ansible-playbook at: ${ansiblePlaybookPath}"
                    
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
                    
                    // Update PATH to include common locations
                    def updatedPath = "/usr/local/bin:/opt/homebrew/bin:/usr/local/opt/php@8.2/bin:~/.local/bin:${env.PATH}"
                    
                    // Store ansible-playbook path in environment variable for shell script
                    env.ANSIBLE_PLAYBOOK_PATH = ansiblePlaybookPath
                    
                    // Use Ansible Vault instead of passing secrets via command line
                    withCredentials([
                        string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASS')
                    ]) {
                        sh """
                            export PATH="${updatedPath}"
                            
                            # Make vault password script executable
                            chmod +x ansible/vault_password.sh
                            
                            # Export vault password for the script to use
                            export ANSIBLE_VAULT_PASSWORD="${VAULT_PASS}"
                            
                            # Debug: Check if password is set (remove in production)
                            echo "Vault password is set: \${ANSIBLE_VAULT_PASSWORD:+YES}"
                            echo "Deployment environment: ${DEPLOY_ENV}"
                            echo "Deployment package: ${env.DEPLOY_PACKAGE}"
                            echo "Deployment package path: ${env.DEPLOY_PACKAGE_PATH}"
                            echo "Ansible-playbook path: ${env.ANSIBLE_PLAYBOOK_PATH}"
                            ls -lh ${env.DEPLOY_PACKAGE_PATH} || echo "Package file not found!"
                            
                            # Verify ansible-playbook path is set
                            if [ -z "${env.ANSIBLE_PLAYBOOK_PATH}" ]; then
                                echo "ERROR: ansible-playbook path is empty!"
                                exit 1
                            fi
                            
                            # Verify ansible-playbook exists and is executable
                            if [ ! -f "${env.ANSIBLE_PLAYBOOK_PATH}" ]; then
                                # If not a file, check if it's a command in PATH
                                if ! command -v "${env.ANSIBLE_PLAYBOOK_PATH}" &> /dev/null; then
                                    echo "ERROR: ansible-playbook not found at: ${env.ANSIBLE_PLAYBOOK_PATH}"
                                    exit 1
                                fi
                            fi
                            
                            # Test ansible-playbook command
                            "${env.ANSIBLE_PLAYBOOK_PATH}" --version || {
                                echo "ERROR: ansible-playbook command failed!"
                                exit 1
                            }
                            
                            # Run ansible-playbook with vault password and package path
                            "${env.ANSIBLE_PLAYBOOK_PATH}" -i ansible/inventory ansible/deploy.yml \\
                                --vault-password-file ansible/vault_password.sh \\
                                --extra-vars "env=${DEPLOY_ENV} deploy_package=${env.DEPLOY_PACKAGE} deploy_package_path=${env.DEPLOY_PACKAGE_PATH}" \\
                                --limit ${DEPLOY_ENV}
                        """
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
