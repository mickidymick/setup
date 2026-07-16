#!/usr/bin/env bash
# Claude Code statusLine command
# Reads JSON from stdin and outputs:
#   Ctx: [#####---------------] 28%  5hr: [#######-------------] 39% (resets in 3:11)

input=$(cat)

make_bar() {
    local pct="$1"
    local width=20
    # clamp to 0-100
    if [ -z "$pct" ] || [ "$pct" = "null" ]; then pct=0; fi
    local pct_int
    pct_int=$(printf '%.0f' "$pct")
    if [ "$pct_int" -lt 0 ]; then pct_int=0; fi
    if [ "$pct_int" -gt 100 ]; then pct_int=100; fi
    local filled=$(( pct_int * width / 100 ))
    local empty=$(( width - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar="${bar}#"; done
    for (( i=0; i<empty; i++ )); do bar="${bar}-"; done
    printf "%s" "$bar"
}

# --- Context bar ---
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -z "$ctx_pct" ]; then
    ctx_bar="$(make_bar 0)"
    ctx_pct_int=0
else
    ctx_bar="$(make_bar "$ctx_pct")"
    ctx_pct_int=$(printf '%.0f' "$ctx_pct")
fi

# --- 5-hour rate limit bar ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

if [ -z "$five_pct" ]; then
    # 5hr data not yet available (no API response yet this session)
    printf "Ctx: [%s] %d%%" "$ctx_bar" "$ctx_pct_int"
    exit 0
fi

five_bar="$(make_bar "$five_pct")"
five_pct_int=$(printf '%.0f' "$five_pct")

# --- Countdown to reset ---
reset_str=""
if [ -n "$five_resets" ] && [ "$five_resets" != "null" ]; then
    now=$(date +%s)
    diff=$(( five_resets - now ))
    if [ "$diff" -lt 0 ]; then diff=0; fi
    hours=$(( diff / 3600 ))
    mins=$(( (diff % 3600) / 60 ))
    reset_str=" (resets in ${hours}:$(printf '%02d' "$mins"))"
fi

printf "Ctx: [%s] %d%%  5hr: [%s] %d%%%s" \
    "$ctx_bar" "$ctx_pct_int" \
    "$five_bar" "$five_pct_int" \
    "$reset_str"
