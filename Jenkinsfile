pipeline {
  agent any
  environment {
    AWS_REGION = 'il-central-1'
    ECR_REPO = 'imtech-oleg'
    ECR_ACCOUNT = '314525640319'
    IMAGE_TAG = "${BUILD_NUMBER}"
  }

  stages {
    // stage('Clone Code') {
    //   steps {
    //     git branch: 'main', url: 'https://github.com/LironBinyamin96/CI-CD-flask-app-aws.git'
    //   }
    // }

    stage('Login to ECR') {
      steps {
        sh '''
          aws ecr get-login-password --region $AWS_REGION | sudo docker login --username AWS --password-stdin $ECR_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t ${DOCKER_IMAGE} ."
      }
    }

    // stage('Login to ECR') {
    //   steps {
    //     sh """
    //       aws ecr get-login-password --region ${AWS_REGION} \
    //         | docker login --username AWS --password-stdin ${ECR_REGISTRY}
    //     """
    //   }
    // }

    stage('Push to ECR') {
      steps {
        sh "sudo docker push ${DOCKER_IMAGE}"
      }
    }
  }

  post {
    always {
      sh 'unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN'
    }
  }
}
