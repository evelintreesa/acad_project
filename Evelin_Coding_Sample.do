**Author of the code: Evelin Treesa Jose
//This code is designed to:

//Load high frequency time series data from multiple CSV files (pm2.5 detectors in different locations).
//Convert timestamps and prepare the data for time series analysis.
//Generate and export time series plots, including original plots, moving averages, and 5-minute averages.
//Provide an initial insights regarding the PM2.5 data over time.

clear

//defining filepathways
global file_path "D:\Round 1"
global output_path "$file_path\output"

//defining working directory
cd "$file_path"

//generating timeseries plots from each detector in a loop
local files : dir "`file_path'" files "hapex 44*.csv"
di `"`files'"' 

foreach x of local files {
    //To help debug the code and to verify the processes
	di "`x'" 
     
	//importing the csv files, the datatset starts from raw 21.
	import delimited "`x'", varnames(21) clear
	
	//A look at the dataset
	di "Variables in `file':"
    describe
	count
	
	//Setting up the time variable for analysis
	gen double timestamp_num = clock(timestamp, "YMDhms")
    format timestamp_num %tc
	
	summarize timestamp_num, format

    display "Oldest timestamp: " %tc r(min)
    display "Latest timestamp: " %tc r(max)

	tsset timestamp_num, delta(60000)
	
	//plotting the pm2.5 variable
	//did it in a loop since the variable is named differently reflecting each detectorscode(each csv file) however uniquely starts with 'kitchenpmhapex'
	//it is also easily used to identify the plots from different detectors in households. 
	foreach var of varlist kitchenpmhapex* {

    di "The variable used for plotting is: `var'"

	tsline `var', title("Kitchen PM2.5 Over Time - `var'") ytitle("Kitchen PM2.5") xtitle("") xlabel(, labsize(0.6)) 
	
	graph export "$output_path\\`var'_tsline.png", as(png) replace
	
	//Define the list of window sizes
    foreach i in 10 15 {
	
    //Apply the moving average with the current window size
    tssmooth ma sma`i' = `var', window(`i')
	
	tsline sma`i', title("Kitchen PM2.5 Over Time - `var' - sma`i'") ytitle("Kitchen PM2.5") xtitle("") xlabel(, labsize(0.6))
	
	graph export "$output_path\\`var'_sma`i'.png", as(png) replace
}

	//5 minute average
    gen group = ceil(_n / 5)
    bysort group: egen meanpm`var' = mean(`var')
    bysort group: gen third_timestamp = timestamp_num if _n == 3
    format third_timestamp %tc
    //Keep only observations where third_timestamp is not missing
    keep if !missing(third_timestamp)
    //Plot mean pm2.5 on y-axis and third_timestamp on x-axis
       twoway (line meanpm`var' third_timestamp, sort), ///
       xtitle("") xlabel(#90, angle(90) labsize(1.2) format(%tc)) ///
       ylabel(, grid) ///
       title("Kitchen PM2.5 Over Time(5 min averages) - `var'")
	   graph export "$output_path\\`var'_5minavg.png", as(png) replace
}
	
    clear
}