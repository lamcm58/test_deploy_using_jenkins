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
                sh 'php artisan key:generate --ansi'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'php artisan test'
            }
        }

        stage('Deploy with Ansible') {
            steps {
                sh 'ansible-playbook -i ansible/inventory ansible/deploy.yml -v --extra-vars "env=${DEPLOY_ENV}" --limit develop'
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
