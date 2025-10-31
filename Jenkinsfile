pipeline {
    agent any
    options {
        timestamps()
    }

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['develop', 'staging', 'production'],
            description: 'Select deployment environment (required)'
        )
    }

    environment {
        DEPLOY_ENV = "${params.DEPLOY_ENV}"
    }

    stages {
        stage('Validate Parameters') {
            steps {
                script {
                    echo "🔍 Validating deployment parameters..."
                    echo "   DEPLOY_ENV received: '${params.DEPLOY_ENV}'"
                    
                    // Check if parameter is missing or invalid
                    if (!params.DEPLOY_ENV || params.DEPLOY_ENV.trim() == '') {
                        error("❌ DEPLOY_ENV parameter is required! Please select an environment (develop/staging/production). Deployment stopped.")
                    }
                    
                    // Validate environment value
                    def validEnvironments = ['develop', 'staging', 'production']
                    if (!validEnvironments.contains(params.DEPLOY_ENV)) {
                        error("❌ Invalid environment '${params.DEPLOY_ENV}'. Must be one of: ${validEnvironments.join(', ')}")
                    }
                    
                    echo "✅ Validation passed! Selected environment: ${params.DEPLOY_ENV}"
                }
            }
        }

        stage('Display Parameters') {
            steps {
                echo "🚀 Deploying to environment: ${params.DEPLOY_ENV}"
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
                sh 'composer install --no-interaction --prefer-dist --optimize-autoloader'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'php artisan test'
            }
        }

        stage('Deploy with Ansible') {
            steps {
                withCredentials([
                    string(credentialsId: 'ansible-become-pass', variable: 'BECOME_PASS'),
                    string(credentialsId: 'db-host', variable: 'DB_HOST'),
                    string(credentialsId: 'db-name', variable: 'DB_NAME'),
                    string(credentialsId: 'db-user', variable: 'DB_USER'),
                    string(credentialsId: 'db-password', variable: 'DB_PASSWORD')
                ]) {
                    sh 'ansible-playbook -i ansible/inventory ansible/deploy.yml -v --extra-vars "env=${DEPLOY_ENV} ansible_become_password=${BECOME_PASS} db_host=${DB_HOST} db_name=${DB_NAME} db_user=${DB_USER} db_password=${DB_PASSWORD}" --limit ${DEPLOY_ENV}'
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
