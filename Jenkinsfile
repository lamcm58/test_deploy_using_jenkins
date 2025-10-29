pipeline {
    agent any

    environment {
        DEPLOY_ENV = "local"
    }

    stages {
        stage('Checkout') {
            steps {
                sshagent(['github-ssh']) {
                    git branch: 'deve', url: 'git@github.com:lamcm58/test_deploy_using_jenkins.git'
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
