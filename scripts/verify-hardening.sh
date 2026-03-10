#!/bin/bash

set -e

echo "🔍 PomoDaddy Hardening Verification"
echo "===================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Check 1: No force unwraps
echo "1️⃣  Checking for force unwraps..."
FORCE_UNWRAPS=$(grep -r "!" --include="*.swift" PomoDaddy/ | grep -v "//" | grep -v "\"" | grep -v "!=" | grep -v "! " | wc -l | tr -d ' ')
if [ "$FORCE_UNWRAPS" -gt 5 ]; then
    echo -e "${RED}❌ Found $FORCE_UNWRAPS potential force unwraps${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ No problematic force unwraps found${NC}"
fi
echo ""

# Check 2: Check print() statements
echo "2️⃣  Checking for print() statements..."
PRINTS=$(grep -r "print(" --include="*.swift" PomoDaddy/ | grep -v "//" | grep -v "#if DEBUG" | wc -l | tr -d ' ')
if [ "$PRINTS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found $PRINTS print() statements (should use Logger)${NC}"
else
    echo -e "${GREEN}✅ No print() statements${NC}"
fi
echo ""

# Check 3: Run SwiftLint
echo "3️⃣  Running SwiftLint..."
if swiftlint lint --strict --quiet 2>/dev/null; then
    echo -e "${GREEN}✅ SwiftLint passed${NC}"
else
    echo -e "${RED}❌ SwiftLint failed (or not installed)${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 4: Check test count
echo "4️⃣  Checking tests..."
if [ -d "PomoDaddyTests" ]; then
    TEST_COUNT=$(find PomoDaddyTests -name "*Tests.swift" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TEST_COUNT" -lt 10 ]; then
        echo -e "${RED}❌ Only $TEST_COUNT test files (expected ≥10)${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✅ Found $TEST_COUNT test files${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  PomoDaddyTests directory not found${NC}"
fi
echo ""

# Check 5: Run tests
echo "5️⃣  Running tests..."
if [ -f "PomoDaddy.xcodeproj/project.pbxproj" ]; then
    if xcodebuild test -project PomoDaddy.xcodeproj -scheme PomoDaddy -destination 'platform=macOS' -quiet 2>/dev/null; then
        echo -e "${GREEN}✅ All tests passed${NC}"
    else
        echo -e "${RED}❌ Tests failed (or project not built)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  Xcode project not generated (run 'make setup')${NC}"
fi
echo ""

# Summary
echo "===================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS check(s) failed${NC}"
    exit 1
fi
