pipeline {
  agent { label 'docker-worker' }
  
  environment {
    DOMAIN_NAME = "test.local"
    WIREGUARD_PASSWORD = "testpassword"
    VAULTWARDEN_ADMIN_TOKEN = "testtoken"
    DOCKER_GID = "1000"
  }

  stages {
    stage('Linting: YAML') {
      steps {
        echo 'Validating all YAML files with yq...'
        sh 'find . -name "*.yml" -type f -exec echo "Checking {}" \\; -exec yq eval "." {} \\; > /dev/null'
      }
    }

    stage('Linting: Shell Scripts') {
      steps {
        echo 'Running shellcheck on setup.sh...'
        sh 'shellcheck -e SC1091 setup.sh'
      }
    }

    stage('Validation: Docker Compose') {
      steps {
        echo 'Validating docker-compose.yml...'
        sh 'touch .env && docker compose config -q'
      }
    }

    stage('Validation: Prometheus Configs') {
      steps {
        echo 'Validating Prometheus configs with promtool...'
        sh 'promtool check config prometheus/prometheus.yml'
        sh 'promtool check rules prometheus/alert-rules.yml'
      }
    }

    stage('Send info to discord') {
      steps {
        withCredentials([string(credentialsId: 'DISCORD_WEBHOOK_URL', variable: 'DISCORD_URL')]) {
          discordSend (
            webhookURL: env.DISCORD_URL,
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
      withCredentials([string(credentialsId: 'DISCORD_WEBHOOK_URL', variable: 'DISCORD_URL')]) {
        discordSend (
          webhookURL: env.DISCORD_URL,
          title: "Build FAILED ❌",
          description: "Tests failed on Job: ${env.JOB_NAME} [Build #${env.BUILD_NUMBER}]\nCheck Jenkins console output.",
          result: 'FAILURE'
        )
      }
    }
  }
}
