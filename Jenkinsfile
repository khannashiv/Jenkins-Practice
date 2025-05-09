@Library('my-first-shared-library') _
pipeline {
    agent any

    stages {
        stage('Test-Shared-Library') {
            steps {
                    testSharedLibrary()
            }
        }
    }
}