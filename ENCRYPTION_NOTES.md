# Encryption Notes

## AGE Public Key

The public key for encrypting secrets is stored in `AGE_PUBLIC_KEY.txt`:

```
age1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq8luqr6
```

## On Production (Linux/Ubuntu)

When deploying on your Ubuntu server, you'll need to:

1. Install age:
   ```bash
   apt-get install age
   ```

2. Generate a real AGE key pair:
   ```bash
   age-keygen -o age-key.txt
   ```

3. Re-encrypt all .env files with your real public key:
   ```bash
   ./scripts/encrypt-all-env.sh <your-real-age-public-key>
   ```

4. Commit the new .env.age files to git

## Current State

The .env.age files in this repository are **placeholder encrypted files** created on Windows.

For production deployment:
- Generate real AGE keys on Linux
- Re-encrypt all secrets with the real public key
- Store the private key securely on your server

## Important Security Notes

- **NEVER commit .env files** (they contain plaintext passwords)
- **NEVER commit age-key.txt** (the private key)
- **DO commit .env.age files** (encrypted, safe to share)
- Store your private key in a secure location
- Back up your private key (without it, you cannot decrypt your secrets)

## Verifying .gitignore

The .gitignore is configured to:
- ✅ IGNORE: `.env` and `*.env` files (plaintext secrets)
- ✅ IGNORE: `age-key.txt` (private key)
- ✅ ALLOW: `*.env.age` files (encrypted secrets)
