# LiteLLM - LLM API Gateway

## Overview
LiteLLM is a lightweight API gateway that provides a unified interface to multiple LLM providers including OpenAI, Anthropic, Google, and more.

## Configuration
- **Domain**: https://llm.orfel.de
- **Internal Port**: 11001
- **Database**: PostgreSQL 15
- **User**: Jannik

## Features
- Unified API for multiple LLM providers
- Model aliasing and routing
- Request/response logging
- Rate limiting and authentication
- Cost tracking

## Supported Providers
- OpenAI
- Anthropic Claude
- Google Gemini
- Azure OpenAI

## Data Storage
- Database: /mnt/Jannik-Cloud-Volume-01/litellm/postgres
- Configuration: /mnt/Jannik-Cloud-Volume-01/litellm

## API Usage
```bash
curl -X POST "https://llm.orfel.de/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_MASTER_KEY"
```

## Logs
```bash
docker logs litellm
```
