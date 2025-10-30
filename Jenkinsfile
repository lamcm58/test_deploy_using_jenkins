pipeline {
    agent any
    options {
        timestamps()
    }

    environment {
        DEPLOY_ENV = "local"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'deve', url: 'https://github.com/lamcm58/test_deploy_using_jenkins.git'
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
                    sh 'ansible-playbook -i ansible/inventory ansible/deploy.yml -v --extra-vars "env=${DEPLOY_ENV} ansible_become_password=${BECOME_PASS}" db_host=${DB_HOST} db_name=${DB_NAME} db_user=${DB_USER} db_password=${DB_PASSWORD} --limit develop'
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
