#!/bin/zsh

# Directory for your GitHub repository (already initialized)
REPO_DIR="/Users/xfolders/xpray"

# Function to make commits based on the pattern
make_commits() {
    local date="$1"
    local count="$2"
    
    cd "$REPO_DIR" || exit 1
    
    for ((i=1; i<=count; i++)); do
        # Create or modify the commit_log.txt file
        echo "Commit $i on $date" >> commit_log.txt
        
        # Add the file to git staging
        git add commit_log.txt
        
        # Commit the change with a specific date
        GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" git commit -m "Commit $i for $date"
    done
}

# Setup the commit log file if it doesn't exist yet
setup_commit_log() {
    cd "$REPO_DIR" || exit 1
    
    # Create commit_log.txt if it doesn't exist
    if [[ ! -f "commit_log.txt" ]]; then
        echo "# GitHub Contribution Pattern Log" > commit_log.txt
        echo "Pattern started on $(date)" >> commit_log.txt
        echo "----------------------------" >> commit_log.txt
        
        # Initial commit for log file
        git add commit_log.txt
        git commit -m "Initialize commit log for pattern generation"
    fi
}

# Read and parse the pattern file
pattern=$(cat /Users/xfolders/spray/pattern-gbbpvo.json)
pattern=$(echo "$pattern" | tr -d '[],"' | tr -d '\n')

# Setup the commit log file
setup_commit_log

# Get today's date
TODAY=$(date +"%Y-%m-%d")
echo "Today is $TODAY"

# Find the most recent Sunday relative to today
# The %u format gives day of week 1-7 (Monday-Sunday)
# The %w format gives day of week 0-6 (Sunday-Saturday)
get_recent_sunday() {
    # First try %w format (0=Sunday to 6=Saturday)
    local day_of_week=$(date +%w 2>/dev/null)
    
    # If that fails, try %u format (1=Monday to 7=Sunday) and convert
    if [[ -z "$day_of_week" ]]; then
        local day_num=$(date +%u 2>/dev/null)
        if [[ "$day_num" -eq 7 ]]; then
            day_of_week=0  # Sunday
        else
            day_of_week=$day_num  # 1-6 for Monday-Saturday
        fi
    fi
    
    # Calculate days to go back to reach the most recent Sunday
    # If today is Sunday (0), days_back is 0
    local days_back=$day_of_week
    
    # Generate the date for the most recent Sunday
    if command -v gdate &>/dev/null; then
        # GNU date command (gdate)
        gdate -d "$TODAY - $days_back days" +"%Y-%m-%d"
    else
        # Try macOS date command
        date -j -v-"${days_back}"d -f "%Y-%m-%d" "$TODAY" +"%Y-%m-%d" 2>/dev/null || \
        # Fallback to GNU date syntax
        date -d "$TODAY - $days_back days" +"%Y-%m-%d"
    fi
}

START_DATE=$(get_recent_sunday)
echo "Starting pattern from $START_DATE (most recent Sunday)"

# Process the pattern
day=0

for ((i=0; i<${#pattern}; i++)); do
    char="${pattern:$i:1}"
    
    # Skip spaces
    if [[ "$char" == " " ]]; then
        continue
    fi
    
    # Calculate the date for this position
    # Try macOS date command first
    current_date=$(date -j -f "%Y-%m-%d" -v+"$day"d "$START_DATE" "+%Y-%m-%d 12:00:00" 2>/dev/null)
    
    # If macOS date command fails, try Linux style as fallback
    if [[ $? -ne 0 ]]; then
        current_date=$(date -d "$START_DATE + $day days" "+%Y-%m-%d 12:00:00" 2>/dev/null)
        
        # If both fail, you might need to use gdate from coreutils
        if [[ $? -ne 0 && -x "$(command -v gdate)" ]]; then
            current_date=$(gdate -d "$START_DATE + $day days" "+%Y-%m-%d 12:00:00")
        fi
    fi
    
    # If the character is a digit, make that many commits
    if [[ "$char" =~ [0-9] ]]; then
        count=$char
        if [[ $count -gt 0 ]]; then
            make_commits "$current_date" "$count"
        fi
    fi
    
    day=$((day + 1))
done

# Push all commits
cd "$REPO_DIR" || exit 1
git push origin main || git push origin master