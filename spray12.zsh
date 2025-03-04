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
        echo "Pacman and Ghost Pattern for 2012" >> commit_log.txt
        echo "----------------------------" >> commit_log.txt
        
        # Initial commit for log file
        git add commit_log.txt
        git commit -m "Initialize commit log for Pacman pattern generation"
    fi
}

# Create a pattern for Pacman and a ghost
# This is a 7x30 grid (7 days of the week x ~30 weeks)
create_pacman_ghost_pattern() {
    cat > pacman_ghost_pattern.txt << EOL
                             4 4 4     
                           4 4 4 4 4   
                         4 4 4 4 4 4 4 
                         4 4 4 4 4 4 4 
     3 3 3 3             4 4   4   4 4 
   3 3 3 3 3 3           4 4 4 4 4 4 4 
 3 3 3 3 3 3 3 3         4 4 4 4 4 4 4 
 3 3 3 3   3 3 3               2       
 3 3 3       3 3         2   2         
 3 3             2 2   2   2           
 3                 2   2               
                     2                 
EOL
    echo "Created Pacman and ghost pattern in pacman_ghost_pattern.txt"
}

# Convert multi-line pattern to a format we can process
process_pattern() {
    local pattern_file="$1"
    local processed_file="processed_pattern.txt"
    
    # Get the number of rows and columns
    local rows=$(wc -l < "$pattern_file")
    local cols=$(head -1 "$pattern_file" | wc -c)
    
    # Create a 2D array that we can index by [col][row]
    # This transposes the pattern to match GitHub's display (columns are weeks, rows are days)
    for ((row=1; row<=rows; row++)); do
        line=$(sed -n "${row}p" "$pattern_file")
        for ((col=1; col<=cols; col++)); do
            char="${line:$((col-1)):1}"
            echo -n "$char" >> "$processed_file"
        done
        echo "" >> "$processed_file"
    done
    
    echo "Processed pattern for GitHub contribution graph format"
    return 0
}

# Setup the commit log file
setup_commit_log

# Create the pattern file
create_pacman_ghost_pattern

# Set the start date to January 1, 2012 (this was a Sunday)
START_DATE="2012-01-01"
echo "Starting pattern from $START_DATE (first Sunday of 2012)"

# Process the pattern line by line, treating each character as a day
# The pattern is read line by line, with each line representing a day of the week
# and each column representing a week
row=0
while IFS= read -r line; do
    col=0
    while [ $col -lt ${#line} ]; do
        char="${line:$col:1}"
        
        # Skip spaces by not making any commits
        if [[ "$char" =~ [0-9] ]]; then
            count=$char
            
            # Calculate the date: START_DATE + (weeks * 7) + day_of_week
            # col is the week number, row is the day of week (0-6)
            days_to_add=$((col * 7 + row))
            
            # Format the date properly
            if command -v gdate &>/dev/null; then
                # GNU date
                current_date=$(gdate -d "$START_DATE + $days_to_add days" "+%Y-%m-%d 12:00:00")
            else
                # Try BSD date (macOS)
                current_date=$(date -j -v+"$days_to_add"d -f "%Y-%m-%d" "$START_DATE" "+%Y-%m-%d 12:00:00" 2>/dev/null)
                
                # Fallback to regular date
                if [[ $? -ne 0 ]]; then
                    current_date=$(date -d "$START_DATE + $days_to_add days" "+%Y-%m-%d 12:00:00")
                fi
            fi
            
            # Make the commits
            if [[ $count -gt 0 ]]; then
                echo "Making $count commits for $current_date (Week $col, Day $row)"
                make_commits "$current_date" "$count"
            fi
        fi
        
        ((col++))
    done
    
    ((row++))
    # Reset row to 0 after we reach Sunday (day 6)
    if [[ $row -ge 7 ]]; then
        row=0
    fi
done < pacman_ghost_pattern.txt

# Push all commits
cd "$REPO_DIR" || exit 1
echo "Pushing commits to remote repository..."
git push origin main || git push origin master
echo "Pattern generation complete!"