# Jannik Cloud Infrastructure - AGE Encryption Setup Guide

## Overview

This infrastructure uses AGE encryption to protect sensitive .env files. Each service's configuration is encrypted with AGE, requiring a private key to decrypt.

## Generate AGE Keys

If you don't have an AGE key pair, generate one:

```bash
age-keygen -o
```

This creates:
- **Private key** (AGE-SECRET-KEY-...): Keep secret, save to `/opt/Jannik-Cloud/keys/age-key.txt`
- **Public key** (age...): Share or use for encryption

## Setup AGE Key for Bootstrap

### Option 1: Interactive (Recommended)
When you run `bootstrap.sh`, it will prompt you:
```bash
sudo infrastructure/bootstrap.sh
```

Output:
```
AGE private key not found. Please paste your AGE-SECRET-KEY now (input will be hidden):
> [Enter your key - input hidden]
```

### Option 2: Place Key Before Bootstrap
Pre-place the key for non-interactive setup:

```bash
# Create directory
sudo mkdir -p /opt/Jannik-Cloud/keys

# Place your AGE secret key (input will be hidden)
echo -n "Enter AGE secret key: " && read -s key && echo "$key" | sudo tee /opt/Jannik-Cloud/keys/age-key.txt > /dev/null

# Set permissions
sudo chmod 600 /opt/Jannik-Cloud/keys/age-key.txt

# Verify
sudo cat /opt/Jannik-Cloud/keys/age-key.txt
```

## Encrypt Service Configurations

Each service's .env file can be encrypted:

```bash
# Generate public key from private key
age-keygen -o | grep "^# public key:" | cut -d' ' -f4 > age-pub.txt

# Encrypt a service's .env file
age -R age-pub.txt < services/outline/.env > services/outline/.env.age

# Verify encryption
file services/outline/.env.age  # Should show binary data

# Decrypt for verification
age -d -i /opt/Jannik-Cloud/keys/age-key.txt < services/outline/.env.age

# Remove plaintext after successful encryption
rm services/outline/.env
```

## Automatic Encryption via generate-env.sh

Each service includes a `generate-env.sh` script that can encrypt automatically:

```bash
cd services/outline
AGE_PUBLIC_KEY="age1..." bash generate-env.sh
```

Output:
- `.env` - Plain text (local use only)
- `.env.age` - Encrypted (safe to commit)

## Key Management Best Practices

### ✓ DO:
- Store AGE secret key securely (e.g., password manager, hardware key)
- Use long, random keys (age-keygen generates secure keys)
- Back up your AGE key in multiple secure locations
- Protect /opt/Jannik-Cloud/keys/ with proper permissions (chmod 700)
- Rotate keys periodically for sensitive environments
- Keep key and encrypted files separate when possible

### ✗ DON'T:
- Commit raw `.env` files to git
- Share AGE-SECRET-KEY with anyone
- Store keys in version control
- Use weak passwords for key derivation
- Forget to set chmod 600 on key files
- Print keys in logs (they're protected in scripts)

## Encryption Workflow

### New Deployment
1. Generate AGE keys locally
2. Place private key at `/opt/Jannik-Cloud/keys/age-key.txt`
3. Run `bootstrap.sh` - it automatically decrypts all .env.age files
4. Services read plain .env files at runtime

### CI/CD Integration

For automated deployment:
```bash
# In your CI/CD pipeline
export AGE_IDENTITY="/path/to/age-key.txt"

# Decrypt all services
infrastructure/decrypt-secrets.sh

# Deploy
sudo infrastructure/bootstrap.sh
```

## Emergency Key Recovery

If you lose your AGE private key:

1. **Recover from backup** (if you have one):
   ```bash
   # Restore from secure backup
   ```

2. **Recreate from encrypted files**:
   If you don't have the key, encrypted .env.age files cannot be recovered. Keep backups!

## Troubleshooting AGE Encryption

### "Invalid AGE key format"
```bash
# Verify key format starts with AGE-SECRET-KEY-
cat /opt/Jannik-Cloud/keys/age-key.txt | head -c 20

# Expected output:
# AGE-SECRET-KEY-
```

### "Decryption failed"
```bash
# Verify key matches the encryption
age -d -i /opt/Jannik-Cloud/keys/age-key.txt < services/service/.env.age

# If it fails, the key doesn't match the encrypted file
```

### "File not found"
```bash
# Ensure .env.age has proper permissions
ls -la services/outline/.env.age

# Should be readable and match your key
```

## Age Command Reference

```bash
# Generate new key pair
age-keygen -o > key.txt
cat key.txt | grep "^# public key:"

# Encrypt file
age -R pubkey.txt < plaintext.txt > plaintext.age

# Decrypt file
age -d -i private-key.txt < plaintext.age > plaintext.txt

# Encrypt with public key (string)
echo "PUB_KEY" | age -e -R /dev/stdin < plaintext.txt > plaintext.age

# Verify cipher (shows age format)
file plaintext.age
```

## Security Audit

Check your AGE setup:

```bash
# Verify permissions
ls -la /opt/Jannik-Cloud/keys/age-key.txt
# Should be: -rw------- (600)

# Verify key validity
grep "^AGE-SECRET-KEY-" /opt/Jannik-Cloud/keys/age-key.txt

# Test decryption
age -d -i /opt/Jannik-Cloud/keys/age-key.txt < services/outline/.env.age > /tmp/test.env
rm /tmp/test.env

echo "✓ AGE setup is secure and working"
```

## References

- Official AGE documentation: https://age-encryption.org/
- AGE GitHub: https://github.com/FiloSottile/age
- Bootstrap script uses AGE for all secret management
