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
        // setting TF env var
        TF_VAR_env_prefix = 'test'
        // TF_VAR_private_subnet_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
        // TF_VAR_public_subnet_cidr_blocks = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
        TF_VAR_vpc_cidr_block = "10.0.0.0/16"
      }
      steps {
        script {
          sh "terraform init"
          def privateList = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
          def publicList = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
          def privateJsonList = groovy.json.JsonOutput.toJson(privateList)
          def publicJsonList = groovy.json.JsonOutput.toJson(publicList)
          env.TF_VAR_private_subnet_cidr_blocks = privateJsonList
          env.TF_VAR_public_subnet_cidr_blocks = publicJsonList
          sh "terraform plan"
          // sh "terraform apply --auto-approve"
          // getting output value and setting as env var
          // EC2_PUBLIC_IP = sh(
          //   script: "terraform output ec2-public_ip",
          //   returnStdout: true
          // ).trim()
        }
      }
    }
  }
}
