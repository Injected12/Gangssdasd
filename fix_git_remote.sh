#!/bin/bash
# Script to fix git remote issues

# Remove existing origin
git remote remove origin

# Add the correct origin with proper formatting
git remote add origin https://github.com/Injected12/gngnsnturf.git

# Verify the remote
git remote -v

echo "Git remote has been reconfigured. To push your changes, use: git push -u origin main"
