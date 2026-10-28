
#!/bin/bash

# URL replacement lookup table
# Format: "original_domain:replacement_domain"
declare -A URL_REPLACEMENTS=(
    ["x.com"]="fixupx.com"
    ["instagram.com"]="kkinstagram.com"
    # Add more replacements here as needed
    # ["reddit.com"]="libreddit.com"
    # ["youtube.com"]="invidious.io"
)

# Function to modify clipboard content based on lookup table
modify_clipboard() {
    local content="$1"
    local modified="$content"
    
    # Apply all URL replacements from the lookup table
    for original in "${!URL_REPLACEMENTS[@]}"; do
        replacement="${URL_REPLACEMENTS[$original]}"
        modified=$(echo "$modified" | sed "s|https://${original}|https://${replacement}|g")
        modified=$(echo "$modified" | sed "s|https://www\.${original}|https://${replacement}|g")
    done
    
    # Update clipboard with modified content
    echo -n "$modified" | xclip -selection clipboard
    
    # Return whether any changes were made
    if [ "$content" != "$modified" ]; then
        return 0  # Changes made
    else
        return 1  # No changes made
    fi
}

# Function to check if clipboard contains any URLs we want to replace
should_process_clipboard() {
    local content="$1"
    
    for original in "${!URL_REPLACEMENTS[@]}"; do
        if echo "$content" | grep -q "https://${original}\|https://www\.${original}"; then
            return 0  # Should process
        fi
    done
    
    return 1  # Should not process
}

# Function to log what changes were made
log_changes() {
    local original="$1"
    local modified="$2"
    
    for domain in "${!URL_REPLACEMENTS[@]}"; do
        replacement="${URL_REPLACEMENTS[$domain]}"
        if echo "$original" | grep -q "https://${domain}\|https://www\.${domain}"; then
            echo "Clipboard modified: ${domain} -> ${replacement}"
        fi
    done
}

# Main loop
echo "URL replacement monitor started..."
echo "Monitoring for URLs: ${!URL_REPLACEMENTS[*]}"

while clipnotify; do
    # Get the current clipboard content
    current_clip=$(xclip -selection clipboard -o 2>/dev/null)
    
    # Skip if clipboard is empty or contains binary data
    if [ -z "$current_clip" ] || ! echo "$current_clip" | grep -q '^[[:print:]]*$'; then
        continue
    fi
    
    # Check if the clipboard contains any URLs we want to replace
    if should_process_clipboard "$current_clip"; then
        # Store original for logging
        original_clip="$current_clip"
        
        # Modify and update the clipboard
        if modify_clipboard "$current_clip"; then
            log_changes "$original_clip" "$(xclip -selection clipboard -o 2>/dev/null)"
        fi
    fi    
done
