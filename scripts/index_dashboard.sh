#!/bin/bash

set -u

if [ $# -ne 1 ]; then
    echo "Usage: $0 <index-alias>"
    echo "Example: $0 auto"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INDEX_FILE="$REPO_ROOT/watchlists/indices.txt"
INDEX_INPUT="$1"
INDEX_ALIAS="$(echo "$INDEX_INPUT" | tr '[:upper:]' '[:lower:]')"
TMP_INDEX_FILE="$(mktemp)"

cleanup() {
    rm -f "$TMP_INDEX_FILE"
}
trap cleanup EXIT

# Keep the supported aliases in one place and reuse the repo watchlist as the source of truth.
# Canonical names use the nifty-prefix convention; legacy short names are still accepted for compatibility.
declare -A INDEX_ALIASES=(
    [nifty50]="nifty50"
    [nifty]="nifty50"
    [niftyauto]="niftyauto"
    [auto]="niftyauto"
    [niftybank]="niftybank"
    [niftybanknifty]="niftybank"
    [banknifty]="niftybank"
    [niftycommodities]="niftycommodities"
    [commodities]="niftycommodities"
    [niftyconsumption]="niftyconsumption"
    [consumption]="niftyconsumption"
    [niftyenergy]="niftyenergy"
    [energy]="niftyenergy"
    [niftyfmcg]="niftyfmcg"
    [fmcg]="niftyfmcg"
    [niftyinfra]="niftyinfra"
    [infra]="niftyinfra"
    [niftyit]="niftyit"
    [it]="niftyit"
    [niftymedia]="niftymedia"
    [media]="niftymedia"
    [niftymetal]="niftymetal"
    [metal]="niftymetal"
    [niftymidcap150]="niftymidcap150"
    [midcap150]="niftymidcap150"
    [niftynext50]="niftynext50"
    [next50]="niftynext50"
    [niftypharma]="niftypharma"
    [pharma]="niftypharma"
    [niftypsubank]="niftypsubank"
    [psubank]="niftypsubank"
    [niftyrealty]="niftyrealty"
    [realty]="niftyrealty"
    [niftysmallcap250]="niftysmallcap250"
    [niftysmlcap250]="niftysmallcap250"
    [smlcap250]="niftysmallcap250"
    [smallcap250]="niftysmallcap250"
)

declare -A INDEX_CSV_NAMES=(
    [nifty50]="nifty50list"
    [niftyauto]="niftyautolist"
    [niftybank]="niftybanklist"
    [niftycommodities]="niftycommoditieslist"
    [niftyconsumption]="niftyconsumptionlist"
    [niftyenergy]="niftyenergylist"
    [niftyfmcg]="niftyfmcglist"
    [niftyinfra]="niftyinfralist"
    [niftyit]="niftyitlist"
    [niftymedia]="niftymedialist"
    [niftymetal]="niftymetallist"
    [niftymidcap150]="niftymidcap150list"
    [niftynext50]="niftynext50list"
    [niftypharma]="niftypharmalist"
    [niftypsubank]="niftypsubanklist"
    [niftyrealty]="niftyrealtylist"
    [niftysmallcap250]="niftysmallcap250list"
)

if [[ -n "${INDEX_ALIASES[$INDEX_ALIAS]:-}" ]]; then
    INDEX_ALIAS="${INDEX_ALIASES[$INDEX_ALIAS]}"
fi

if ! grep -Eq "^${INDEX_ALIAS}$" "$INDEX_FILE" 2>/dev/null; then
    echo "Unsupported index alias: $INDEX_INPUT"
    echo "Supported aliases from watchlists/indices.txt:"
    cat "$INDEX_FILE" 2>/dev/null || echo "(watchlist not found)"
    exit 1
fi

# Try to use a dedicated watchlist file if one already exists for this alias.
if [ -f "$REPO_ROOT/watchlists/${INDEX_ALIAS}.txt" ]; then
    cp "$REPO_ROOT/watchlists/${INDEX_ALIAS}.txt" "$TMP_INDEX_FILE"
    bash "$SCRIPT_DIR/watchlist.sh" "$TMP_INDEX_FILE"
    exit 0
fi

CSV_NAME="${INDEX_CSV_NAMES[$INDEX_ALIAS]:-}"
if [ -z "$CSV_NAME" ]; then
    echo "No live constituent source is configured for $INDEX_INPUT."
    exit 1
fi

CSV_URL="https://www.niftyindices.com/IndexConstituent/ind_${CSV_NAME}.csv"
if ! curl -L -sS --fail \
    --connect-timeout 15 \
    --max-time 60 \
    -A "Mozilla/5.0" \
    -e "https://www.niftyindices.com/" \
    "$CSV_URL" \
    -o "$TMP_INDEX_FILE"; then
    echo "Unable to download constituents for $INDEX_INPUT."
    exit 1
fi

python3 - "$TMP_INDEX_FILE" <<'PY'
import csv
import sys

path = sys.argv[1]
with open(path, newline='', encoding='utf-8-sig') as source:
    rows = csv.DictReader(source)
    symbols = [row['Symbol'].strip() for row in rows if row.get('Symbol', '').strip()]

with open(path, 'w', encoding='utf-8') as destination:
    destination.write('\n'.join(symbols))
    if symbols:
        destination.write('\n')
PY

if [ ! -s "$TMP_INDEX_FILE" ]; then
    echo "The constituent source returned no symbols for $INDEX_INPUT."
    exit 1
fi

bash "$SCRIPT_DIR/watchlist.sh" "$TMP_INDEX_FILE"
