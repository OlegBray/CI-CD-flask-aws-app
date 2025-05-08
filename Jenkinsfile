pipeline {
  agent any

  parameters {
    booleanParam(name: 'DESTROY', defaultValue: true, description: 'Set true to destroy infrastructure instead of deploying')
  }

  environment {
    AWS_REGION = 'il-central-1'
    ECR_REPO = 'imtech-oleg'
    ECR_ACCOUNT = '314525640319'
    IMAGE_TAG = "${BUILD_NUMBER}"
    DOCKER_IMAGE = "${ECR_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
  }

  stages {
    stage('Terraform Destroy') {
      when {
        expression { params.DESTROY == true }
      }
      steps {
        sh '''
          terraform init
          terraform destroy -auto-approve -var="image_tag=${BUILD_NUMBER}"
        '''
      }
    }

    stage('Build Docker Image') {
      when {
        expression { params.DESTROY == false }
      }
      steps {
        sh "docker build -t ${DOCKER_IMAGE} ."
      }
    }

    stage('Login to ECR') {
      when {
        expression { params.DESTROY == false }
      }
      steps {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} \
            | docker login --username AWS --password-stdin ${ECR_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
        """
      }
    }

    stage('Push to ECR') {
      when {
        expression { params.DESTROY == false }
      }
      steps {
        sh "docker push ${DOCKER_IMAGE}"
      }
    }

    stage('Run Terraform Apply') {
      when {
        expression { params.DESTROY == false }
      }
      steps {
        sh '''
          terraform init
          terraform validate
          terraform apply -auto-approve -var="image_tag=${BUILD_NUMBER}"
        '''
      }
    }
  }

  post {
    always {
      sh 'unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN'
    }
  }
}
