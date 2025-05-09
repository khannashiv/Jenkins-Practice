def call() {
            echo 'Testing shared libraries in jenkins.'
            sh '''
                  echo " What is my present working directory."
                  pwd
                  echo "List all the files and folders in present working directory."
                  ls -al
                  echo "Checking disk space alloted to OS."
                  df -h
                  echo " Checking avaiable menory on the system"
                  free -m
             '''
  }
