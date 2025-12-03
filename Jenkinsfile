#!/usr/bin/env groovy

library identifier: 'jenkins-shared-library@main', retriever: modernSCM(
    [$class: 'GitSCMSource', 
    remote: 'https://github.com/MonikaJassova/8-jenkins-shared-library.git',
    credentialsId: 'GitHub'])

pipeline {   
  agent any
  stages {
    stage("provision EKS") {
      environment {
        // authentication to AWS for TF
        AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
        TF_VAR_env_prefix = 'test'
      }
      steps {
        script {
          sh "terraform init"
          sh "terraform apply --auto-approve"
        }
      }
    }
  }
}
