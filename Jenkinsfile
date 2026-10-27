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
    PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
    AWS_ACCESS_KEY_ID = credentials('aws-monitoring-demo')
    AWS_DEFAULT_REGION = 'ap-south-1'
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
                sh 'terraform apply -auto-approve -input=false -var="my_ip=106.219.165.107/32" -var="key_name=grafana-vm-demo-key" -var="private_key_path=/Users/salonichaudhary/.ssh/grafana-vm-demo-key.pem"'
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
