\name{fpca2s}
\alias{fpca2s}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Functional principal component analysis by a two-stage method
}
\description{
This function performs functional PCA by performing an ordinary singular value decomposition on the functional data matrix, then smoothing the right singular vectors by smoothing splines.
}
\usage{
fpca2s(Y, npc=NA, center = TRUE, argvals = NULL, smooth=TRUE)
}

\arguments{
  \item{Y}{data matrix (rows: observations; columns: grid
  of eval. points)}

  \item{npc}{how many smooth SVs to try to extract. If \code{NA}
  (the default), the hard thresholding rule of Donoho and
  Gavish (2013) is used. Application of this rule to functional PCA should be regarded as experimental.}

  \item{center}{center \code{Y} so that its column-means
  are 0? Defaults to \code{TRUE}}

  \item{argvals}{
index vector of \eqn{J} entries for data in X; defaults to a sequence from 0 to 1.
}
  \item{smooth}{
logical; defaults to TRUE, if NULL, no smoothing of eigenvectors.
}
 
}

\details{
The eigenvalues are the same as those obtained from eigendecomposition of the sample covariance matrix. Please note that we expect to merge this function into \code{\link{fpca.ssvd}} in future versions of the package.
}
\value{A list with components
\item{Yhat}{predicted data matrix}
\item{scores}{matrix of scores}
\item{mu}{mean function}
\item{npc}{number of principal components}
\item{eigenvectors}{matrix of eigenvectors}
\item{eigenvalues}{vector of eigenvalues}
}
\references{

Xiao, L., Ruppert, D., Zipunnikov, V., and Crainiceanu, C., (2013),
Fast covariance estimation for high-dimensional functional data. (submitted) \url{http://arxiv.org/abs/1306.5718}.

  Donoho, D.L. and Gavish, M. (2013). The optimal hard
  threshold for singular values is 4/sqrt(3).  eprint
  arXiv:1305.5870. Available from
  \url{http://arxiv.org/abs/1305.5870}.
  
}
\author{
Luo Xiao \email{lxiao@jhsph.edu}
}

\seealso{
  \code{\link{fpca.sc}} and \code{\link{fpca.face}} for
  FPCA based on smoothing a covariance estimate;
\code{\link{fpca.ssvd}} for another SVD-based approach.
}
\examples{
  #### settings
  I <- 50 # number of subjects
  J <- 3000 # dimension of the data
  t <- (1:J)/J # a regular grid on [0,1]
  N <- 4 #number of eigenfunctions
  sigma <- 2 ##standard deviation of random noises
  lambdaTrue <- c(1,0.5,0.5^2,0.5^3) # True eigenvalues
  
  case = 1
  ### True Eigenfunctions
  
  if(case==1) phi <- sqrt(2)*cbind(sin(2*pi*t),cos(2*pi*t),
                                   sin(4*pi*t),cos(4*pi*t))
  if(case==2) phi <- cbind(rep(1,J),sqrt(3)*(2*t-1),
                           sqrt(5)*(6*t^2-6*t+1),
                           sqrt(7)*(20*t^3-30*t^2+12*t-1))

  ###################################################
  ########     Generate Data            #############
  ###################################################
  xi <- matrix(rnorm(I*N),I,N);
  xi <- xi\%*\%diag(sqrt(lambdaTrue))
  X <- xi\%*\%t(phi); # of size I by J
  Y <- X + sigma*matrix(rnorm(I*J),I,J)
  
  results <- fpca2s(Y,npc=4,argvals=t)
  ###################################################
  ####               SVDS               ########
  ###################################################  
  Phi <- results$eigenvectors
  eigenvalues <- results$eigenvalues
  
  for(k in 1:N){
    if(Phi[,k]\%*\%phi[,k]< 0) 
      Phi[,k] <- - Phi[,k]
  }
 
 ### plot eigenfunctions
 par(mfrow=c(N/2,2))
 seq <- (1:(J/10))*10
 for(k in 1:N){
      plot(t[seq],Phi[seq,k]*sqrt(J),type="l",lwd = 3, 
           ylim = c(-2,2),col = "red",
           ylab = paste("Eigenfunction ",k,sep=""),
           xlab="t",main="SVDS")
      
      lines(t[seq],phi[seq,k],lwd = 2, col = "black")
      }
     
}

