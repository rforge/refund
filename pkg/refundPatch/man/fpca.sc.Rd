\name{fpca.sc}
\alias{fpca.sc}
\title{
Functional principal components analysis by smoothed covariance
}
\description{
Decomposes functional observations using functional principal components analysis. A mixed model framework is used to estimate scores and obtain variance estimates.
}
\usage{
fpca.sc(Y=NULL, ydata = NULL, Y.pred=NULL, argvals = NULL, 
        random.int = FALSE, nbasis = 10, pve = .99, npc = NULL, 
        var = FALSE, simul = FALSE, sim.alpha = .95,
        useSymm = FALSE, makePD = FALSE, center=TRUE, cov.est.method = 2)
}
\arguments{
  \item{Y, ydata}{the user must supply either \code{Y}, a matrix of functions observed on a regular grid, or a data frame \code{ydata} representing irregularly observed functions. See Details.}
  \item{Y.pred}{if desired, a matrix of functions to be approximated using the FPC decomposition.}
  \item{argvals}{function argument.}
  \item{random.int}{If \code{TRUE}, the mean is estimated by \code{\link[gamm4]{gamm4}} with random intercepts. If \code{FALSE} (the default), the mean is estimated by \code{\link[mgcv]{gam}} treating all the data as independent.}
  \item{nbasis}{number of B-spline basis functions used for estimation of the mean function and bivariate smoothing of the covariance surface.}
  \item{pve}{proportion of variance explained: used to choose the number of principal components.}
  \item{npc}{prespecified value for the number of principal components (if given, this overrides \code{pve}).}
  \item{var}{\code{TRUE} or \code{FALSE} indicating whether model-based estimates for the variance of FPCA expansions should be computed.}
  \item{simul}{logical: should critical values be estimated for simultaneous confidence intervals?}
  \item{sim.alpha}{1 - coverage probability of the simultaneous intervals.}
  \item{useSymm}{logical, indicating whether to smooth only the upper triangular part of the naive covariance (when \code{cov.est.method==2}).
      This can save computation time for large data sets, and allows for covariance surfaces that are very peaked on the diagonal.}
  \item{makePD}{logical: should positive definiteness be enforced for the covariance surface estimate?}
  \item{center }{logical: should an estimated mean function be subtracted from \code{Y}? Set to \code{FALSE} if you have already demeaned the data using your favorite mean function estimate.}
  \item{cov.est.method}{covariance estimation method. If set to \code{1}, a one-step method that applies a bivariate smooth to the \eqn{y(s_1)y(s_2)} values. This can be very slow. If set to \code{2} (the default), a two-step method that obtains a naive covariance estimate which is then smoothed.}
}
\details{
  This function computes a FPC decomposition for a set of observed curves, which may be sparsely observed and/or measured with error. A mixed model framework is used to estimate curve-specific scores and variances.

FPCA via kernel smoothing of the covariance function, with the diagonal treated separately, was proposed in Staniswalis and Lee (1998) and much extended by Yao et al. (2005), who introduced the "PACE" method. \code{fpca.sc} uses penalized splines to smooth the covariance function, as developed by Di et al. (2009) and Goldsmith et al. (2013).

The functional data must be supplied as either
\itemize{
\item an \eqn{n \times d} matrix \code{Y}, each row of which is one functional observation, with missing values allowed; or
\item a data frame \code{ydata}, with columns \code{'.id'} (which curve the point belongs to, say \eqn{i}), \code{'.index'} (function argument such as time point \eqn{t}), and \code{'.value'} (observed function value \eqn{Y_i(t)}).}
}
\value{
 \item{Yhat}{FPC approximation (projection onto leading components) of \code{Y.pred} if specified, or else of \code{Y}.}
  \item{scores}{\eqn{n \times npc} matrix of estimated FPC scores.}
  \item{mu}{estimated mean function (or a vector of zeroes if \code{center==FALSE}).}
  \item{efunctions }{\eqn{d \times npc} matrix of estimated eigenfunctions of the functional covariance, i.e., the FPC basis functions.}
  \item{evalues}{estimated eigenvalues of the covariance operator, i.e., variances of FPC scores.}
  \item{npc }{number of FPCs: either the supplied \code{npc}, or the minimum number of basis functions needed to explain proportion \code{pve} of the variance in the observed curves.}
  \item{sigma2}{estimated measurement error variance.}
  \item{diag.var}{diagonal elements of the covariance matrices for each estimated curve.}
  \item{VarMats}{a list containing the estimated covariance matrices for each curve in \code{Y}.}
  \item{crit.val}{estimated critical values for constructing simultaneous confidence intervals.}
}
\references{
Di, C., Crainiceanu, C., Caffo, B., and Punjabi, N. (2009). Multilevel functional principal component analysis. \emph{Annals of Applied Statistics}, 3, 458--488.

Goldsmith, J., Greven, S., and Crainiceanu, C. (2013). Corrected confidence bands for functional data using principal components. \emph{Biometrics}, 69(1), 41--51.

Staniswalis, J. G., and Lee, J. J. (1998). Nonparametric regression analysis of longitudinal data. \emph{Journal of the American Statistical Association}, 93, 1403--1418.

Yao, F., Mueller, H.-G., and Wang, J.-L. (2005). Functional data analysis for sparse longitudinal data. \emph{Journal of the American Statistical Association}, 100, 577--590.
}
\author{
Jeff Goldsmith \email{jeff.goldsmith@columbia.edu}, Sonja Greven \email{sonja.greven@stat.uni-muenchen.de}, Lan Huo \email{Lan.Huo@nyumc.org}, Lei Huang \email{huangracer@gmail.com}, and Philip Reiss \email{phil.reiss@nyumc.org}
}
\examples{
\dontrun{
data(cd4)

Fit.MM = fpca.sc(cd4, var = TRUE, simul = TRUE)

# for one subject, examine curve estimate, pointwise and simultaneous itervals
EX = 1
EX.MM =  cbind(Fit.MM$Yhat[EX,], 
      Fit.MM$Yhat[EX,] + 1.96 * sqrt(Fit.MM$diag.var[EX,]), 
      Fit.MM$Yhat[EX,] - 1.96 * sqrt(Fit.MM$diag.var[EX,]),
      Fit.MM$Yhat[EX,] + Fit.MM$crit.val[EX] * sqrt(Fit.MM$diag.var[EX,]),
      Fit.MM$Yhat[EX,] - Fit.MM$crit.val[EX] * sqrt(Fit.MM$diag.var[EX,]))


par(mfrow=c(1,3))

# plot data for one subject, with curve and interval estimates
d = as.numeric(colnames(cd4))
plot(d[which(!is.na(cd4[EX,]))], cd4[EX,which(!is.na(cd4[EX,]))], type = 'o', pch = 19,
  cex=.75, ylim = range(0, 3400), xlim = range(d), xlab = "Months since seroconversion", 
    lwd = 1.2, ylab = "Total CD4 Cell Count", main = "Est. & CI - Sampled Data")

matpoints(d, EX.MM, col = 4, type = 'l', lwd = c(2, 1, 1, 1, 1), lty = c(1,1,1,2,2))

# plot estimated mean function
plot(d, Fit.MM$mu, type = 'l', xlab = "Months since seroconversion",
  ylim = range(0, 3400), ylab = "Total CD4 Cell Count", main = "Est. Mean Function")

# plot the first estimated basis function
plot(d, Fit.MM$efunctions[,1], type = 'l', xlab = "Months since seroconversion",
  ylab = "Total CD4 Cell Count", main = "First Est. Basis Function")
  
  
# input a dataframe instead of a matrix

nid <- 20
nobs <- sample(10:20, nid, rep=TRUE)
ydata <- data.frame(
    .id = rep(1:nid, nobs),	
    .index = round(runif(sum(nobs), 0, 1), 3))
ydata$.value <- unlist(tapply(ydata$.index, 
                              ydata$.id, 
                              function(x) 
                                  runif(1, -.5, .5) + 
                                  dbeta(x, runif(1, 6, 8), runif(1, 3, 5))
                              )
                       )
Fit.MM = fpca.sc(ydata=ydata, var = TRUE, simul = FALSE)
matplot(Fit.MM$efunctions[,1:2])
}
}