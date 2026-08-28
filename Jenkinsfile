#!/usr/bin/env groovy

library identifier: 'jenkins-shared-library@main', retriever: modernSCM(
    [$class: 'GitSCMSource', 
    remote: 'https://github.com/MonikaJassova/8-jenkins-shared-library.git',
    credentialsId: 'GitHub'])

pipeline {   
  agent any
  parameters {
    choice(name: 'ENV', choices: ['dev', 'staging', 'test'], description: 'Target environment')
  }
  stages {
    stage("provision TCP infrastructure") {
      environment {
        // authentication to T Cloud Public for TF
        OS_ACCESS_KEY = credentials('jenkins_tcp_access_key_id')
        OS_SECRET_KEY = credentials('jenkins_tcp_secret_access_key')
        OS_REGION     = 'eu-de'
        // for OBS service
        AWS_ACCESS_KEY_ID = credentials('jenkins_tcp_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins_tcp_secret_access_key')
      }
      steps {
        script {
          sh "terraform -chdir=environments/${params.ENV} init"
          sh "terraform -chdir=environments/${params.ENV} apply --auto-approve"
        }
      }
    }
  }
}
