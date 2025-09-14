#### Ensure cowsay is installed. ( Deploy Stage. )

#!/bin/sh

export PATH=$PATH:/usr/games:/usr/local/games

if ! which cowsay >/dev/null 2>&1; then
  echo "Error: cowsay is not installed. Please run: sudo apt-get install cowsay -y"
  exit 1
fi

echo "PATH is: $PATH"

# Display advice with random cow
cat advice.message | cowsay -f $(ls /usr/share/cowsay/cows | shuf -n 1)