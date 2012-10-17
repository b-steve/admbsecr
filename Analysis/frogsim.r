## Letting R know where everything is.
admbsecr.dir <- "~/admbsecr" # Point this to the admbsecr file.
if (.Platform$OS == "unix"){
  sep <- "/"
} else if (.Platform$OS == "windows") {
  sep <- "\\"
}
admb.dir <- paste(admbsecr.dir, "ADMB", sep = sep)
work.dir <- paste(admbsecr.dir, "Analysis", sep = sep)
func.dir <- paste(admbsecr.dir, "R", sep = sep)
dat.dir <- paste(admbsecr.dir, "Data", "Frogs", sep = sep)

## Get required libraries.
library(secr)
library(Rcpp)
library(inline)

## Set working directory to that with the functions.
setwd(func.dir)
## Get SECR functions.
source("admbsecr.r")
source("autofuns.r")
source("helpers.r")
source("lhoodfuns.r")
source("tplmake.r")

## Loading trap positions.
setwd(dat.dir)
mics <- read.csv(file = "array1a-top.csv")
micnames <- 1:dim(mics)[1]
mics <- cbind(micnames, mics)
traps <- read.traps(data = mics, detector = "signal")

setwd(work.dir)
## Setup for simulations.
nsims <- 1
buffer <- 35
mask.spacing <- 50

## True parameter values.
set.seed(5253)
D <- 4450
g0 <- 0.99999
sigma <- 5.60
sigmatoa <- 0.002
ssb0 <- 170
ssb1 <- -2.50
sigmass <- 7.00
cutoff <- 150
truepars <- c(D = D, g0 = g0, sigma = sigma, sigmatoa = sigmatoa,
              ssb0 = ssb0, ssb1 = ssb1, sigmass = sigmass)
detectpars <- list(beta0 = ssb0, beta1 = ssb1, sdS = sigmass, cutval = cutoff)
## Inverse of speed of sound (in ms per metre).
invsspd <- 1000/330

## Setting up mask and traps.
ntraps <- nrow(traps)
mask <- make.mask(traps, buffer = buffer, type = "trapbuffer")
nmask <- nrow(mask)
A <- attr(mask, "area")
mask.dists <- distances.cpp(as.matrix(traps), as.matrix(mask))
simprobs <- NULL
toaprobs <- NULL
ssprobs <- NULL
jointprobs <- NULL
simpleres <- matrix(0, nrow = nsims, ncol = 3)
toares <- matrix(0, nrow = nsims, ncol = 4)
ssres <- matrix(0, nrow = nsims, ncol = 4)
jointres <- matrix(0, nrow = nsims, ncol = 5)
colnames(simpleres) <- c("D", "g0", "sigma")
colnames(toares) <- c("D", "g0", "sigma", "sigmatoa")
colnames(ssres) <- c("D", "ssb0", "ssb1", "sigmass")
colnames(jointres) <- c("D", "sigmatoa", "ssb0", "ssb1", "sigmass")

## Carrying out simulation.
for (i in 1:nsims){
  if (i == 1){
    print(c("start", date()))
  } else if (i %% 100 == 0){
    print(c(i, date()))
  }
  ## Simulating data and setting things up for analysis.
  popn <- sim.popn(D = D, core = traps, buffer = buffer)
  capthist <- sim.capthist(traps, popn, detectfn = 10, detectpar = detectpars,
                       noccasions = 1, renumber = FALSE)
  n <- nrow(capthist)
  ndets <- sum(capthist)
  ## IDs for detected animals.
  cue.ids <- unique(as.numeric(rownames(capthist)))
  ## Cartesian coordinates of detected animals.
  detections <- popn[cue.ids, ]
  ## Distances from detected animals to traps.
  distances <- t(distances.cpp(as.matrix(traps), as.matrix(detections)))
  capthist.ss <- array(0, dim = dim(capthist))
  capthist.ss[capthist == 1] <- attr(capthist, "signalframe")[, 1]
  ## Generating times of arrival.  
  ## Time of call itself doesn't provide any information, this comes
  ## solely from the *differences* in arrival times between traps. We
  ## can assume that animal with ID = t calls at time t without loss
  ## of generality.
  capthist.toa <- array(0, dim = dim(capthist))
  for (j in 1:n){
    for (k in 1:ntraps){
      if (capthist[j, 1, k] == 1){
        dist <- distances[j, k]
        meantoa <- cue.ids[j] + invsspd*dist/1000
        capthist.toa[j, 1, k] <- rnorm(1, meantoa, sigmatoa)
      } else {
        capthist.toa[j, 1, k] <- 0
      }
    }
  }
  capthist.joint <- array(c(capthist.ss, capthist.toa), dim = c(dim(capthist), 2))
  ## Straightforward SECR model using admbsecr().
  simplefit <- try(admbsecr(capt = capthist, traps = traps, mask = mask,
                            sv = truepars[1:3], admbwd = admb.dir,
                            method = "simple", verbose = FALSE), silent = TRUE)
  if (class(simplefit) == "try-error"){
    simplefit <- try(admbsecr(capt = capthist, traps = traps, mask = mask,
                              sv = "auto", admbwd = admb.dir, method = "simple",
                              verbose = FALSE), silent = TRUE)
  }
  if (class(simplefit) == "try-error"){
    simplecoef <- NA
    simprobs <- c(simprobs, i)
  } else {
    simplecoef <- coef(simplefit)
  }
  ## SECR model using supplementary TOA data.
  ssqtoa <- apply(capthist.toa, 1, toa.ssq, dists = mask.dists)
  toafit <- try(admbsecr(capt = capthist.toa, traps = traps, mask = mask,
                         sv = truepars[1:4], ssqtoa = ssqtoa, admbwd = admb.dir,
                         method = "toa", verbose = FALSE), silent = TRUE)
  if (class(toafit) == "try-error"){
    toafit <- try(admbsecr(capt = capthist.toa, traps = traps, mask = mask,
                           sv = "auto", ssqtoa = ssqtoa, admbwd = admb.dir,
                           method = "toa", verbose = FALSE), silent = TRUE)
  }
  if (class(toafit) == "try-error"){
    toacoef <- NA
    toaprobs <- c(toaprobs, i)
  } else {
    toacoef <- coef(toafit)
  }
  ## SECR model using supplementary signal strength data.
  ssfit <- try(admbsecr(capt = capthist.ss, traps = traps, mask = mask,
                        sv = truepars[c(1, 5:7)], cutoff = cutoff,
                        admbwd = admb.dir, method = "ss", verbose = FALSE),
               silent = FALSE)
  if (class(ssfit) == "try-error"){
    ssfit <- try(admbsecr(capt = capthist.ss, traps = traps, mask = mask,
                          sv = "auto", cutoff = cutoff, admbwd = admb.dir,
                          method = "ss", verbose = FALSE), silent = FALSE)
  }
  if (class(ssfit) == "try-error"){
    sscoef <- NA
    ssprobs <- c(ssprobs, i)
  } else {
    sscoef <- coef(ssfit)
  }
  ## SECR model using joint TOA and signal strength data.
  jointfit <- try(admbsecr(capt = capthist.joint, traps = traps, mask = mask,
                           sv = truepars[c(1, 4:7)], cutoff = cutoff,
                           ssqtoa = ssqtoa, admbwd = admb.dir, method = "sstoa",
                           verbose = FALSE), silent = TRUE)
  if (class(jointfit) == "try-error"){
    jointfit <- try(admbsecr(capt = capthist.joint, traps = traps, mask = mask,
                             sv = "auto", cutoff = cutoff, ssqtoa = ssqtoa,
                             admbwd = admb.dir, method = "sstoa",
                             verbose = FALSE), silent = TRUE)
  }
  if (class(jointfit) == "try-error"){
    jointcoef <- NA
    jointprobs <- c(jointprobs, i)
  } else {
    jointcoef <- coef(jointfit)
  }
  simpleres[i, ] <- simplecoef
  toares[i, ] <- toacoef
  ssres[i, ] <- sscoef
  jointres[i, ] <- jointcoef
  if (i == nsims){
    print(c("end", date()))
  }
}