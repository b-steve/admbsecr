% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convert.r
\name{convert.capt}
\alias{convert.capt}
\alias{convert.capt.to.admbsecr}
\alias{convert.capt.to.secr}
\title{Capture history conversion.}
\usage{
convert.capt.to.admbsecr(capt)

convert.capt.to.secr(capt, traps, capthist = TRUE, cutoff = NULL)
}
\arguments{
\item{capt}{A \code{secr} capture history object for
\code{convert.capt.to.admbsecr}, or an \code{admbsecr} capture
history object for \code{convert.capt.to.secr}.}

\item{traps}{A matrix with two columns. Each row provides Cartesian
coordinates for the location of a trap (or detector).}

\item{capthist}{Logical, if \code{TRUE}, a \code{capthist} object
is returned. Otherwise a data frame is returned, which is
suitable for the \code{captures} argument to the
\link{make.capthist} function.}

\item{cutoff}{The signal strength threshold for detection, if
required.}
}
\value{
A capture history object appropriate for analysis using
    either the \code{admbsecr} or the \code{secr} package.
}
\description{
These functions convert a capture history object between the
structures required for the \code{admbsecr} and \code{secr}
packages.
}
\examples{
capt <- convert.capt.to.secr(capt = example$capt, traps = example$traps, cutoff = example$cutoff)

}

