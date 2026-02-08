#!/bin/bash

# Build Stage.

# Fix PATH first (for Jenkins, because Jenkins PATH doesn’t include /usr/games)
# export PATH=$PATH:/usr/games:/usr/local/games #### Kept for debugging.

# Fetch advice from the API
curl -s https://api.adviceslip.com/advice > advice.json

# Extract advice text
jq -r .slip.advice advice.json > advice.message