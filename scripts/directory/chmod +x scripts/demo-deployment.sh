#!/bin/bash

set -e

# Function to check if a livestream is running
check_livestream() {
    # Replace this with your actual check
    curl -s http://your-app.fly.dev/livestream-status | grep -q "LIVE"
}

# Function to check if the old machine is destroyed
check_old_machine_destroyed() {
    # Replace this with your actual check
    ! fly status | grep -q "old-version"
}

echo "Starting livestream..."
# Replace this with your actual command to start a livestream
curl -X POST http://your-app.fly.dev/start-livestream

sleep 10  # Wait for livestream to initialize

if check_livestream; then
    echo "Livestream started successfully."
else
    echo "Failed to start livestream."
    exit 1
fi

echo "Triggering deployment..."
fly deploy

echo "Waiting for deployment to complete..."
fly status --watch

echo "Checking if livestream is still running..."
if check_livestream; then
    echo "Livestream is still running after deployment."
else
    echo "Livestream was interrupted during deployment."
    exit 1
fi

echo "Stopping livestream..."
# Replace this with your actual command to stop a livestream
curl -X POST http://your-app.fly.dev/stop-livestream

sleep 10  # Wait for livestream to stop

echo "Checking if old machine is destroyed..."
if check_old_machine_destroyed; then
    echo "Old machine was successfully destroyed."
else
    echo "Old machine is still running."
    exit 1
fi

echo "Demo completed successfully!"