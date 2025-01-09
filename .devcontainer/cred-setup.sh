#!/bin/bash

# Create a temporary directory for our work
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Get the list of credentials and save to a temporary file
docker-credential-osxkeychain list > "$TEMP_DIR/cred_list.json"

# Initialize the final config structure
echo '{"auths":{}}' > "$TEMP_DIR/config.json"

# Process each credential
jq -r 'keys[]' "$TEMP_DIR/cred_list.json" | while read -r registry; do
    if [[ "$registry" == *"access-token"* ]] || [[ "$registry" == *"refresh-token"* ]]; then
        echo "Skipping $registry (contains filtered terms)"
        continue
    fi

    # Get the full credential details
    echo "$registry" | docker-credential-osxkeychain get > "$TEMP_DIR/cred_details.json"
    
    # Extract username and password
    username=$(jq -r '.Username' "$TEMP_DIR/cred_details.json")
    secret=$(jq -r '.Secret' "$TEMP_DIR/cred_details.json")
    
    # Create the auth token (base64 encoded username:password)
    auth_token=$(echo -n "${username}:${secret}" | base64)
    
    # Ensure registry URL ends with a forward slash
    registry_url="${registry%/}/"
    
    # Add this credential to the config file
    jq --arg url "$registry_url" --arg auth "$auth_token" \
        '.auths += {($url): {"auth": $auth}}' "$TEMP_DIR/config.json" > "$TEMP_DIR/config.json.tmp" \
        && mv "$TEMP_DIR/config.json.tmp" "$TEMP_DIR/config.json"
done

mkdir -p .docker

# Backup existing config if it exists
if [ -f .docker/config.json ]; then
    cp .docker/config.json .docker/config.json.backup
fi

# Move the new config into place
cp "$TEMP_DIR/config.json" .docker/config.json

echo "Docker credentials have been successfully migrated to .docker/config.json"
echo "A backup of your old config (if it existed) can be found at .docker/config.json.backup"
