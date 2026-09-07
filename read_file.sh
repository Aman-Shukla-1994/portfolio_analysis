#!/bin/bash

# Ensure an argument was given
if [ -z "$1" ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

# Define ANSI Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color (Resets text)

# Create a temporary workspace file for sorting
TMP_DASH=$(mktemp)
trap 'rm -f "$TMP_DASH"' EXIT

# Print a structured header row with clean alignment spacing
printf "%-15s %-25s %-10s %-10s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s\n" \
       "SYMBOL" "ACTION" "FROM 52W LOW" "FROM 52W HIGH" "1W" "1M" "3M" "6M" "YTD" "1Y" "3Y" "5Y"
echo "-----------------------------------------------------------------------------------------------------------------------------------"

# Function to add color tokens to text based on indicators
get_color_token() {
    local val="$1"
    if [[ "$val" == +* ]]; then
        echo "G"
    elif [[ "$val" == -* ]]; then
        echo "R"
    else
        echo "N"
    fi
}

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    # Strip carriage returns to fix Windows formatting bugs
    line=$(echo "$raw_line" | tr -d '\r')
    
    if [ -z "$line" ]; then
        continue
    fi

    # Run script and retain the exit status so failed symbols remain visible.
    bash tranches.sh "$line" > output.txt 2>&1
    tranche_status=$?

    # Pull the percentage distance from the 52-week range.
    lo52=$(grep "From 52W Low" output.txt | cut -d : -f2 | xargs)
    hi52=$(grep "From 52W High" output.txt | cut -d : -f2 | xargs)

    ac=$(grep "ACTION" output.txt | cut -d : -f2 | xargs)
    w1=$(grep "1W" output.txt | cut -d : -f2 | xargs)
    m1=$(grep "1M" output.txt | cut -d : -f2 | xargs)
    m3=$(grep "3M" output.txt | cut -d : -f2 | xargs)
    m6=$(grep "6M" output.txt | cut -d : -f2 | xargs)
    yt=$(grep "YTD" output.txt | cut -d : -f2 | xargs)
    y1=$(grep "1Y" output.txt | cut -d : -f2 | xargs)
    y3=$(grep "3Y" output.txt | cut -d : -f2 | xargs)
    y5=$(grep "5Y" output.txt | cut -d : -f2 | xargs)

    if [ -n "$ac" ]; then
        # Determine Color Token for Action Status Column
        if [[ "$ac" == *"ACCUMULATE"* ]]; then
            col_tok="G"
        elif [[ "$ac" == *"WAIT"* ]] || [[ "$ac" == *"CAUTION"* ]]; then
            col_tok="R"
        else
            col_tok="Y"
        fi

        # Get color tokens for percentages
        t_lo52=$(get_color_token "$lo52")
        t_hi52=$(get_color_token "$hi52")
        t_w1=$(get_color_token "$w1")
        t_m1=$(get_color_token "$m1")
        t_m3=$(get_color_token "$m3")
        t_m6=$(get_color_token "$m6")
        t_yt=$(get_color_token "$yt")
        t_y1=$(get_color_token "$y1")
        t_y3=$(get_color_token "$y3")
        t_y5=$(get_color_token "$y5")

        # =========================================================================
        # REVISED ACTION SORTING PRIORITY LIST
        # =========================================================================
        if [[ "$ac" == "ACCUMULATE - UPTREND" ]]; then
            rank="A"
        elif [[ "$ac" == "CAUTIOUS ACCUMULATION" ]]; then
            rank="B"
        elif [[ "$ac" == "CAUTION - BEARISH BIAS" ]]; then
            rank="C"
        elif [[ "$ac" == "MIXED - WAIT" ]]; then
            rank="D"
        elif [[ "$ac" == "WAIT - DOWNTREND" ]]; then
            rank="E"
        elif [[ "$ac" == "WAIT - STRONG DOWNTREND" ]]; then
            rank="F"
        else
            # Fallback for unexpected labels
            rank="G"
        fi

        # Save raw values alongside color map blueprints to temporary file
        echo "$rank|$line|$ac|$col_tok|$lo52|$t_lo52|$hi52|$t_hi52|$w1|$t_w1|$m1|$t_m1|$m3|$t_m3|$m6|$t_m6|$yt|$t_yt|$y1|$t_y1|$y3|$t_y3|$y5|$t_y5" >> "$TMP_DASH"
    elif [ "$tranche_status" -ne 0 ]; then
        # Do not silently discard symbols whose market data could not be read.
        echo "G|$line|ERROR|Y|N/A|N|N/A|N|N/A|N|N/A|N|N/A|N|N/A|N|N/A|N|N/A|N|N/A|N|N/A|N" >> "$TMP_DASH"
    fi
    
    rm -f output.txt
done < "$1"

# Helper to map a single token back to full ANSI code wrapper text
apply_color() {
    local text="$1"
    local tok="$2"
    if [ "$tok" = "G" ]; then echo -ne "${GREEN}${text}${NC}";
    elif [ "$tok" = "R" ]; then echo -ne "${RED}${text}${NC}";
    elif [ "$tok" = "Y" ]; then echo -ne "${YELLOW}${text}${NC}";
    else echo -ne "$text"; fi
}

# Read, sort by priority rank field (A -> B -> C -> D -> E -> F), and print
sort -t'|' -k1,1 "$TMP_DASH" | while IFS='|' read -r r symbol action c_tok lo52 t_lo52 hi52 t_hi52 w1 t_w1 m1 t_m1 m3 t_m3 m6 t_m6 yt t_yt y1 t_y1 y3 t_y3 y5 t_y5; do
    # Print out the base symbols
    printf "%-15s " "$symbol"
    
    # Render Action block inside its own colored wrapper zone
    if [ "$c_tok" = "G" ]; then echo -ne "${GREEN}"; elif [ "$c_tok" = "R" ]; then echo -ne "${RED}"; else echo -ne "${YELLOW}"; fi
    printf "%-25s${NC} " "$action"

    # Render the percentage distance from the 52-week range.
    apply_color "$(printf "%-8s" "$lo52")" "$t_lo52"; echo -n " "
    apply_color "$(printf "%-8s" "$hi52")" "$t_hi52"; echo -n " "

    # Render remaining timeline percentage columns individually
    apply_color "$(printf "%-8s" "$w1")" "$t_w1"; echo -n " "
    apply_color "$(printf "%-8s" "$m1")" "$t_m1"; echo -n " "
    apply_color "$(printf "%-8s" "$m3")" "$t_m3"; echo -n " "
    apply_color "$(printf "%-8s" "$m6")" "$t_m6"; echo -n " "
    apply_color "$(printf "%-8s" "$yt")" "$t_yt"; echo -n " "
    apply_color "$(printf "%-8s" "$y1")" "$t_y1"; echo -n " "
    apply_color "$(printf "%-8s" "$y3")" "$t_y3"; echo -n " "
    apply_color "$(printf "%-8s" "$y5")" "$t_y5"; echo ""
done

rm -f "$TMP_DASH"
