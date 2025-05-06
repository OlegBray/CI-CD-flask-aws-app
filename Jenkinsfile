pipeline {
  agent any
  environment {
    AWS_REGION    = 'il-central-1'
    ECR_REGISTRY  = '314525640319.dkr.ecr.il-central-1.amazonaws.com'
    ECR_REPO_NAME = 'imtech-oleg'
    IMAGE_TAG     = 'flask-integration-v1'
    DOCKER_IMAGE  = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
  }
  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Set AWS Credentials') {
      steps {
        withCredentials([aws(credentialsId: 'aws-imtech-credentials')]) {
          // AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY are now in env :contentReference[oaicite:1]{index=1}
          sh 'aws sts get-caller-identity'
        }
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
        """  // use --password-stdin for security :contentReference[oaicite:2]{index=2}
      }
    }

    stage('Push to ECR') {
      steps {
        sh "docker push ${DOCKER_IMAGE}"
      }
    }
  }
}
