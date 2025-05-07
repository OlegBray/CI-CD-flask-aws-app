pipeline {
  agent any

  environment {
    // ECR settings
    AWS_REGION           = 'il-central-1'
    ECR_REGISTRY         = '314525640319.dkr.ecr.il-central-1.amazonaws.com'
    ECR_REPO_NAME        = 'imtech-oleg'
    IMAGE_TAG            = 'flask-integration-v1'
    DOCKER_IMAGE         = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"

    // Vault‑injected AWS creds (KV‑v2)
    AWS_ACCESS_KEY_ID     = vault path: 'secret/data/aws/creds', key: 'access_key', engineVersion: '2', credentialsId: 'vault-cred'    // :contentReference[oaicite:1]{index=1}
    AWS_SECRET_ACCESS_KEY = vault path: 'secret/data/aws/creds', key: 'secret_key', engineVersion: '2', credentialsId: 'vault-cred'    // :contentReference[oaicite:2]{index=2}
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Verify AWS Identity') {
      steps {
        // will use the vars injected above
        sh 'echo "AWS caller: $(aws sts get-caller-identity --query Arn --output text)"'
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
