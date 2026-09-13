# Portfolio Analysis

A Bash-based portfolio and market-index analysis tool for Indian equities and indices. It downloads daily market data from Yahoo Finance, calculates returns and trend signals across multiple time horizons, and places each symbol into price-based tranche levels.

## Requirements

- Bash
- Python 3
- `curl`
- Standard Unix utilities: `grep`, `sed`, `sort`, `xargs`, and `mktemp`
- Network access to Yahoo Finance

The scripts are intended for a Unix-like shell. On Windows, run them through WSL or Git Bash.

## Usage

### Analyze one or more symbols

```bash
bash scripts/stock.sh RELIANCE
bash scripts/stock.sh NIFTY
bash scripts/stock.sh "RELIANCE,TCS,NIFTY"
```

The symbol is normalized to uppercase. You may provide a single symbol, multiple separate arguments, or a single comma-separated string. Regular stock symbols default to the Yahoo Finance `.NS` suffix. The repo follows a consistent Nifty-prefixed naming scheme for Nifty-linked indices. Canonical names in `watchlists/indices.txt` are:

- `nifty50`
- `niftyauto`
- `niftybank`
- `niftycommodities`
- `niftyconsumption`
- `niftyenergy`
- `niftyfmcg`
- `niftyinfra`
- `niftyit`
- `niftymedia`
- `niftymetal`
- `niftymidcap150`
- `niftynext50`
- `niftypharma`
- `niftypsubank`
- `niftyrealty`
- `niftysmallcap250`
- `sensex`

Older shorthand names such as `nifty`, `banknifty`, `metal`, and `smlcap250` remain accepted for compatibility, but the canonical repo convention is the `nifty...` prefix.

Yahoo-style symbols can also be supplied directly when needed, such as `BRITANNIA.NS` or a symbol beginning with `^`.

### Run the holdings dashboard

```bash
bash scripts/watchlist.sh watchlists/holdings.txt
```

`holdings.txt` contains one stock or index symbol per line. Blank lines are ignored. The dashboard analyzes every symbol, reports its 52-week low and high, preserves failed symbols as visible error rows, sorts results by the calculated action, and prints a colorized summary.

Available watchlists include:

- `watchlists/holdings.txt`
- `watchlists/indices.txt`
- `watchlists/investlist.txt`
- `watchlists/ipo.txt`
- `watchlists/dividendStocks.txt`
- `watchlists/globalndices.txt`

To use another watchlist:

```bash
bash scripts/watchlist.sh path/to/watchlist.txt
```

To get the 52-week low and high for every configured index:

```bash
bash scripts/watchlist.sh watchlists/indices.txt
```

To export the same compact table as CSV:

```bash
bash scripts/watchlist.sh watchlists/indices.txt output/indices.csv
bash scripts/index_dashboard.sh niftyauto output/niftyauto.csv
```

## Output

For each symbol, `stock.sh` reports:

- The latest completed trading-day close
- The percentage distance of the current close above the 52-week low and below the 52-week high
- Fundamental fields relevant to the active mode: sector, market-cap type, PE, PB, and dividend yield
- Absolute return rows for 1W, 1M, 3M, 6M, YTD, 1Y, 3Y, and 5Y
- The 52-week range block for the current symbol
- Index mode distinguishes sector/index fundamentals from stock fundamentals without showing ROE
- The console output intentionally omits tranche labels and market-cap values in the compact view

The calculator downloads a 10-year daily history and overlays a recent 10-day download so the latest available sessions are refreshed. Data is converted to India Standard Time before trading dates are selected. For recognized NSE indices, the displayed 52-week high/low and the 1M/1Y change values use the official NSE `allIndices` feed; Yahoo Finance remains the source for the broader historical return series. Stock symbols and the SENSEX continue to use Yahoo high/low data.

## Tranche calculation

The 52-week intraday low and high define the range:

```text
T0 = 52-week low
T4 = 52-week high
step = (T4 - T0) / 4
T1 = T0 + step
T2 = T0 + 2 * step
T3 = T0 + 3 * step
```

The current close is classified into the interval containing it. The display labels are simplified to `L`, `T1`, `M`, `T2`, and `H` so the user sees a compact trading ladder rather than the older T0/T1/T2/T3/T4 naming.

## Pivot trigger logic

The script also calculates a daily pivot setup using the latest bar:

```text
Pivot Point = (High + Low + Close) / 3
R1 = 2 * Pivot Point - Low
S1 = 2 * Pivot Point - High
R2 = Pivot Point + (High - Low)
S2 = Pivot Point - (High - Low)
```

The breakout and breakdown trigger levels are still used for interpretation:

- price above `R1` strengthens the bullish case
- price below `S1` strengthens the bearish case
- price between them is treated as a wait / accumulate zone

## Development checks

There is no automated test suite or package manager. Run shell syntax checks before submitting changes:

```bash
bash -n scripts/stock.sh
bash -n scripts/watchlist.sh
```

A network-backed smoke test for the calculator is:

```bash
bash scripts/stock.sh NIFTY
```

## GitHub Actions

The **Run watchlist dashboard** workflow can be started manually from the Actions tab and exposes the current watchlists under `watchlists/`. The **Analyze stock symbols** workflow accepts a comma-separated string such as `RELIANCE, TCS, NIFTY` and runs the calculator for each symbol in order. Each workflow retrieves live market data and uploads its report as a workflow artifact.

The **Run index dashboard** workflow accepts an index alias from `watchlists/indices.txt` and runs `scripts/index_dashboard.sh` for that index. The selectable aliases are maintained from the same watchlist and validated again during the workflow run.

## Files

- `scripts/stock.sh` - single-symbol data download, calculations, trend classification, and report generation.
- `scripts/watchlist.sh` - batch processing and colorized dashboard rendering.
- `watchlists/holdings.txt` - default stock watchlist.
- `watchlists/indices.txt` - index/watchlist aliases.
- `.github/copilot-instructions.md` - repository-specific guidance for Copilot sessions.

The dashboard uses temporary files for intermediate output and does not create generated files in the repository.

## Data and limitations

Market data is retrieved from Yahoo Finance at runtime and may be unavailable, delayed, stale, or changed by the upstream service. The calculator exits when no completed data is available, when the latest data is more than seven days old, or when 52-week high/low data is insufficient. Results are analytical indicators, not investment advice.
