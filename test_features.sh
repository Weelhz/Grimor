#!/bin/bash

# Book Sphere Feature Testing Script
# This script tests all major features of the Book Sphere application

set -e

echo "📚 Book Sphere Feature Testing Script"
echo "====================================="

# Configuration
SERVER_URL="http://localhost:3000"
API_BASE="$SERVER_URL/api"
TEST_USER="testuser$(date +%s)"
TEST_EMAIL="test@example.com"
TEST_PASSWORD="testpassword123"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Helper functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${YELLOW}Testing: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Check if server is running
echo "🔍 Checking server status..."
if ! curl -s "$SERVER_URL" > /dev/null; then
    echo -e "${RED}❌ Server is not running at $SERVER_URL${NC}"
    echo "Please start the server first: cd server && npm run dev"
    exit 1
fi

echo -e "${GREEN}✓ Server is running${NC}"

# Test 1: Database Connection
echo -e "\n📊 Testing Database Connection..."
run_test "Database health check" "curl -s '$API_BASE/health' | grep -q 'healthy'"

# Test 2: User Registration
echo -e "\n👤 Testing User Authentication..."
run_test "User registration" "curl -s -X POST '$API_BASE/auth/register' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\",\"full_name\":\"Test User\"}' \
    | grep -q 'token'"

# Test 3: User Login
run_test "User login" "curl -s -X POST '$API_BASE/auth/login' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\"}' \
    | grep -q 'token'"

# Get auth token for further tests
AUTH_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\"}" \
    | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$AUTH_TOKEN" ]; then
    echo -e "${RED}❌ Failed to get auth token, skipping authenticated tests${NC}"
    AUTH_TOKEN="invalid_token"
fi

# Test 4: User Profile
run_test "Get user profile" "curl -s '$API_BASE/auth/profile' \
    -H 'Authorization: Bearer $AUTH_TOKEN' \
    | grep -q 'username'"

# Test 5: Mood References
echo -e "\n🎭 Testing Mood System..."
run_test "Get mood references" "curl -s '$API_BASE/moods' | grep -q 'calm'"

# Test 6: Music System
echo -e "\n🎵 Testing Music System..."
run_test "Get music list" "curl -s '$API_BASE/music' | grep -q '\\['"

# Test 7: Book System
echo -e "\n📖 Testing Book System..."
run_test "Get books list" "curl -s '$API_BASE/books' \
    -H 'Authorization: Bearer $AUTH_TOKEN' \
    | grep -q '\\['"

# Test 8: Playlist System
echo -e "\n🎼 Testing Playlist System..."
run_test "Get user playlists" "curl -s '$API_BASE/playlists' \
    -H 'Authorization: Bearer $AUTH_TOKEN' \
    | grep -q '\\['"

# Test 9: Create Playlist
run_test "Create playlist" "curl -s -X POST '$API_BASE/playlists' \
    -H 'Authorization: Bearer $AUTH_TOKEN' \
    -H 'Content-Type: application/json' \
    -d '{\"name\":\"Test Playlist\"}' \
    | grep -q 'Test Playlist'"

# Test 10: WebSocket Connection
echo -e "\n🔗 Testing WebSocket Connection..."
run_test "WebSocket connection" "timeout 5 node -e \"
    const io = require('socket.io-client');
    const socket = io('$SERVER_URL');
    socket.on('connect', () => {
        console.log('Connected');
        process.exit(0);
    });
    socket.on('disconnect', () => process.exit(1));
    setTimeout(() => process.exit(1), 4000);
\""

# Test 11: File Upload Endpoint
echo -e "\n📁 Testing File Upload..."
run_test "File upload endpoint" "curl -s -X POST '$API_BASE/books/upload' \
    -H 'Authorization: Bearer $AUTH_TOKEN' \
    -F 'file=@/dev/null' \
    | grep -q 'error\\|success'"

# Test 12: Rate Limiting
echo -e "\n🚦 Testing Rate Limiting..."
run_test "Rate limiting active" "
    for i in {1..6}; do
        curl -s '$API_BASE/auth/login' \
            -H 'Content-Type: application/json' \
            -d '{\"username\":\"invalid\",\"password\":\"invalid\"}' > /dev/null
    done
    curl -s '$API_BASE/auth/login' \
        -H 'Content-Type: application/json' \
        -d '{\"username\":\"invalid\",\"password\":\"invalid\"}' \
        | grep -q 'Too many requests'
"

# Test 13: Input Validation
echo -e "\n✅ Testing Input Validation..."
run_test "Input validation" "curl -s -X POST '$API_BASE/auth/register' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"\",\"password\":\"123\"}' \
    | grep -q 'error\\|validation'"

# Test 14: CORS Headers
echo -e "\n🌐 Testing CORS Headers..."
run_test "CORS headers present" "curl -s -I '$API_BASE/health' \
    | grep -q 'Access-Control-Allow-Origin'"

# Test 15: Security Headers
echo -e "\n🔒 Testing Security Headers..."
run_test "Security headers present" "curl -s -I '$SERVER_URL' \
    | grep -q 'X-Content-Type-Options'"

# Test Results Summary
echo -e "\n" 
echo "================================================"
echo "📋 TEST RESULTS SUMMARY"
echo "================================================"
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! The Book Sphere application is working correctly.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the server logs and fix the issues.${NC}"
    exit 1
fi