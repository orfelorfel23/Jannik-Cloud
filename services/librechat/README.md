# LibreChat - Chat Interface for Multiple LLMs

## Overview
LibreChat is an open-source chat UI for multiple LLM providers. Switch between OpenAI, Anthropic, Google, and more.

## Configuration
- **Domain**: https://chat.orfel.de
- **Internal Port**: 11008
- **Database**: MongoDB 7
- **User**: Jannik

## Features
- Multi-LLM support (OpenAI, Claude, Gemini)
- Conversation history
- System prompts and presets
- File uploads and attachments
- Image generation (with compatible APIs)
- User authentication

## First Run
1. Navigate to https://chat.orfel.de
2. Sign up for an account
3. Configure API keys in settings (OpenAI, Anthropic, Google)

## Data Storage
- Database: /mnt/Jannik-Cloud-Volume-01/librechat/mongo
- Images: /mnt/Jannik-Cloud-Volume-01/librechat

## API Keys
Configure your own API keys from:
- OpenAI: https://platform.openai.com
- Anthropic: https://console.anthropic.com
- Google: https://makersuite.google.com

## Logs
```bash
docker logs librechat
docker logs librechat-mongo
```
