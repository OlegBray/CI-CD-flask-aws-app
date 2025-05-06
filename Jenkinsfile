pipeline {
  agent any

  environment {
    AWS_REGION    = 'il-central-1'
    ECR_REGISTRY  = '314525640319.dkr.ecr.il-central-1.amazonaws.com'
    ECR_REPO_NAME = 'imtech-oleg'
    IMAGE_TAG     = 'flask-integration-v1'
    DOCKER_IMAGE  = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
    VAULT_ADDR    = 'http://vault:8200'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Retrieve AWS creds from Vault') {
      steps {
        // Correct vault step usage :contentReference[oaicite:10]{index=10}
        vault(
          path:          'secret/data/aws/pv-key',
          engineVersion: '2',
          credentialsId: 'vault-cred',
          secretValues: [
            [vaultKey: 'access_key', envVar: 'AWS_ACCESS_KEY_ID'],
            [vaultKey: 'secret_key', envVar: 'AWS_SECRET_ACCESS_KEY']
          ]
        )
        sh 'echo "Using AWS principal: $(aws sts get-caller-identity --query Arn --output text)"'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t ${DOCKER_IMAGE} ."
      }
    }

    stage('Login to ECR') {
      steps {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} \
            | docker login --username AWS --password-stdin ${ECR_REGISTRY}
        """
      }
    }

    stage('Push to ECR') {
      steps {
        sh "docker push ${DOCKER_IMAGE}"
      }
    }
  }
}
