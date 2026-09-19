# Portfolio Analysis

A Bash-based portfolio and market-index analysis tool for Indian equities and indices. It downloads daily market data from Yahoo Finance and calculates returns and trend signals across multiple time horizons.

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

The symbol is normalized to uppercase. You may provide a single symbol, multiple separate arguments, or a single comma-separated string. Regular stock symbols default to the Yahoo Finance `.NS` suffix. The repo follows a consistent Nifty-prefixed naming scheme for Nifty-linked indices. Canonical names in `watchlists/indices` are:

- `nifty50`
- `niftyauto`
- `niftybank`
- `niftycommodities`
- `niftyconsumption`
- `niftyenergy`
- `niftyfmcg`
- `niftyinfrastructure`
- `niftyit`
- `niftymedia`
- `niftymetal`
- `niftymidcap150`
- `niftynext50`
- `niftypharma`
- `niftypsubank`
- `niftyrealty`
- `niftysmallcap250`

Older shorthand names such as `nifty`, `banknifty`, `metal`, and `smlcap250` remain accepted for compatibility, but the canonical repo convention is the `nifty...` prefix.

Yahoo-style symbols can also be supplied directly when needed, such as `BRITANNIA.NS` or a symbol beginning with `^`.

### Run the holdings dashboard

```bash
bash scripts/watchlist.sh watchlists/holdings
```

`holdings` contains one stock or index symbol per line. Blank lines are ignored. The dashboard analyzes every symbol, reports its 52-week low and high, preserves failed symbols as visible error rows, and prints a colorized summary.

Available watchlists include:

- `watchlists/holdings`
- `watchlists/indices`
- `watchlists/ipo`
- `watchlists/dividendStocks`
- `watchlists/etfs`

To use another watchlist:

```bash
bash scripts/watchlist.sh path/to/watchlist
```

To get the 52-week low and high for every configured index:

```bash
bash scripts/watchlist.sh watchlists/indices
```

To export the same compact table as CSV:

```bash
bash scripts/watchlist.sh watchlists/indices output/indices.csv
bash scripts/index_dashboard.sh niftyauto output/niftyauto.csv
```

To export an Excel workbook with green positive returns and red negative returns:

```bash
python3 -m pip install openpyxl
bash scripts/watchlist.sh watchlists/indices output/indices.xlsx
```

CSV files cannot store cell colors. The watchlist GitHub Actions workflow therefore uploads and emails the colored `.xlsx` workbook.

The index GitHub Actions workflow has an `all_indices` checkbox. When checked, it runs every alias in `watchlists/indices` and uploads/emails the resulting colored XLSX workbooks. The selected index value is ignored in that mode.

## Output

For each symbol, `stock.sh` reports:

- The latest available market price and quote date
- The percentage distance of the current close above the 52-week low and below the 52-week high
- Fundamental fields relevant to the active mode: sector, market-cap type, PE, PB, and dividend yield
- Absolute return rows for 1W, 1M, 3M, 6M, YTD, 1Y, 3Y, and 5Y
- The 52-week range block for the current symbol
- The console output is designed for compact dashboard parsing

The calculator downloads a 10-year daily history and overlays a recent 10-day download so the latest available sessions are refreshed. Data is converted to India Standard Time before trading dates are selected. For recognized NSE indices, the displayed 52-week high/low and the 1M/1Y change values use the official NSE `allIndices` feed; Yahoo Finance remains the source for the broader historical return series. Stock symbols and the SENSEX continue to use Yahoo high/low data.

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
bash -n scripts/index_dashboard.sh
```

A network-backed smoke test for the calculator is:

```bash
bash scripts/stock.sh NIFTY
```

## GitHub Actions

The **Run watchlist dashboard** workflow can be started manually from the Actions tab and exposes the current watchlists under `watchlists/`. The **Analyze stock symbols** workflow accepts a comma-separated string such as `RELIANCE, TCS, NIFTY` and runs the calculator for each symbol in order. Each workflow retrieves live market data and uploads its report as a workflow artifact.

The **Run index dashboard** workflow accepts an index alias from `watchlists/indices` and runs `scripts/index_dashboard.sh` for that index. The selectable aliases are maintained from the same watchlist and validated again during the workflow run. Enable the `all_indices` checkbox to process every configured index, including `niftysmallcap250`; the workflow produces one colored XLSX workbook per index. The `send_email` checkbox controls whether those workbooks are emailed.

To enable workflow email delivery, add these values as GitHub Actions repository secrets:

- `SMTP_SERVER`: SMTP host, for example `smtp.gmail.com`
- `SMTP_PORT`: SMTP port, normally `587`
- `SMTP_USERNAME`: full sender Gmail address
- `SMTP_PASSWORD`: Gmail app password, not the normal account password
- `EMAIL_TO`: recipient email address
- `EMAIL_FROM`: sender email address, normally the same as `SMTP_USERNAME`

The local `.env` file is ignored and is not uploaded to GitHub Actions. Configure the secrets in the repository's Settings under Secrets and variables > Actions.

## Files

- `scripts/stock.sh` - single-symbol data download, calculations, trend classification, and report generation.
- `scripts/watchlist.sh` - batch processing and colorized dashboard rendering.
- `scripts/index_dashboard.sh` - resolves index aliases and downloads index constituents for the batch dashboard.
- `watchlists/holdings` - default stock watchlist.
- `watchlists/indices` - index/watchlist aliases.
- `watchlists/dividendStocks`, `watchlists/etfs`, and `watchlists/ipo` - additional selectable watchlists.
- `.github/copilot-instructions.md` - repository-specific guidance for Copilot sessions.

The dashboard uses temporary files for intermediate output and does not create generated files in the repository.

## Data and limitations

Market data is retrieved from Yahoo Finance at runtime and may be unavailable, delayed, stale, or changed by the upstream service. The calculator exits when no completed data is available, when the latest data is more than seven days old, or when 52-week high/low data is insufficient. Results are analytical indicators, not investment advice.
