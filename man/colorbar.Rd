% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helpers.R
\name{colorbar}
\alias{colorbar}
\title{Modify the colorbar}
\usage{
colorbar(p, ...)
}
\arguments{
\item{p}{a plotly object}

\item{...}{arguments are documented here 
\url{https://plot.ly/r/reference/#scatter-marker-colorbar}.}
}
\description{
Modify the colorbar
}
\examples{

plot_ly(mpg, x = ~cty, y = ~hwy, color = ~cyl) \%>\%
  colorbar(len = 0.5)

}
\author{
Carson Sievert
}

