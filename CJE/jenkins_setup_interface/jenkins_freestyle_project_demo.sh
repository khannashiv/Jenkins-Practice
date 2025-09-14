#!/bin/bash

# Build Stage.

# Fix PATH first (for Jenkins, because Jenkins PATH doesn’t include /usr/games)
export PATH=$PATH:/usr/games:/usr/local/games

# Fetch advice from the API
curl -s https://api.adviceslip.com/advice > advice.json

# Extract advice text
jq -r .slip.advice advice.json > advice.message

# Test to make sure the advice message has more than 5 words ( Test Stage. )
word_count=$(wc -w < advice.message)

if [ $word_count -gt 5 ]; then
  echo "Advice has more than 5 words"
else
  echo "Advice $(cat advice.message) has 5 words or less"
fi

# Ensure cowsay is installed. ( Deploy Stage. )
if [ ! command -v cowsay &> /dev/null ]; then
  echo "Error: cowsay is not installed. Please run: sudo apt-get install cowsay -y"
  exit 1
fi

# Display advice with random cow
echo $PATH
cat advice.message | cowsay -f $(ls /usr/share/cowsay/cows | shuf -n 1)