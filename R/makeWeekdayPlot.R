#' Creates a plot by weekday from the data.table given
#'
#' `makeWeekdayPlot` returns a plot which shows yVar by weekday, compareYear and plotPeriod (assumed to be lockdown). 
#' Assumes this is the date aligned data.
#'
#' @param dt the data
#' @param yVar the variable you want to plot
#' @param yLab the label for the y axis
#' @param yDiv the value you want to divide yVar by to make the y axis more sensible. Default = `1`
#' 
#' @return a plot
#' @import ggplot2
#' @import data.table
#' @author Ben Anderson, \email{b.anderson@@soton.ac.uk}
#' @export
#' @family plot
#'
makeWeekdayPlot <- function(dt, yVar, yLab, yDiv){
  # by weekday 
  # not proportions - absolute
  # wkdayFixed = obs (they are the same - that was the whole idea!)
  pDT <- dt[, .(yVals = mean(get(yVar))/yDiv), keyby = .(plotPeriod, compareYear, wkdayFixed)]
  p <- ggplot2::ggplot(pDT, aes(x = wkdayFixed, y = yVals, 
                               colour = compareYear, group = compareYear)) + 
    geom_line() +
    theme(legend.position="bottom") +
    scale_color_discrete(name="Year") +
    facet_grid(plotPeriod ~ . ) +
    labs( y = yLab,
          x = "Weekday")
  return(p)
}