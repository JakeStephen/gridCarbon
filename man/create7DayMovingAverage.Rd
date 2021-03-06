% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/create7DayMovingAverage.R
\name{create7DayMovingAverage}
\alias{create7DayMovingAverage}
\title{Calculates a 7 day rolling mean for specified variable for the data.table given}
\usage{
create7DayMovingAverage(dt, avgVar, byVars)
}
\arguments{
\item{dt}{a data table with a summary variable you want to average}

\item{avgVar}{the variable you want to average}

\item{byVars}{the variables you want to group by (e.g. obsDate and compareYear) as a vector thus: byVars <- c("obsDate", "compareYear")}
}
\description{
`createDailyMeanPlot` returns a plot which calculates the mean of yVar and plots it for 2020 and 2017-2019 to 
compare the values for the same date over previous years. This assumes the
}
\author{
Ben Anderson, \email{b.anderson@soton.ac.uk}
}
\concept{stats}
