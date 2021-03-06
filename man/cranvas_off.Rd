% Generated by roxygen2 (4.0.1): do not edit by hand
\name{cranvas_off}
\alias{cranvas_off}
\title{Close all Qt applications in the current R session}
\usage{
cranvas_off()
}
\description{
This function closes all Qt applications, including the plot windows from
\pkg{cranvas} and any other applications created from \pkg{qtbase}. To some
extent, it is like \code{\link{graphics.off}()}, but you should be cautious
about its strong side effects (it may closes the applications that you do not
wish to close).
}
