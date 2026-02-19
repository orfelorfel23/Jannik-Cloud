# Security Verification

## Files in Git Repository

✅ **Safe to commit (encrypted/public):**
- `.env.age` files (encrypted secrets)
- `AGE_PUBLIC_KEY.txt` (public key)
- `docker-compose.yml` files
- Shell scripts
- Documentation
- Caddyfile

## Files Excluded from Git

🔒 **NEVER committed (sensitive):**
- `.env` files (plaintext passwords)
- `age-key.txt` (private encryption key)
- `age-key.pub` (generated public key file)

## Verification Commands

### Check what's being tracked:
```bash
git ls-files | grep -E "\.(env|key)" || echo "No sensitive files tracked"
```

### Verify .env files are ignored:
```bash
git check-ignore services/outline/.env
# Should output: services/outline/.env
```

### Verify .env.age files are tracked:
```bash
git ls-files | grep "\.env\.age$"
# Should list all 14 .env.age files
```

### List ignored files with passwords:
```bash
find services -name ".env" -type f
# These should all be ignored by git
```

## Current Status

Run this verification:

```bash
cd Jannik-Cloud
echo "=== Checking for sensitive files in git ==="
git ls-files | grep -E "^services/.*\.env$|age-key\.txt" && echo "⚠️  WARNING: Sensitive files found!" || echo "✅ Safe: No sensitive files in git"

echo ""
echo "=== Verifying encrypted files are in git ==="
git ls-files | grep "\.env\.age$" | wc -l
echo "Expected: 14 encrypted .env.age files"

echo ""
echo "=== Checking plaintext .env files exist locally (but ignored) ==="
find services -name ".env" -type f | wc -l
echo "Should be: 14 .env files (ignored by git)"
```

## What Gets Pushed to Git

When you run `git push`, these are pushed:
- ✅ All source code and configs
- ✅ 14 encrypted `.env.age` files
- ✅ All documentation
- ✅ Public AGE key
- ❌ NO plaintext passwords
- ❌ NO private keys

## What Stays Local Only

These remain on your local machine/server only:
- 🔒 `.env` files with real passwords
- 🔒 `age-key.txt` private key
- 🔒 Any `*.key` files

## Production Deployment

On your Ubuntu server:
1. Clone the git repository (gets encrypted files)
2. Run `sudo ./deploy_script.sh`
3. Script prompts for AGE private key
4. Script decrypts all `.env.age` → `.env` files
5. Services start with real passwords
6. `.env` files stay local on server only
