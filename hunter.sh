#!/bin/bash
# ============================================================
#   Hunter - Automated Bug Bounty Recon Framework
#   Author : Renzi
#   Usage  : ./hunter.sh -d domains.txt -w wordlist.txt [-o outdir] [-b]
# ============================================================

# ── Colors & Styles ─────────────────────────────────────────
RED='\e[1;31m'; GRN='\e[1;32m'; YLW='\e[1;33m'; BLU='\e[1;34m'
CYN='\e[1;36m'; WHT='\e[1;37m'; DIM='\e[2m'; RST='\e[0m'; BLD='\e[1m'

# ── Banner ───────────────────────────────────────────────────
banner() {
  clear
  echo -e "${CYN}"
  echo '  ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ '
  echo '  ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗'
  echo '  ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝'
  echo '  ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗'
  echo '  ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║'
  echo '  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝'
  echo -e "${RST}"
  echo -e "  ${DIM}${WHT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
  echo -e "  ${CYN}       Bug Bounty Recon Framework ${DIM}|  v2.0 by Renzi${RST}"
  echo -e "  ${DIM}${WHT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
  echo ""
}

# ── Helpers ──────────────────────────────────────────────────
section() {
  echo ""
  echo -e "  ${BLU}┌─────────────────────────────────────────────────┐${RST}"
  echo -e "  ${BLU}│${RST}  ${GRN}${BLD}$1${RST}"
  echo -e "  ${BLU}└─────────────────────────────────────────────────┘${RST}"
}
info() { echo -e "  ${CYN}[i]${RST} $1"; }
ok()   { echo -e "  ${GRN}[✔]${RST} $1"; }
warn() { echo -e "  ${YLW}[!]${RST} $1"; }
die()  { echo -e "  ${RED}[✘]${RST} $1"; exit 1; }

run() {
  local label="$1"; shift
  local bin="$1"
  if ! command -v "$bin" &>/dev/null; then
    warn "Skipping '${label}' — ${bin} not found"
    return 1
  fi
  info "Running: ${label}"
  "$@"
}

merge() { sort -u "$@" 2>/dev/null; }

# ── Usage ────────────────────────────────────────────────────
usage() {
  banner
  echo -e "  ${WHT}Usage:${RST}"
  echo -e "    ${CYN}./hunter.sh${RST} ${YLW}-d${RST} <domains.txt> ${YLW}-w${RST} <wordlist.txt> [OPTIONS]"
  echo ""
  echo -e "  ${WHT}Required:${RST}"
  echo -e "    ${YLW}-d, --domains  <file>${RST}    Domains list (one per line)"
  echo -e "    ${YLW}-w, --wordlist <file>${RST}    DNS brute-force wordlist"
  echo ""
  echo -e "  ${WHT}Options:${RST}"
  echo -e "    ${YLW}-o, --output   <dir>${RST}     Output directory ${DIM}(default: ./hunter-output)${RST}"
  echo -e "    ${YLW}-b, --background${RST}         Run in background, detach from terminal"
  echo -e "    ${YLW}-h, --help${RST}               Show this help message"
  echo ""
  echo -e "  ${WHT}Examples:${RST}"
  echo -e "    ${DIM}# Run in foreground${RST}"
  echo -e "    ${CYN}./hunter.sh -d domains.txt -w wordlist.txt${RST}"
  echo ""
  echo -e "    ${DIM}# Run in background (detached, logs to hunter-output/hunter.log)${RST}"
  echo -e "    ${CYN}./hunter.sh -d domains.txt -w wordlist.txt -o ./results -b${RST}"
  echo ""
}

# ── Check deps ───────────────────────────────────────────────
check_deps() {
  section "Checking dependencies"
  local tools=(subfinder assetfinder dnsx httpx nuclei naabu katana urlfinder ffuf uro uncover curl slicepathsurl)
  local missing=()
  for t in "${tools[@]}"; do
    if command -v "$t" &>/dev/null; then
      ok "$t"
    else
      warn "$t ${DIM}not found — some steps may be skipped${RST}"
      missing+=("$t")
    fi
  done
  [[ ${#missing[@]} -gt 0 ]] && warn "Missing: ${missing[*]}"
}

# ═══════════════════════════════════════════════════════════════
#  PARSE ARGS
# ═══════════════════════════════════════════════════════════════
DOMAINS=""
WORDLIST=""
OUTDIR="./hunter-output"
BACKGROUND=false

[[ $# -eq 0 ]] && usage && exit 0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--domains)    DOMAINS="$2";   shift 2 ;;
    -w|--wordlist)   WORDLIST="$2";  shift 2 ;;
    -o|--output)     OUTDIR="$2";    shift 2 ;;
    -b|--background) BACKGROUND=true; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo -e "  ${RED}[✘]${RST} Unknown argument: $1"; usage; exit 1 ;;
  esac
done

# ── Validate required args ───────────────────────────────────
[[ -z "$DOMAINS"  ]] && die "Missing required argument: -d <domains file>"
[[ ! -f "$DOMAINS" ]] && die "Domains file not found: ${DOMAINS}"

if [[ -z "$WORDLIST" || ! -f "$WORDLIST" ]]; then
  warn "Wordlist not provided or not found — DNS brute-force will be skipped."
  WORDLIST=""
fi

# ── Background mode ──────────────────────────────────────────
if $BACKGROUND; then
  mkdir -p "$OUTDIR"
  LOGFILE="${OUTDIR}/hunter.log"
  # Re-launch this script without -b, redirect all output to log
  nohup bash "$0" -d "$DOMAINS" ${WORDLIST:+-w "$WORDLIST"} -o "$OUTDIR" \
    > "$LOGFILE" 2>&1 &
  BG_PID=$!
  banner
  echo -e "  ${GRN}[✔]${RST} Hunter is running in the background"
  echo -e "  ${CYN}[i]${RST} PID    : ${BLD}${BG_PID}${RST}"
  echo -e "  ${CYN}[i]${RST} Log    : ${BLD}${LOGFILE}${RST}"
  echo -e "  ${CYN}[i]${RST} Monitor: ${BLD}tail -f ${LOGFILE}${RST}"
  echo -e "  ${CYN}[i]${RST} Stop   : ${BLD}kill ${BG_PID}${RST}"
  echo ""
  exit 0
fi

# ═══════════════════════════════════════════════════════════════
#  MAIN SCAN (foreground or spawned by background mode)
# ═══════════════════════════════════════════════════════════════
banner
check_deps

mkdir -p "$OUTDIR"

# ── Output directory structure ───────────────────────────────
DIR_SUBS="${OUTDIR}/subdomains"
DIR_URLS="${OUTDIR}/urls"
DIR_SCAN="${OUTDIR}/nuclei"
DIR_MISC="${OUTDIR}/misc"
mkdir -p "$DIR_SUBS" "$DIR_URLS" "$DIR_SCAN" "$DIR_MISC"

# subdomains/
SUB1="${DIR_SUBS}/subfinder.txt"
SUB2="${DIR_SUBS}/assetfinder.txt"
SUB3="${DIR_SUBS}/dnsx.txt"
SUBD="${DIR_SUBS}/all-subdomains.txt"

# urls/
HTTPX_LOG="${DIR_URLS}/live-hosts.txt"
PASS_LOG="${DIR_URLS}/passive-urls.txt"
PASS_FILT="${DIR_URLS}/passive-urls-filtered.txt"
KATA_LOG="${DIR_URLS}/katana-crawl.txt"
KATA_FILT="${DIR_URLS}/katana-filtered.txt"
SLICE_LOG="${DIR_URLS}/slice-paths.txt"
WEBARCH_H="${DIR_URLS}/webarchive-sensitive.txt"
JS_TXT="${DIR_URLS}/js-files.txt"

# nuclei/
N_HTTPX="${DIR_SCAN}/nuclei-httpx.txt"
N_SHODAN="${DIR_SCAN}/nuclei-shodan.txt"
N_DAST_PASSIVE="${DIR_SCAN}/nuclei-dast-passive.txt"
N_DAST_KATANA="${DIR_SCAN}/nuclei-dast-katana.txt"
N_SLICE="${DIR_SCAN}/nuclei-slice.txt"
N_SLICE_DAST="${DIR_SCAN}/nuclei-slice-dast.txt"
N_NAABU="${DIR_SCAN}/nuclei-naabu.txt"
N_PRIV8="${DIR_SCAN}/nuclei-coffinxp.txt"
N_JS="${DIR_SCAN}/nuclei-js.txt"

# misc/
SHODAN_Q="${DIR_MISC}/shodan-queries.txt"
SHODAN_H="${DIR_MISC}/shodan-hosts.txt"
EXCL_WEB="${DIR_MISC}/non-web-ports.txt"
WEBARCH="${DIR_MISC}/webarchive-raw.txt"
BACKUP_LOG="${DIR_MISC}/backup-files.txt"

# ─────────────────────────────────────────────────────────────
section "Phase 1 — Subdomain Enumeration"
# ─────────────────────────────────────────────────────────────

run "subfinder" subfinder -dL "$DOMAINS" -all -recursive -o "$SUB1"
run "assetfinder" bash -c "cat '$DOMAINS' | assetfinder > '$SUB2'"

if [[ -n "$WORDLIST" ]]; then
  run "dnsx" dnsx -d "$DOMAINS" -w "$WORDLIST" -o "$SUB3"
else
  warn "Skipping dnsx — no wordlist provided"
  touch "$SUB3"
fi

merge "$SUB1" "$SUB2" "$SUB3" > "$SUBD"
ok "Final subdomain count: ${BLD}$(wc -l < "$SUBD")${RST}  →  ${CYN}${SUBD}${RST}"

# ─────────────────────────────────────────────────────────────
section "Phase 3 — Live Host Probing (httpx)"
# ─────────────────────────────────────────────────────────────

run "httpx" httpx \
  -l "$SUBD" -ports 80,443,8080,8888,8443 \
  -no-fallback -mc 200,301,302,404 \
  -t 1000 -rl 300 -silent -o "$HTTPX_LOG"

ok "Live hosts: ${BLD}$(wc -l < "$HTTPX_LOG")${RST}  →  ${CYN}${HTTPX_LOG}${RST}"

# ─────────────────────────────────────────────────────────────
section "Phase 4 — Nuclei Scan (httpx targets)"
# ─────────────────────────────────────────────────────────────

run "nuclei (standard)" nuclei \
  -l "$HTTPX_LOG" -s critical,high,medium,low,unknown -c 200 -o "$N_HTTPX"

# ─────────────────────────────────────────────────────────────
section "Phase 5 — Shodan / Uncover Scan"
# ─────────────────────────────────────────────────────────────

while IFS= read -r domain; do
  echo "ssl:${domain}"
  echo "ssl.cert.subject.cn:${domain}"
  echo "hostname:${domain}"
  echo "ssl.cert.subject.cn:${domain} -HTTP"
done < "$DOMAINS" > "$SHODAN_Q"

run "uncover" bash -c "uncover -s '$SHODAN_Q' -silent | sort -u > '$SHODAN_H'"
run "nuclei (shodan)" nuclei \
  -l "$SHODAN_H" -s critical,high,medium,low,unknown -c 200 -o "$N_SHODAN"

# ─────────────────────────────────────────────────────────────
section "Phase 6 — Passive URL Collection + DAST"
# ─────────────────────────────────────────────────────────────

run "urlfinder" bash -c "
  cat '$SUBD' | urlfinder \
    -s alienvault,commoncrawl,waybackarchive,urlscan,virustotal \
    -f qurl -fs rdn -silent -o '$PASS_LOG'
"
run "httpx + uro (passive)" bash -c "sort -u '$PASS_LOG' | uro | httpx -silent > '$PASS_FILT'"
run "nuclei DAST (passive)" nuclei -l "$PASS_FILT" -dast -o "$N_DAST_PASSIVE"

# ─────────────────────────────────────────────────────────────
section "Phase 7 — Active Crawl (katana) + DAST"
# ─────────────────────────────────────────────────────────────

run "katana" bash -c "cat '$SUBD' | katana -o '$KATA_LOG' -silent"
run "httpx + uro (katana)" bash -c "cat '$KATA_LOG' | httpx -silent | uro > '$KATA_FILT'"
run "nuclei DAST (katana)" nuclei -l "$KATA_FILT" -dast -o "$N_DAST_KATANA"

# ─────────────────────────────────────────────────────────────
section "Phase 8 — SlicePath URL Scan"
# ─────────────────────────────────────────────────────────────

run "slicepathsurl + httpx" bash -c "
  cat '$KATA_FILT' '$PASS_FILT' | sort -u | uro | \
  slicepathsurl -l 3 | httpx -silent -o '$SLICE_LOG'
"
run "nuclei standard (slice)" nuclei \
  -l "$SLICE_LOG" -s critical,high,medium,low,unknown -c 200 -o "$N_SLICE"
run "nuclei DAST (slice)" nuclei -l "$SLICE_LOG" -dast -c 200 -o "$N_SLICE_DAST"

# ─────────────────────────────────────────────────────────────
section "Phase 9 — Port Scan (naabu) + Nuclei"
# ─────────────────────────────────────────────────────────────

run "naabu" naabu \
  -list "$SUBD" -verify -rate 10000 -retries 1 \
  -top-ports 1000 -exclude-ports 80,443,8080,8888,8443 \
  -c 300 -silent -o "$EXCL_WEB"

run "nuclei (non-web ports)" bash -c "
  cat '$EXCL_WEB' | nuclei -s critical,high,medium,low,unknown -c 200 -o '$N_NAABU'
"

# ─────────────────────────────────────────────────────────────
section "Phase 10 — Custom Nuclei Templates (coffinxp)"
# ─────────────────────────────────────────────────────────────

PRIV8_TEMPLATES="../coffinxp/nuclei-templates/"
if [[ -d "$PRIV8_TEMPLATES" ]]; then
  run "nuclei (priv8)" nuclei -l "$HTTPX_LOG" -t "$PRIV8_TEMPLATES" -c 200 -o "$N_PRIV8"
else
  warn "Custom templates not found at ${PRIV8_TEMPLATES} — skipping"
fi

# ─────────────────────────────────────────────────────────────
section "Phase 11 — JavaScript File Analysis"
# ─────────────────────────────────────────────────────────────

run "katana + JS grep" bash -c "
  cat '$DOMAINS' | katana | grep '\.js' | httpx -mc 200 | tee '$JS_TXT'
"
run "nuclei exposures (JS)" nuclei \
  -l "$JS_TXT" -t ~/nuclei-templates/http/exposures/ -c 200 -o "$N_JS"

# ─────────────────────────────────────────────────────────────
section "Phase 12 — Backup File Discovery (ffuf)"
# ─────────────────────────────────────────────────────────────

run "ffuf (backup files)" ffuf \
  -w "${DOMAINS}:SUB" -w "backup_files_only.txt:FILE" \
  -u "https://SUB/FILE" -mc 200 -rate 100 -fs 0 \
  -c -o "$BACKUP_LOG" -of md

# ─────────────────────────────────────────────────────────────
section "Phase 13 — Web Archive Analysis"
# ─────────────────────────────────────────────────────────────

info "Querying Wayback Machine CDX API"
while IFS= read -r domain; do
  curl -sG "https://web.archive.org/cdx/search/cdx" \
    --data-urlencode "url=*.$domain/*" \
    --data-urlencode "collapse=urlkey" \
    --data-urlencode "output=text" \
    --data-urlencode "fl=original"
done < "$DOMAINS" >> "$WEBARCH"

grep -iE "\.(xls|xml|xlsx|json|pdf|sql|doc|docx|pptx|txt|zip|tar\.gz|tgz|bak|7z|rar|cache|secret|db|backup|yml|gz|config|csv|yaml|md5|exe|dll|bin|ini|bat|sh|tar|deb|rpm|iso|img|apk|msi|dmg|tmp|crt|pem|key|pub|env|toml)(\?|$)" \
  "$WEBARCH" | \
  run "httpx (archive)" httpx -title -mc 200 -silent -o "$WEBARCH_H"

ok "Archived sensitive files: $(wc -l < "$WEBARCH_H")"

# ═══════════════════════════════════════════════════════════════
section "Scan Complete — Summary"
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "  ${DIM}${WHT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "  ${BLD}${WHT} Output: ${CYN}${OUTDIR}/${RST}"
echo -e "  ${DIM}${WHT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo ""
echo -e "  ${YLW}subdomains/${RST}"
echo -e "  ${DIM}  all-subdomains.txt         $(wc -l < "$SUBD" 2>/dev/null || echo 0) entries${RST}"
echo -e "  ${DIM}  subfinder.txt / assetfinder.txt / dnsx.txt${RST}"
echo ""
echo -e "  ${YLW}urls/${RST}"
echo -e "  ${DIM}  live-hosts.txt             $(wc -l < "$HTTPX_LOG" 2>/dev/null || echo 0) entries${RST}"
echo -e "  ${DIM}  passive-urls-filtered.txt  $(wc -l < "$PASS_FILT" 2>/dev/null || echo 0) entries${RST}"
echo -e "  ${DIM}  katana-filtered.txt        $(wc -l < "$KATA_FILT" 2>/dev/null || echo 0) entries${RST}"
echo -e "  ${DIM}  slice-paths.txt            $(wc -l < "$SLICE_LOG" 2>/dev/null || echo 0) entries${RST}"
echo ""
echo -e "  ${YLW}nuclei/${RST}"
echo -e "  ${DIM}  nuclei-httpx.txt           $(wc -l < "$N_HTTPX" 2>/dev/null || echo 0) findings${RST}"
echo -e "  ${DIM}  nuclei-shodan.txt          $(wc -l < "$N_SHODAN" 2>/dev/null || echo 0) findings${RST}"
echo -e "  ${DIM}  nuclei-dast-passive.txt    $(wc -l < "$N_DAST_PASSIVE" 2>/dev/null || echo 0) findings${RST}"
echo -e "  ${DIM}  nuclei-dast-katana.txt     $(wc -l < "$N_DAST_KATANA" 2>/dev/null || echo 0) findings${RST}"
echo -e "  ${DIM}  nuclei-slice.txt           $(wc -l < "$N_SLICE" 2>/dev/null || echo 0) findings${RST}"
echo -e "  ${DIM}  nuclei-naabu.txt           $(wc -l < "$N_NAABU" 2>/dev/null || echo 0) findings${RST}"
echo ""
echo -e "  ${YLW}misc/${RST}"
echo -e "  ${DIM}  shodan-hosts.txt / non-web-ports.txt / backup-files.txt${RST}"
echo -e "  ${DIM}  webarchive-raw.txt / webarchive-sensitive.txt${RST}"
echo ""
echo -e "  ${DIM}${WHT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo ""
ok "All results saved to: ${BLD}${OUTDIR}/${RST}"
echo -e "  ${GRN}${BLD}  Hunt complete. Happy hacking!${RST}"
echo ""
