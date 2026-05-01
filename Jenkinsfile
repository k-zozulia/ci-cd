pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - sleep
    args:
    - 9999999
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker
  - name: git
    image: alpine/git:latest
    command:
    - sleep
    args:
    - 9999999
  volumes:
  - name: kaniko-secret
    secret:
      secretName: docker-credentials
      items:
      - key: .dockerconfigjson
        path: config.json
"""
        }
    }

    environment {
        AWS_REGION        = "eu-central-1"
        ECR_REGISTRY      = "419772658013.dkr.ecr.eu-central-1.amazonaws.com"
        ECR_REPOSITORY    = "lesson-8-9-ecr"
        IMAGE_TAG         = "${BUILD_NUMBER}"
        GITHUB_REPO       = "https://github.com/k-zozulia/ci-cd.git"
        GITHUB_BRANCH     = "lesson-8-9"
    }

    stages {
        stage('Build & Push to ECR') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \
                            --context=dir:///home/jenkins/agent/workspace/django-pipeline \
                            --dockerfile=/home/jenkins/agent/workspace/django-pipeline/Dockerfile \
                            --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \
                            --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    """
                }
            }
        }

        stage('Update Helm values.yaml') {
            steps {
                container('git') {
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        sh """
                            git config --global user.email "jenkins@ci.cd"
                            git config --global user.name "Jenkins"

                            git clone https://x-token:${GITHUB_TOKEN}@github.com/k-zozulia/ci-cd.git repo
                            cd repo

                            git checkout ${GITHUB_BRANCH}

                            sed -i 's|tag:.*|tag: "${IMAGE_TAG}"|' charts/django-app/values.yaml

                            git add charts/django-app/values.yaml
                            git commit -m "ci: update image tag to ${IMAGE_TAG}"
                            git push origin ${GITHUB_BRANCH}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded! Image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}