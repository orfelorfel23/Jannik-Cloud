#!/bin/bash
if [ ! -f .env ]; then
  cp .env.example .env
  echo ".env created from .env.example"
  echo "Please fill in the required API keys."
else
  echo ".env already exists."
fi
