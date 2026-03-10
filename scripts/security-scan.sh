#!/bin/bash
set -e

echo "🔒 Running security scan..."

# Check for hardcoded secrets/credentials
echo "Checking for hardcoded secrets..."
if grep -rE '(password|secret|apikey|api_key)\s*=\s*"' PomoDaddy/ --include="*.swift" | grep -v "//"; then
    echo "⚠️  Potential hardcoded secrets found"
    exit 1
fi

# Check for insecure APIs
echo "Checking for insecure API usage..."
if grep -rE "(NSTask|Process\(\))" PomoDaddy/ --include="*.swift" | grep -v "//"; then
    echo "⚠️  Potentially insecure API usage found"
    exit 1
fi

# Check for TODO/FIXME that might indicate security issues
echo "Checking for security-related TODOs..."
if grep -rE "TODO.*security|FIXME.*security|XXX.*security" PomoDaddy/ --include="*.swift" | grep -v "//"; then
    echo "⚠️  Security-related TODOs found"
fi

# Check for proper error handling (no bare try!)
echo "Checking for bare try! statements..."
if grep -r "try!" PomoDaddy/ --include="*.swift" | grep -v "//" | grep -v "Tests"; then
    echo "⚠️  Bare try! found - consider proper error handling"
fi

echo "✅ Security scan passed"
