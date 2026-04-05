pipeline {
  agent any
  stages {
    stage('says hewwo') {
      steps {
        echo 'hewwo'
        
        withCredentials([string(credentialsId: 'DISCORD_WEBHOOK_URL', variable: 'DISCORD_URL')]) {
          discordSend (
            webhookURL: "${env.DISCORD_URL}",
            title: "Build Started",
            description: "Job: ${env.JOB_NAME} [Build #${env.BUILD_NUMBER}]",
            result: 'SUCCESS'
                    )
           }
        echo 'should send message to webhook'
      }
    }
  }
}
