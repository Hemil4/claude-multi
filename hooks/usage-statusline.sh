#!/usr/bin/env bash
# claude-multi status line — shows REAL usage data from Claude Code
# Responsive: adapts to terminal width

input=$(cat)

# Extract data from Claude Code JSON (piped via stdin)
FIVE_HR=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
SEVEN_DAY=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
SEVEN_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')

# Profile detection
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-}"
if [ -z "$CONFIG_DIR" ]; then
    PROFILE="default"
else
    DIRNAME=$(basename "$CONFIG_DIR")
    PROFILE="${DIRNAME#.claude-}"
fi

# Shorten model name
short_model() {
    local m="$1"
    case "$m" in
        *"Opus"*)   echo "Opus" ;;
        *"Sonnet"*) echo "Sonnet" ;;
        *"Haiku"*)  echo "Haiku" ;;
        *)          echo "$m" ;;
    esac
}
MODEL_SHORT=$(short_model "$MODEL")

# Terminal width
COLS="${COLUMNS:-0}"
if [ "$COLS" -eq 0 ]; then
    COLS=$(tput cols 2>/dev/null || echo 0)
fi
if [ "$COLS" -eq 0 ]; then
    COLS=$(stty size < /dev/tty 2>/dev/null | awk '{print $2}' || echo 0)
fi
if [ "$COLS" -eq 0 ]; then
    COLS=120
fi

# Colors
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# Color based on percentage
pct_color() {
    local p="${1:-0}"
    p=$(echo "$p" | cut -d. -f1)
    if [ "$p" -ge 80 ]; then echo "$RED"
    elif [ "$p" -ge 50 ]; then echo "$YELLOW"
    else echo "$GREEN"
    fi
}

# Progress bar
make_bar() {
    local pct="${1:-0}"
    local width="${2:-10}"
    pct=$(echo "$pct" | cut -d. -f1)
    local filled=$(( (pct * width) / 100 ))
    [ "$filled" -gt "$width" ] && filled=$width
    local empty=$(( width - filled ))
    local color
    color=$(pct_color "$pct")
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo "${color}${bar}${RESET}"
}

# Format reset time
format_reset() {
    local ts="$1"
    [ -z "$ts" ] || [ "$ts" = "null" ] && return
    date -r "$ts" '+%-I:%M%p' 2>/dev/null || date -d "@$ts" '+%-I:%M%p' 2>/dev/null || echo ""
}

# Format cost
format_cost() {
    local c="$1"
    [ "$c" = "0" ] || [ "$c" = "null" ] && return
    printf "\$%.2f" "$c"
}

# ── Build responsive output ──────────────────────────────────────────────

FIVE_PCT=$(echo "${FIVE_HR:-0}" | cut -d. -f1)
SEVEN_PCT=$(echo "${SEVEN_DAY:-0}" | cut -d. -f1)
FIVE_TIME=$(format_reset "$FIVE_RESET")
SEVEN_TIME=$(format_reset "$SEVEN_RESET")
COST_STR=$(format_cost "$COST")

FIVE_COLOR=$(pct_color "$FIVE_PCT")
SEVEN_COLOR=$(pct_color "$SEVEN_PCT")

if [ "$COLS" -ge 120 ]; then
    # ── Wide: full detail with bars ──
    BAR=$(make_bar "$FIVE_PCT" 10)
    OUT="${BOLD}${PROFILE}${RESET} ${DIM}${MODEL_SHORT}${RESET}"
    [ -n "$FIVE_HR" ] && OUT+=" | ${BAR} ${FIVE_PCT}%"
    [ -n "$FIVE_TIME" ] && OUT+=" ${DIM}reset ${FIVE_TIME}${RESET}"
    [ -n "$SEVEN_DAY" ] && OUT+=" | Wk: ${SEVEN_COLOR}${SEVEN_PCT}%${RESET}"
    [ -n "$SEVEN_TIME" ] && OUT+=" ${DIM}${SEVEN_TIME}${RESET}"
    OUT+=" | Ctx: ${CTX_PCT}%"
    [ -n "$COST_STR" ] && OUT+=" | ${COST_STR}"

elif [ "$COLS" -ge 90 ]; then
    # ── Medium: bar + percentages, no reset times ──
    BAR=$(make_bar "$FIVE_PCT" 8)
    OUT="${BOLD}${PROFILE}${RESET} ${DIM}${MODEL_SHORT}${RESET}"
    [ -n "$FIVE_HR" ] && OUT+=" | ${BAR} ${FIVE_PCT}%"
    [ -n "$SEVEN_DAY" ] && OUT+=" | Wk: ${SEVEN_COLOR}${SEVEN_PCT}%${RESET}"
    OUT+=" | Ctx: ${CTX_PCT}%"
    [ -n "$COST_STR" ] && OUT+=" | ${COST_STR}"

elif [ "$COLS" -ge 60 ]; then
    # ── Narrow: compact percentages only ──
    OUT="${BOLD}${PROFILE}${RESET}"
    [ -n "$FIVE_HR" ] && OUT+=" ${FIVE_COLOR}S:${FIVE_PCT}%${RESET}"
    [ -n "$SEVEN_DAY" ] && OUT+=" ${SEVEN_COLOR}W:${SEVEN_PCT}%${RESET}"
    OUT+=" C:${CTX_PCT}%"
    [ -n "$COST_STR" ] && OUT+=" ${COST_STR}"

else
    # ── Very narrow: just session percentage ──
    OUT="${PROFILE}"
    [ -n "$FIVE_HR" ] && OUT+=" ${FIVE_COLOR}${FIVE_PCT}%${RESET}"
fi

echo -e "$OUT"
