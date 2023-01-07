#!/bin/bash

# Database thoughts
# 1 table for users with user_id SERIAL PRIMARY KEY, name VARCHAR(22)
# 2 table for games with game_id SERIAL PRIMARY KEY, user_id FOREIGN KEY, number_of_guesses

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

MENU() {
  # generate random number 1-1000
  SECRET=$((RANDOM%1000+1))
  # Enter username prompt and read into variable USERNAME
  echo Enter your username:
  read USERNAME

  USER_INFO=$($PSQL "SELECT user_id, game_id, number_of_guesses
                      FROM users INNER JOIN games USING(user_id)
                      WHERE name = '$USERNAME'")
  # if the user is new
  if [[ -z $USER_INFO ]]
  then
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    NEW_USER_RESULT=$($PSQL "INSERT INTO users(name) VALUES('$USERNAME')")
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME'")
    GAME
  else
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME'")
    GAMES_COUNT=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id = $USER_ID")
    BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id = $USER_ID")
    echo "Welcome back, $USERNAME! You have played $GAMES_COUNT games, and your best game took $BEST_GAME guesses."
    GAME
  fi
}

GAME() {
  echo "Guess the secret number between 1 and 1000:"
  GUESS_COUNT=0
  read GUESS
  while [[ $GUESS -ne $SECRET ]]
  do
    if [[ ! $GUESS =~ ^[0-9]+$ ]]
    then
      echo "That is not an integer, guess again:"
      read GUESS
    elif [[ $GUESS -gt $SECRET ]]
    then
      echo "It's lower than that, guess again:"
      GUESS_COUNT=$(($GUESS_COUNT + 1))
      read GUESS
    elif [[ $GUESS -lt $SECRET ]]
    then
      echo "It's higher than that, guess again:"
      GUESS_COUNT=$(($GUESS_COUNT + 1))
      read GUESS
    fi
  done
  GUESS_COUNT=$(($GUESS_COUNT + 1))
  INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $GUESS_COUNT)")
  echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET. Nice job!"
}

MENU
