# loads data & runs a report
# https://data.nationalgrideso.com/carbon-intensity1/historic-generation-mix/r/historic_gb_generation_mix



# Load some packages
library(gridCarbon) # load this first - you will need to download & build it locally from this repo

libs <- c("data.table", # data munching
          "drake", # data gets done once (ideally)
          "ggplot2", # plots
          "here", # here. not there
          "hms", # hms obvs
          "lubridate", # dates made easy
          "skimr", # skimming data for fast descriptives
          "zoo" # rolling mean etc
          ) 


gridCarbon::loadLibraries(libs) # should install any that are missing
drake::expose_imports(gridCarbon) # should track our functions

# check

# Parameters ----
update <- "yep" # edit to force data re-load - forces everything re-build :-)

localParams <- list()

# > dates ----
# editing any one of these will trigger drake to re-load the data
# and re-build all the plots. In case you were wondering...

#from
localParams$fromYear <- 2016 # a way to limit the number of years of data files loaded

# up to but not including
#localParams$toDate <- as.Date("2020-06-01") # 1st June for paper
localParams$toDate <- lubridate::today() # for latest

# plot cut dates
localParams$recentCutDate <- as.Date("2020-02-01")
localParams$comparePlotCutDate <- as.Date("2020-02-01")

# > data paths ----
localParams$gridDataLoc <- paste0(gcParams$ukData, 
                                  "/gridGen/processed/yearly/")
localParams$embeddedDataLoc <- paste0(gcParams$ukData, 
                                  "/embeddedGen/processed/")

# > captions ----
localParams$gridCaption <- paste0("Source: UK Electricity System Operator")
localParams$gridURL <- paste0("https://data.nationalgrideso.com/carbon-intensity1/historic-generation-mix/r/historic_gb_generation_mix")
localParams$gamCap <- "Trend line = Generalized additive model (gam) with integrated smoothness estimation"
localParams$loessCap <- "Trend line = Locally estimated scatterplot smoothing (loess)"
localParams$lockdownCap <- "\nColoured rectangle = UK covid lockdown period to date"
localParams$weekendCap <- "\nShaded rectangles = weekends"

# > rmd
localParams$pubLoc <- "University of Southampton: Sustainable Energy Research Centre"

# > defn of peak ----
localParams$amPeakStart <- hms::as_hms("07:00:00")
localParams$amPeakEnd <- hms::as_hms("09:00:00")
localParams$pmPeakStart <- hms::as_hms("17:00:00") # source?
localParams$pmPeakEnd <- hms::as_hms("21:00:00") # source?

# Functions ----

# should mostly be in R/


makeReport <- function(f){
  # default = html
  rmarkdown::render(input = paste0(here::here("rmd", "uk/"), f, ".Rmd"),
                    params = list(title = title,
                                  subtitle = subtitle,
                                  authors = authors),
                    output_file = paste0(here::here("docs/uk/"), f,"_upTo_",localParams$toDate,".html")
  )
}

# drake plan ----

plan <- drake::drake_plan(
  ## >> data stuff ----
  gridGenData = loadUKESOYearlyGenData(path = localParams$gridDataLoc, # from where?
                                       fromYear = localParams$fromYear, # from what date?
                                       toDate = localParams$toDate, # to when?
                                       update), 
  alignedGridGenData = alignDates(gridGenData, 
                                  dateTime = "rDateTimeUTC",
                                  toDate = localParams$toDate), # to when? # fix the dates so they line up
  embeddedGenData = loadEmbeddedGenData(localParams$embeddedDataLoc,
                                        toDate = localParams$toDate,update),
  alignedEmbeddedGenData = alignDates(embeddedGenData, 
                                  dateTime = "rDateTimeUTC",
                                  toDate = localParams$toDate),
  ## >> GW stuff ----
  recentDateTimeGWhPlot = createRecentDateTimePlot(gridGenData, 
                                                   dateTime = "rDateTimeUTC",
                                                        yVar = "GWh", 
                                                        yCap = "Total generation (GWh)",
                                                        yDiv = 1,
                                                  lockDownStart = gcParams$UKlockDownStartDateTime,
                                                  lockDownEnd = gcParams$UKlockDownEndDateTime),
  
  recentHalfHourlyProfileGWhPlot = createRecentHalfHourlyProfilePlot(gridGenData,
                                                                     dateTime = "rDateTimeUTC",
                                                                     yVar = "GWh",
                                                                     yCap = "Total generation (GWh)",
                                                                     yDiv = 1),
  
  compareDailyGWhPlot = createDailyMeanComparePlot(alignedGridGenData, 
                                                   yVar = "GWh", 
                                                   yCap = "Mean half hourly GWh per day",
                                                   yDiv = 1,
                                                  lockDownStart = gcParams$UKlockDownStartDate,
                                                  lockDownEnd = gcParams$UKlockDownEndDate
                                                   ),
  
  compareDailyGWhpcPlot = createDailyPcComparePlot(alignedGridGenData, 
                                                   yVar = "GWh", 
                                                   yCap = "% difference",
                                                  lockDownStart = gcParams$UKlockDownStartDate,
                                                  lockDownEnd = gcParams$UKlockDownEndDate
                                                   ),
  
  ## >> CI stuff ----
  recentDateTimeCIPlot = createRecentDateTimePlot(gridGenData, 
                                                   dateTime = "rDateTimeUTC",
                                                   yVar = "CARBON_INTENSITY", 
                                                   yCap = "Carbon intensity",
                                                   yDiv = 1,
                                                  lockDownStart = gcParams$UKlockDownStartDateTime,
                                                  lockDownEnd = gcParams$UKlockDownEndDateTime),
  
  recentHalfHourlyProfileCIPlot = createRecentHalfHourlyProfilePlot(gridGenData,
                                                                     dateTime = "rDateTimeUTC",
                                                                     yVar = "CARBON_INTENSITY",
                                                                     yCap = "Carbon intensity",
                                                                     yDiv = 1),
  
  compareDailyCIPlot = createDailyMeanComparePlot(alignedGridGenData, 
                                                   yVar = "CARBON_INTENSITY", 
                                                   yCap = "Mean daily half hourly carbon intensity",
                                                   yDiv = 1 , # what to divide the y value by
                                                  lockDownStart = gcParams$UKlockDownStartDate,
                                                  lockDownEnd = gcParams$UKlockDownEndDate 
  ),
  compareDailyCIpcPlot = createDailyPcComparePlot(alignedGridGenData, 
                                                   yVar = "CARBON_INTENSITY", 
                                                   yCap = "% difference",
                                                  lockDownStart = gcParams$UKlockDownStartDate,
                                                  lockDownEnd = gcParams$UKlockDownEndDate),
  ## >> CO2e kg stuff ----
  recentDateTimeC02ekgPlot = createRecentDateTimePlot(gridGenData, 
                                                   dateTime = "rDateTimeUTC",
                                                   yVar = "C02e_T", 
                                                   yCap = "C02e emitted (T)",
                                                   yDiv = 1, # totalC02e_kg is in kg
                                                   lockDownStart = gcParams$UKlockDownStartDateTime,
                                                   lockDownEnd = gcParams$UKlockDownEndDateTime), 
  
  
  recentHalfHourlyProfileC02ekgPlot = createRecentHalfHourlyProfilePlot(gridGenData, 
                                                                   dateTime = "rDateTimeUTC",
                                                                    yVar = "C02e_T", 
                                                                    yCap = "C02e emitted (T)",
                                                                    yDiv = 1 # totalC02e_kg is in kg
                                                                   ), 
  
  compareDailyCO2ekgPlot = createDailyMeanComparePlot(alignedGridGenData, 
                                                   yVar = "C02e_T", 
                                                   yCap = "Mean half hourly C02e (T)",
                                                   yDiv = 1 , # totalC02e_kg is in kg
                                                   lockDownStart = gcParams$UKlockDownStartDate,
                                                   lockDownEnd = gcParams$UKlockDownEndDate
                                                   ),

  compareDailyC02ekgpcPlot = createDailyPcComparePlot(alignedGridGenData, 
                                                   yVar = "C02e_T", 
                                                   yCap = "% difference",
                                                   lockDownStart = gcParams$UKlockDownStartDate,
                                                   lockDownEnd = gcParams$UKlockDownEndDate)
)

# > run drake plan ----
plan # test the plan
make(plan) # run the plan, re-loading data if needed

gridGenDT <- drake::readd(gridGenData)
alignedGridGenDT <- drake::readd(alignedGridGenData)

embeddedGenDT <- drake::readd(embeddedGenData)

# set lockdown period categories for plots
dstBreak <- as.Date("2020-03-29") #https://www.timeanddate.com/time/change/uk
alignedGridGenDT[, plotPeriodDetailed := ifelse(dateFixed < gcParams$UKlockDownStartDate, 
                                         "A: Pre-lockdown Jan - Mar", NA)] #
alignedGridGenDT[, plotPeriodDetailed := ifelse(dateFixed >= gcParams$UKlockDownStartDate &
                                           dateFixed < dstBreak, 
                                         "B: Lockdown to DST 31/3", plotPeriodDetailed)] #
alignedGridGenDT[, plotPeriodDetailed := ifelse(dateFixed > dstBreak &
                                           obsDate < gcParams$UKlockDownRelaxDate_1, 
                                         "C: Lockdown 31/3 - 11/5", plotPeriodDetailed)] #
alignedGridGenDT[, plotPeriodDetailed := ifelse(dateFixed >= gcParams$UKlockDownRelaxDate_1, 
                                         "D: Lockdown since 11/5", plotPeriodDetailed)] #

alignedGridGenDT[, plotPeriod := ifelse(dateFixed < gcParams$UKlockDownStartDate, 
                                 "A: Pre-lockdown Jan - Mar", NA)] #
alignedGridGenDT[, plotPeriod := ifelse(dateFixed >= gcParams$UKlockDownStartDate , 
                                 "B: Lockdown", plotPeriod)] 

# test a plot ----
#drake::readd(recentDateTimeGWPlot)

# code ----

# > Make report ----
# >> yaml ----
version <- "1.0"
title <- paste0("UK Electricity Generation and Carbon Itensity")
subtitle <- paste0("covid 19 lockdown v", version)
authors <- "Ben Anderson"

# latest dates:
message("We now have gridGen data from, " , min(gridGenDT$rDateTimeUTC), 
        " to: ", max(gridGenDT$rDateTimeUTC))
message("We now have embeddedGen data from, " , min(embeddedGenDT$rDateTimeUTC), 
        " to: ", max(embeddedGenDT$rDateTimeUTC))

# >> run report ----
rmdFile <- "covidLockdown_UK" # not the full path
makeReport(rmdFile)

# done
