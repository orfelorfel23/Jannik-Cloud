#!/bin/bash
# Generate a secure 32-character password
openssl rand -base64 24 | tr -d '\n' | head -c 32
