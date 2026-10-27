// ------------------------------------------------------------
// Jenkinsfile  -  ONE CLICK in Jenkins
// Click "Build with Parameters":
//   apply   -> builds AWS + installs all software
//   destroy -> deletes everything
// (Terraform runs Ansible by itself, see ansible.tf)
// ------------------------------------------------------------
pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Create or delete the infrastructure')
    }

    environment {
        // AWS keys saved in Jenkins (Manage Jenkins > Credentials) as "Secret text"
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'ap-south-1'
    }

    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init -input=false'
            }
        }

        stage('Apply: build AWS + install software') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh 'terraform apply -auto-approve -input=false'
                sh 'echo "Grafana is ready: $(terraform output -raw grafana_url)  (user: admin)"'
            }
        }

        stage('Destroy: delete everything') {
            when { expression { params.ACTION == 'destroy' } }
            steps {
                sh 'terraform destroy -auto-approve -input=false'
            }
        }
    }
}
