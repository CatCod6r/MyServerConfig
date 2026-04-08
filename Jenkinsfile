pipeline {
  agent any
  
  environment {
    DOMAIN_NAME = "test.local"
    WIREGUARD_PASSWORD = "testpassword"
    VAULTWARDEN_ADMIN_TOKEN = "testtoken"
    DOCKER_GID = "1000"
  }

  stages {
    stage('Linting: YAML') {
      steps {
        echo 'Running yamllint...'
        // Uses a docker container to lint all yaml files in the repository
        sh '''
          docker run --rm -v $(pwd):/data cytopia/yamllint -d "{extends: relaxed, rules: {line-length: disable}}" .
        '''
      }
    }

    stage('Linting: Shell Scripts') {
      steps {
        echo 'Running shellcheck on setup.sh...'
        // Ignores SC1091 (unable to read sourced .env file in CI)
        sh '''
          docker run --rm -v $(pwd):/mnt koalaman/shellcheck -e SC1091 /mnt/setup.sh
        '''
      }
    }

    stage('Validation: Docker Compose') {
      steps {
        echo 'Validating docker-compose.yml...'
        // Creates a dummy .env file so docker-compose config doesn't fail on missing variables
        sh '''
          touch .env
          docker compose config -q
        '''
      }
    }

    stage('Validation: Prometheus Configs') {
      steps {
        echo 'Validating Prometheus configs with promtool...'
        sh '''
          docker run --rm -v $(pwd)/prometheus:/etc/prometheus prom/prometheus:latest promtool check config /etc/prometheus/prometheus.yml
          docker run --rm -v $(pwd)/prometheus:/etc/prometheus prom/prometheus:latest promtool check rules /etc/prometheus/alert-rules.yml
        '''
      }
    }

    stage('Validation: Nginx Config') {
      steps {
        echo 'Validating Nginx vaultwarden.conf...'
        sh '''
          docker run --rm -v $(pwd)/vaultwarden.conf:/etc/nginx/nginx.conf:ro nginx:latest nginx -t -c /etc/nginx/nginx.conf
        '''
      }
    }

    stage('Send info to discord') {
      steps {
        withCredentials([string(credentialsId: 'DISCORD_WEBHOOK_URL', variable: 'DISCORD_URL')]) {
          discordSend (
            webhookURL: "${env.DISCORD_URL}",
            title: "Build Started",
            description: "Job: ${env.JOB_NAME} [Build #${env.BUILD_NUMBER}]",
            result: 'SUCCESS'
          )
        }
        echo 'Message sent to Discord webhook'
      }
    }
  }

  post {
    failure {
      // Send a failure notification to Discord if any test fails
      withCredentials([string(credentialsId: 'DISCORD_WEBHOOK_URL', variable: 'DISCORD_URL')]) {
        discordSend (
          webhookURL: "${env.DISCORD_URL}",
          title: "Build FAILED \u274C",
          description: "Tests failed on Job: ${env.JOB_NAME} [Build #${env.BUILD_NUMBER}]\nCheck Jenkins console output.",
          result: 'FAILURE'
        )
      }
    }
  }
}
