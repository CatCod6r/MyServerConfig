pipeline {
  agent any
  
  environment {
    // Mock environment variables required for validation steps
    DOMAIN_NAME = "test.local"
    WIREGUARD_PASSWORD = "testpassword"
    VAULTWARDEN_ADMIN_TOKEN = "testtoken"
    DOCKER_GID = "1000"
    
    // Add our local workspace bin directory to the execution PATH
    PATH = "${env.WORKSPACE}/bin:${env.PATH}"
  }

  stages {
    stage('Setup Tools (Locally)') {
      steps {
        echo 'Downloading standalone testing tools into workspace...'
        sh '''
          # Create a local bin directory in the Jenkins workspace
          mkdir -p bin
          
          # 1. Download ShellCheck
          if [ ! -f bin/shellcheck ]; then
            echo "Downloading ShellCheck..."
            curl -sSLO https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz
            tar -xJf shellcheck-v0.10.0.linux.x86_64.tar.xz
            mv shellcheck-v0.10.0/shellcheck bin/
            rm -rf shellcheck-v0.10.0*
          fi

          # 2. Download Promtool (Prometheus config validator)
          if [ ! -f bin/promtool ]; then
            echo "Downloading Promtool..."
            curl -sSLO https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
            tar -xzf prometheus-2.53.0.linux-amd64.tar.gz
            mv prometheus-2.53.0.linux-amd64/promtool bin/
            rm -rf prometheus-2.53.0*
          fi

          # 3. Download standalone Docker Compose binary (for syntax checking)
          if [ ! -f bin/docker-compose ]; then
            echo "Downloading Docker Compose..."
            curl -sSL https://github.com/docker/compose/releases/download/v2.29.1/docker-compose-linux-x86_64 -o bin/docker-compose
            chmod +x bin/docker-compose
          fi

          # 4. Download yq (standalone Go binary for YAML linting/parsing)
          if [ ! -f bin/yq ]; then
            echo "Downloading yq..."
            curl -sSL https://github.com/mikefarah/yq/releases/download/v4.44.2/yq_linux_amd64 -o bin/yq
            chmod +x bin/yq
          fi
          
          echo "All tools installed in ${WORKSPACE}/bin"
          shellcheck --version
        '''
      }
    }

    stage('Linting: YAML') {
      steps {
        echo 'Validating all YAML files with yq...'
        // Uses yq to parse every yaml file. If a file has invalid YAML syntax, yq will fail the build.
        sh '''
          find . -name "*.yml" -type f -exec echo "Checking {}" \\; -exec yq eval '.' {} \\; > /dev/null
        '''
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
        sh 'touch .env && docker-compose config -q'
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
