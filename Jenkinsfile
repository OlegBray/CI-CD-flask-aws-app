pipeline {
  agent any

  environment {
    // ECR settings
    AWS_REGION    = 'il-central-1'
    ECR_REGISTRY  = '314525640319.dkr.ecr.il-central-1.amazonaws.com'
    ECR_REPO_NAME = 'imtech-oleg'
    IMAGE_TAG     = 'flask-integration-v1'
    DOCKER_IMAGE  = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"

    // Vault server info
    VAULT_ADDR    = 'http://vault:8200'
    AWS_CREDS_PATH= 'secret/data/aws/creds'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Retrieve AWS creds from Vault') {
      steps {
        // Bind Vault token from Jenkins Credentials → VAULT_TOKEN
        withCredentials([string(credentialsId: 'vault-token', variable: 'VAULT_TOKEN')]) {
          script {
            // Fetch secret via HTTP
            def resp = httpRequest(
              httpMode: 'GET',
              url: "${env.VAULT_ADDR}/v1/${env.AWS_CREDS_PATH}",
              customHeaders: [[name: 'X-Vault-Token', value: VAULT_TOKEN]],
              validResponseCodes: '200'
            )
            // Parse JSON and set AWS env vars
            def data = readJSON text: resp.content
            env.AWS_ACCESS_KEY_ID     = data.data.data.access_key
            env.AWS_SECRET_ACCESS_KEY = data.data.data.secret_key
            if (data.data.data.session_token) {
              env.AWS_SESSION_TOKEN   = data.data.data.session_token
            }
            echo "✅ Retrieved AWS creds from Vault"
          }
        }
      }
    }

    stage('Debug AWS Identity') {
      steps {
        // Confirm AWS CLI sees the creds
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
        // Non‑interactive login to ECR
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

  post {
    always {
      // Clean up sensitive vars
      sh 'unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN'
    }
  }
}
