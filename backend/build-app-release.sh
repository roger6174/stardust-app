#!/bin/bash

# Build Release Script for Stardust App Backend
# Creates deployment package for AWS EC2

set -e  # Exit on any error

echo "🚀 Starting build process for Stardust App Backend..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Clean previous builds
print_status "Cleaning previous builds..."
rm -rf release
mkdir -p release

# Build Backend
print_status "Building App Backend..."
npm install

print_status "Bundling Backend with esbuild..."
npx esbuild src/app.js --bundle --platform=node --target=node18 --outfile=dist/bundle.js --minify

print_status "Creating backend executable from bundle (app.jar)..."
npx pkg dist/bundle.js --targets node18-linux-x64 --output release/app
mv release/app release/app.jar
print_status "App backend executable created: release/app.jar"

# Copy Backend Environment Configuration
if [ -f ".env" ]; then
    cp .env release/.env
    print_status "Backend .env included in release"
else
    print_warning ".env not found - you will need to create it manually on EC2"
fi

# Copy SSL Certificate for RDS
if [ -f "global-bundle.pem" ]; then
    cp global-bundle.pem release/global-bundle.pem
    print_status "RDS SSL Certificate included in release"
else
    print_warning "global-bundle.pem not found - DB connections might fail in prod"
fi

# Create version info
print_status "Creating version information..."
echo "Build Date: $(date)" > release/VERSION.txt

cat > release/DEPLOYMENT_INFO.txt << EOF
Stardust App Backend - Deployment Package
Target: AWS EC2 (stardust-server)
Port: 5099
Service Name: stardust-app

Directory Structure:
├── app.jar                # Backend binary
├── .env                   # Backend credentials (DB/JWT/RDS)
└── global-bundle.pem      # RDS Certificate

Built on: $(date)
EOF

print_status "🎉 Build completed successfully!"
print_status "Release folder: ./release"
print_status "Now you can drag everything from the 'release' folder to your Termius SFTP (mobile-backend)."
