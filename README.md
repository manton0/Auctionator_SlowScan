# Auctionator - Slow Scan

A page-by-page auction house scanning addon for the **Ascension** private server (WoW 3.3.5). Auctionator SlowScan provides an alternative full scan method for servers where Auctionator's built-in GetAll scan does not work, feeding price data directly into Auctionator's price database.

## Features

- **Page-by-Page Scanning** — Scans the auction house one page at a time, bypassing the need for the GetAll API that many private servers disable
- **Live Price Collection** — Reads auction data directly from each loaded page during the scan, so even partial scans capture useful pricing data
- **Auctionator Integration** — Writes lowest-per-unit buyout prices straight into Auctionator's `Atr_ScanDB`, making prices available everywhere Auctionator displays them
- **Real-Time Progress** — Shows current page, total pages, and number of unique items collected as the scan progresses
- **Interruptible Scans** — Stop a scan at any time and keep all data collected so far
- **Quality Filtering** — Respects Auctionator's minimum quality setting when collecting prices
- **Minimal UI** — Adds a single "Slow Scan" button to the top-right of the Auction House frame, no extra windows or configuration needed

## Installation

1. Download the newest version under **Code > Download ZIP** [Download](https://github.com/manton0/Auctionator_SlowScan/archive/refs/heads/main.zip) 
2. Extract the ZIP content into your `Interface/AddOns` folder
3. Make sure the folder is called `Auctionator_SlowScan`
4. Ensure **Auctionator** and **Auctionator_Price_Database** are also installed (required dependencies)
5. Start your client and enjoy

## Usage

- **Open the Auction House** — The "Slow Scan" button appears in the top-right corner of the AH frame
- **Click "Slow Scan"** — Begins scanning all auctions page by page; the button changes to "Stop Scan"
- **Click "Stop Scan"** — Interrupts the scan early and saves all data collected so far
- **Watch progress** — Status text below the button shows the current page and item count
- **Check chat** — A summary message is printed to chat when the scan completes or is stopped

## Author

**mazer** (Discord: the_mazer)
