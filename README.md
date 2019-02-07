# bio594-shiny-dev-proj
Code for Shiny project developed for URI's BIO594-0016 Data Visualization class, Spring 2019.

## Dashboards
### Vendor Health
- Sliders / Selectors
	- Date range to report over.
	- Optional comparison date range.
	- Vendor to report. 
	- Radio for reporting currency - USD or vendor primary

- Statistics
	- Average lead-time, by warehouse, by transport method.
		- For items that have been received, receipt date vs. PO submission date.
	- Average fill-rate, by warehouse, by transport method.
		- 'Exclude unfulfilled POs' checkbox
	- Inventory value by month
	- Sell through for preferred vendor

- Dump a report for vendor

### Brand Health
- Sliders / Selectors
	- Date range to report over.
	- Optional comparison date range.
	- Brand
	- Radio for reporting currency - USD or vendor primary

- Statistics
	- Sales by month, color code by customer category
	- Inventory turns by branlid, by item over a date range
 
- Dump a report for brand

### Supply Chain Health
- Sliders / Selectors
	- vendor to report

- Statistics
	- Time since placed.
	- Time since original eta.
	- Items still open
	- Discontinued items on PO
	- Discontinued items on SO
	- Overall customer backorders by brand