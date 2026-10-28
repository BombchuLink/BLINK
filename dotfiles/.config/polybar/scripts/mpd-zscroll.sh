#!/bin/bash

# MPD zscroll wrapper script
# Save as ~/.config/polybar/scripts/mpd-zscroll-wrapper.sh

# Kill any existing zscroll processes for this script
pkill -f "zscroll.*mpc"

# Function to restart zscroll when song changes
monitor_mpd() {
    local last_song=""
    local zscroll_pid=""
    
    while true; do
        current_song=$(mpc current 2>/dev/null)
        
        # If song changed, restart zscroll
        if [ "$current_song" != "$last_song" ]; then
            # Kill previous zscroll
            if [ -n "$zscroll_pid" ]; then
                kill $zscroll_pid 2>/dev/null
            fi
            
            # Start new zscroll
            zscroll -l 55 \
                --delay 0.3 \
                --match-command "mpc status" \
                --match-text "playing" "--scroll 1" \
                --match-text "paused" "--scroll 0" \
                --update-interval 0.3 \
				-p "   " \
                "$current_song" &
            
            zscroll_pid=$!
            last_song="$current_song"
        fi
        
        sleep 1
    done
}

# Start monitoring
monitor_mpd
