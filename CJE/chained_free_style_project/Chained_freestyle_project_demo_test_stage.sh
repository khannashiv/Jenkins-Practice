#### Test to make sure the advice message has more than 5 words ( Test Stage. )

#!/bin/bash
# echo "Current workspace content: $(ls -al)" # This line is kept for debugging.
word_count=$(wc -w < advice.message)

if [ $word_count -gt 5 ]; then
  echo "Advice has more than 5 words"
else
  echo "Advice $(cat advice.message) has 5 words or less"
fi