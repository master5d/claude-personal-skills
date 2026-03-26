#!/usr/bin/env bash
# Claude Code status line — ~/.claude/statusline-command.sh
# Layout:
#   Line 1: {model} {context_bar} | ✏ {ctx_pct}% | {project_name} |
#   Line 2: session  {bar} {pct}%  ({in}in · {out}out)  🕐{time}
#   Line 3: weekly   ~{tokens} est  🕐{date}
#   Line 4: (promo) 🎁 2× off-peak → std in Xh Ym · Nd left
#   Line 5: (bypass) ►► bypass permissions on

# ── ANSI colours ──────────────────────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
WHITE='\033[37m'
ORANGE='\033[38;5;208m'
GREEN='\033[32m'

# ── Read JSON from stdin ──────────────────────────────────────────────────────
INPUT=$(cat)

# ── Helper: extract JSON field ────────────────────────────────────────────────
jq_get() { printf '%s' "$INPUT" | jq -r "$1 // empty" 2>/dev/null; }

# ── Parse fields ─────────────────────────────────────────────────────────────
MODEL_NAME=$(jq_get '.model.display_name')
CTX_SIZE=$(jq_get '.context_window.context_window_size')
USED_PCT=$(jq_get '.context_window.used_percentage')
TOTAL_IN=$(jq_get '.context_window.total_input_tokens')
TOTAL_OUT=$(jq_get '.context_window.total_output_tokens')
PROJECT_DIR=$(jq_get '.workspace.project_dir')
CWD=$(jq_get '.workspace.current_dir')

# ── Format helpers ────────────────────────────────────────────────────────────
format_num() {
  local n=$1
  if   [ -z "$n" ] || [ "$n" = "null" ]; then echo ""; return; fi
  if   [ "$n" -ge 1000000 ] 2>/dev/null; then printf '%sM' "$(( n / 1000000 ))";
  elif [ "$n" -ge 1000 ]    2>/dev/null; then printf '%sk' "$(( n / 1000 ))";
  else echo "$n"; fi
}

# ── Model label ───────────────────────────────────────────────────────────────
MODEL_SHORT="${MODEL_NAME#Claude }"
CTX_LABEL=$(format_num "$CTX_SIZE")
if [ -n "$CTX_LABEL" ]; then
  MODEL_DISPLAY="${MODEL_SHORT} (${CTX_LABEL})"
else
  MODEL_DISPLAY="${MODEL_SHORT}"
fi

# ── Project name ──────────────────────────────────────────────────────────────
PROJECT_NAME=""
if [ -n "$PROJECT_DIR" ] && [ "$PROJECT_DIR" != "null" ]; then
  PROJECT_NAME=$(basename "$PROJECT_DIR")
elif [ -n "$CWD" ] && [ "$CWD" != "null" ]; then
  PROJECT_NAME=$(basename "$CWD")
fi

# ── Dot bar ───────────────────────────────────────────────────────────────────
dot_bar() {
  local pct=${1:-0}
  local total=${2:-10}
  local filled=$(( (pct * total + 50) / 100 ))
  [ "$filled" -gt "$total" ] 2>/dev/null && filled=$total
  [ "$filled" -lt 0 ]       2>/dev/null && filled=0
  local bar=""
  for i in $(seq 1 $total); do
    if [ "$i" -le "$filled" ]; then bar="${bar}●"; else bar="${bar}○"; fi
  done
  echo "$bar"
}

# ── Color by fill level: cyan → yellow → red ─────────────────────────────────
bar_color() {
  local pct=${1:-0}
  if   [ "$pct" -ge 85 ]; then printf '%s' "$RED"
  elif [ "$pct" -ge 60 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$CYAN"
  fi
}

# ── Context bar (20 dots) — line 1 ───────────────────────────────────────────
CTX_PCT=${USED_PCT:-0}
CTX_PCT_INT=$(printf '%.0f' "$CTX_PCT" 2>/dev/null || echo 0)
CTX_BAR=$(dot_bar "$CTX_PCT_INT" 20)
CTX_COLOR=$(bar_color "$CTX_PCT_INT")

# ── Session line (line 2) — accurate, directly from input JSON ───────────────
# CTX_PCT_INT matches /usage "Current session X% used"
SESS_BAR=$(dot_bar "$CTX_PCT_INT" 10)
SESS_COLOR=$(bar_color "$CTX_PCT_INT")
SESS_IN=$(format_num "${TOTAL_IN:-0}")
SESS_OUT=$(format_num "${TOTAL_OUT:-0}")
[ -z "$SESS_IN" ]  && SESS_IN="0"
[ -z "$SESS_OUT" ] && SESS_OUT="0"
CURRENT_TIME=$(date '+%H:%M')

# ── Weekly token accumulation (line 3) — estimated across sessions ────────────
# Tracks raw token deltas; no fake budget %; shows count + "est" label
TRACKING_FILE="${HOME}/.claude/statusline-weekly.json"
NOW_DATE=$(date '+%Y-%m-%d')
NOW_TS=$(date +%s)

DAY_OF_WEEK=$(date +%u)
WEEK_START_TS=$(( NOW_TS - (DAY_OF_WEEK - 1) * 86400 ))
WEEK_START_DATE=$(date -d "@${WEEK_START_TS}" '+%Y-%m-%d' 2>/dev/null \
                  || date -r "${WEEK_START_TS}" '+%Y-%m-%d' 2>/dev/null \
                  || echo "$NOW_DATE")

SESSION_TOKENS=$(( ${TOTAL_IN:-0} + ${TOTAL_OUT:-0} ))

if [ -f "$TRACKING_FILE" ]; then
  W_START=$(jq -r '.week_start // empty'   "$TRACKING_FILE" 2>/dev/null)
  W_TOKENS=$(jq -r '.tokens // 0'         "$TRACKING_FILE" 2>/dev/null)
  W_SESSION=$(jq -r '.session_tokens // 0' "$TRACKING_FILE" 2>/dev/null)
else
  W_START=""; W_TOKENS=0; W_SESSION=0
fi

W_TOKENS=${W_TOKENS:-0};  W_SESSION=${W_SESSION:-0}
SESSION_TOKENS=${SESSION_TOKENS:-0}
[ "$W_SESSION" = "null" ] && W_SESSION=0

# Reset on new week
if [ "$W_START" != "$WEEK_START_DATE" ]; then
  W_TOKENS=0; W_SESSION=0; W_START="$WEEK_START_DATE"
fi

# Accumulate delta — only count increases (session resets handled by taking full count)
if [ "$W_SESSION" -gt 0 ] && [ "$SESSION_TOKENS" -lt "$(( W_SESSION / 2 ))" ] 2>/dev/null; then
  DELTA="$SESSION_TOKENS"                          # new session started
elif [ "$SESSION_TOKENS" -ge "$W_SESSION" ]; then
  DELTA=$(( SESSION_TOKENS - W_SESSION ))          # normal growth
else
  DELTA=0                                          # minor fluctuation, skip
fi
W_TOKENS=$(( W_TOKENS + DELTA ))

# Persist
mkdir -p "$(dirname "$TRACKING_FILE")"
printf '{"week_start":"%s","tokens":%d,"session_tokens":%d}\n' \
  "$W_START" "$((W_TOKENS))" "$((SESSION_TOKENS))" > "$TRACKING_FILE"

WEEKLY_RAW=$(format_num "$W_TOKENS")
WEEK_DATE=$(date '+%a %d %b')

# ── March 2026 promotion (Mar 13–28): 2× off-peak ────────────────────────────
format_mins() {
  local m=$1
  local d=$(( m / 1440 )) h=$(( (m % 1440) / 60 )) mm=$(( m % 60 ))
  if   [ "$d" -gt 0 ]; then printf '%dd %dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$mm"
  else printf '%dm' "$mm"; fi
}

PROMO_END_NUM="20260328"
NOW_DATE_NUM=$(date '+%Y%m%d')
if [ "$NOW_DATE_NUM" -le "$PROMO_END_NUM" ] 2>/dev/null; then
  DAYS_LEFT=$(( ( $(date -d "2026-03-29" +%s) - $(date -d "$NOW_DATE" +%s) ) / 86400 ))
  UTC_H=$(date -u '+%H'); UTC_M=$(date -u '+%M')
  RAW_ET_MIN=$(( UTC_H * 60 + UTC_M - 240 ))
  ET_DAY_NUM=$(date +%u)
  if [ "$RAW_ET_MIN" -lt 0 ]; then
    ET_TOTAL_MIN=$(( RAW_ET_MIN + 1440 ))
    ET_DAY_NUM=$(( ET_DAY_NUM - 1 ))
    [ "$ET_DAY_NUM" -lt 1 ] && ET_DAY_NUM=7
  else
    ET_TOTAL_MIN=$RAW_ET_MIN
  fi

  if [ "$ET_DAY_NUM" -le 5 ] && [ "$ET_TOTAL_MIN" -ge 480 ] && [ "$ET_TOTAL_MIN" -lt 840 ]; then
    PROMO_LABEL="standard (peak)"; PROMO_COLOR="$YELLOW"
    MINS_TO_NEXT=$(( 840 - ET_TOTAL_MIN )); NEXT_DESC="→ 2× in"
  else
    PROMO_LABEL="2× off-peak"; PROMO_COLOR="$GREEN"; NEXT_DESC="→ std in"
    if   [ "$ET_DAY_NUM" -le 5 ] && [ "$ET_TOTAL_MIN" -lt 480 ]; then
      MINS_TO_NEXT=$(( 480 - ET_TOTAL_MIN ))
    elif [ "$ET_DAY_NUM" -le 4 ]; then
      MINS_TO_NEXT=$(( 1920 - ET_TOTAL_MIN ))
    elif [ "$ET_DAY_NUM" = "5" ]; then
      MINS_TO_NEXT=$(( 4800 - ET_TOTAL_MIN ))
    elif [ "$ET_DAY_NUM" = "6" ]; then
      MINS_TO_NEXT=$(( 3360 - ET_TOTAL_MIN ))
    else
      MINS_TO_NEXT=$(( 1920 - ET_TOTAL_MIN ))
    fi
  fi
  NEXT_TIMER=$(format_mins "$MINS_TO_NEXT")
  [ "$DAYS_LEFT" = "1" ] && DAYS_STR="last day!" || DAYS_STR="${DAYS_LEFT}d left"
  PROMO_LINE=1
else
  PROMO_LINE=0
fi

# ── Bypass permissions detection ──────────────────────────────────────────────
BYPASS_ON="${CLAUDE_CODE_BYPASS_PERMISSIONS:-}"

# ── Output ────────────────────────────────────────────────────────────────────

# Line 1: model | context bar | ctx% | project
printf "${CYAN}${MODEL_DISPLAY}${RESET} ${CTX_COLOR}${CTX_BAR}${RESET} ${WHITE}|${RESET} ✏  ${CTX_COLOR}${CTX_PCT_INT}%%${RESET} ${WHITE}|${RESET} ${BOLD}${PROJECT_NAME}${RESET} ${WHITE}|${RESET}\n"

# Line 2: session — uses context_window.used_percentage directly (matches /usage)
printf "${DIM}session${RESET} ${SESS_COLOR}${SESS_BAR}${RESET} ${SESS_COLOR}${CTX_PCT_INT}%%${RESET}  ${DIM}${SESS_IN}in · ${SESS_OUT}out  🕐${CURRENT_TIME}${RESET}\n"

# Line 3: weekly accumulated tokens — raw count, labeled as estimate
printf "${DIM}weekly ${RESET} ${DIM}~${WEEKLY_RAW} est  🕐${WEEK_DATE}${RESET}\n"

# Line 4: March 2026 promotion
if [ "$PROMO_LINE" = "1" ]; then
  printf "${PROMO_COLOR}🎁 ${PROMO_LABEL}${RESET}  ${DIM}${NEXT_DESC} ${NEXT_TIMER}  ·  ${DAYS_STR}${RESET}\n"
fi

# Line 5: bypass permissions warning
if [ -n "$BYPASS_ON" ] && [ "$BYPASS_ON" = "1" ]; then
  printf "${ORANGE}►► bypass permissions on (shift+tab to cycle)${RESET}\n"
fi
