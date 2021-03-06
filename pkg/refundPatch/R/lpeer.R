lpeer<- function(Y, subj, t, funcs, covariates=NULL, comm.pen=TRUE,  
                 pentype='Ridge', L.user=NULL, f_t=NULL, Q=NULL, phia=10^3,
                 se=FALSE, ...)
{
  pd1 = pd2 = pd3 = pd4 = pd5 = pd6 = NULL
  
  #Determining K, converting W, Y, id and t to matrix
  W<- as.matrix(funcs)
  K<- ncol(W) 
  Y<- as.matrix(Y)
  id<- as.matrix(subj)
  t<-as.matrix(t)
  
  #Check 1:Making sure Y, subj and t have only 1 column
  if(dim(Y)[2]>1) return(cat("Error: No. of column for Y cannot be greater than 1. \nThe lpeer() will not proceed further.\n"))
  if(dim(id)[2]>1) return(cat("Error: No. of column for subj cannot be greater than 1. \nThe lpeer() will not proceed further.\n"))
  if(dim(t)[2]>1) return(cat("Error: No. of column for t cannot be greater than 1. \nThe lpeer() will not proceed further.\n"))
  
  #Check 2: Do check for intercept in X matrix
  if (!is.null(covariates)){
    covariates<- as.matrix(covariates)
    X.chk<- apply(covariates, 2, sd)
    if(any(X.chk==0)) return(cat("Error: Drop intercept or equivalent to intercept term from covariate. \nThe lpeer() will not proceed further.\n"))
  }
  X<-  cbind(1, covariates)
  
  #Check 3: Check the dimension of Y, id, t, W and X
  Yl<- dim(Y)[1]
  idl<- dim(id)[1]
  tl<- dim(t)[1]
  chk.eq<- ifelse(Yl==idl & idl==tl & tl==nrow(W), 0 ,1)
  if(chk.eq==1) return(cat("Error: At least one of (1) length of Y, (2) lenght of subj, (3) length of \nt, and (4) number of row of funcs are not equal.\n The lpeer() will not proceed further.\n"))
  if(!is.null(covariates) & Yl!=nrow(cbind(X,X))) return(cat("Error: length of Y and number of rows of X is not equal.\n The lpeer() will not proceed further.\n"))
  
  #Organizing f(t)
  if(length(dim(f_t))>0 ){
    f_t<- f_t
  } else
    if(length(f_t)>0){
      f_t<- matrix(f_t, ncol=1)
    } else
    {
      f_t<- matrix(rep(1, Yl), ncol=1)
    }
  f_t<- f_t[,which(apply(f_t, 2, sd)>0)]
  f_t<- cbind(1, f_t)
  d=ncol(f_t)-1
  if(d>5) warning("Only first 5 time components will be used", call. = FALSE)
  d=min(d,5)
  
  #Check 4: check in f(t)
  if(dim(f_t)[1]!=Yl) return(cat("Error: f_t and Y are not compatible in dimension. \nThe lpeer() will not proceed further.\n"))
  
  #Sort the data by id and t & removal of missing and infinite observations
  tdata<- data.frame(id, t, Y, W, X, f_t)
  tdata<- tdata[which(apply(is.na(tdata), 1, sum)==0),]
  tdata<- tdata[which(apply(is.infinite(as.matrix(tdata)), 1, sum)==0),]
  tdata<- tdata[order(id, t), ]
  tdata<- tdata[!is.na(tdata$id) & !is.na(tdata$t) & !is.na(tdata$Y),]
  id<- tdata$id
  t<- tdata$t
  Y<- tdata$Y
  W.e<- dim(W)[2]+3; W<- as.matrix(tdata[,c(4:W.e)])
  X.s<- W.e + 1; X.e<- dim(X)[2]+W.e; X<- as.matrix(tdata[,c(X.s:X.e)])
  f_t.s<- X.e + 1; f_t.e<- dim(f_t)[2]+X.e; f_t<- as.matrix(tdata[,c(f_t.s:f_t.e)])
  
  #Determining N and NT
  N<- length(unique(id))
  NT<- length(Y)
  
  #Checking entry for pentype
  pentypecheck<- toupper(pentype) %in% c('DECOMP', 'DECOMPOSITION', 'RIDGE', 'D2', 'USER')
  if(!pentypecheck)  return (cat("Error: Specify valid object for argument PENTYPE.\n"))
  
  #Check 5: Some checking/processing for decomposition type of penalty
  if(toupper(pentype)=='DECOMP' | toupper(pentype)=='DECOMPOSITION'){
    
    
    #5.1: Removing rows containing missing and infinite values
    Q<- Q[which(apply(is.na(Q), 1, sum)==0),]
    Q<- Q[which(apply(is.infinite(Q), 1, sum)==0),]
    
    #5.2: Compatibility of Q and W matrix
    if (!comm.pen) 
    {
      if(ncol(Q)!=(d+1)*ncol(W)) return(cat('Error: For different penalty, number of columns of Q need to be (d+1) \ntimes of number of columns of funcs.\nThe lpeer() will not proceed further.\n'))
    }
    if (comm.pen) 
    {
      if(ncol(Q)!=ncol(W)) return(cat('Error: For common penalty, number of columns of func and Q need to be equal.\nThe lpeer() will not proceed further.\n'))
      Q1<- Q
      for(i in 1:d) Q1<- cbind(Q1, Q)
      Q<- Q1
    }
    
    #5.3: Singularity of Q matrix
    Q.eig<- abs(eigen(Q %*% t(Q))$values)
    if(any(Q.eig<1e-12)) return(cat('Error: Q matrix is singular or near singular.\nThe lpeer() will not proceed further.\n'))
    
    #5.4: Checking for phia
    if(!exists("phia")) return (cat("Error: Specify valid object for argument PHIA.\n"))
    if(!is.numeric(phia)|is.matrix(phia)|is.matrix(phia)) return (cat("Error: Specify valid object for argument PHIA.\n"))
  }
  
  #Check 6: Some checking/processing for user type of penalty
  if(toupper(pentype)=='USER'){
    L<- L.user
    
    #6.1: Removing rows containing missing and infinite values
    L<- L[which(apply(is.na(L), 1, sum)==0),]
    L<- L[which(apply(is.infinite(L), 1, sum)==0),]
    
    #6.2: Dimension of L matrix
    if (!comm.pen) 
    {
      if(ncol(L)!=(d+1)*ncol(W)) return(cat('Error: For different penalty, number of columns of L need to be (d+1) \ntimes of number of columns of func.\nThe lpeer() will not proceed further.\n'))
    }
    if (comm.pen) 
    {
      if(ncol(L)!=ncol(W)) return(cat('Error: For common penalty, number of columns of func and L.user need to be equal.\nThe lpeer() will not proceed further.\n'))
      L1<- L
      for(i in 1:d) L1<- magic::adiag(L1, L)
      L<- L1
    }
    
    #6.3: Singularity of L'L matrix
    LL<- t(L)%*%L
    LL.eig<- abs(eigen(LL %*% t(LL))$values)
    if(any(LL.eig<1e-12)) return(cat("Error: L'L matrix is singular or near singular.\nThe lpeer() will not proceed further.\n"))
  }
  
  #Generate L matrix for D2 penalty
  if(toupper(pentype)=='D2'){
    Left<- cbind(diag(rep(1,K-2)),rep(0,K-2),rep(0,K-2))
    Middle<- cbind(rep(0,K-2),diag(rep(-2,K-2)),rep(0,K-2))
    Right<- cbind(rep(0,K-2),rep(0,K-2),diag(rep(1,K-2)))
    D.2<- rbind(Left+Middle+Right, c(rep(0, K-2), 1, -2), c(rep(0, K-2), 0, 1))
  }
  
  #Generate W1 matrix (This is referred as in the paper W matrix)
  for(i in 0:d){
    if (i==0) W1<-data.matrix(W)*f_t[,(i+1)] 
    if (i>0) W1<- cbind(W1, data.matrix(W)*f_t[,(i+1)])
  }
  
  #Generate W* matrix
  for(i in 0:d){
    if(toupper(pentype)=='DECOMP' | toupper(pentype)=='DECOMPOSITION'){
      tQ<- Q[,(i*K+1):((i+1)*K)] 
      tP_Q <- t(tQ) %*% solve(tQ %*% t(tQ)) %*% tQ
      tL_PEER<- phia*(diag(K)- tP_Q) + 1*tP_Q
      rm(tQ); rm(tP_Q)
    } else
      if(toupper(pentype)=='RIDGE'){
        tL_PEER<- diag(K)
      } else
        if(toupper(pentype)=='D2'){
          tL_PEER<- D.2
        } else
          if(toupper(pentype)=='USER'){
            tL_PEER<- L[(i*K+1):((i+1)*K),(i*K+1):((i+1)*K)]
          } 
    
    v <- diag(K)
    if (K > N) 
      v <- svd((data.matrix(W) * f_t[, (i + 1)]) %*% solve(tL_PEER))$v
    assign(paste("W", i + 1, "_PEER", sep = ""), (data.matrix(W) * 
      f_t[, (i + 1)]) %*% solve(tL_PEER) %*% v)
    rm(tL_PEER)
    rm(v)
  }
  
  #Generate Z
  id.bd1<- factor(rep(1, NT))
  ni<- tapply(id, id, length)
  for(i in 1:N){
    if (i==1) Z<- matrix(1, nrow=ni[i])
    if (i>1) Z<- magic::adiag(Z, matrix(1, nrow=ni[i]))
  }
  
  #Input for random argument of lme function 
  for(i in 0:d) assign(paste('pd', i+1, sep=''), 
                       nlme::pdIdent(form=as.formula(paste('~W', i+1, '_PEER -1', sep=''))))
  pdid<- nlme::pdIdent(~Z-1)
  
  if(d==0) tXX<- nlme::pdBlocked(list(pd1, pdid))
  if(d==1) tXX<- nlme::pdBlocked(list(pd1, pd2, pdid))
  if(d==2) tXX<- nlme::pdBlocked(list(pd1, pd2, pd3, pdid))
  if(d==3) tXX<- nlme::pdBlocked(list(pd1, pd2, pd3, pd4, pdid))
  if(d==4) tXX<- nlme::pdBlocked(list(pd1, pd2, pd3, pd4, pd5, pdid))
  if(d==5) tXX<- nlme::pdBlocked(list(pd1, pd2, pd3, pd4, pd5, pd6, pdid))
  
  #Fitting the model
  out_PEER<- nlme::lme(fixed=Y~X-1, random=list(id.bd1=tXX), ... ) 
  cat('The fit is successful.\n')
  
  #Extracting the estimates
  Gamma_PEER<-matrix(out_PEER$coeff$random$id.bd1, ncol=1)
  for(i in 0:d) {
    if(toupper(pentype)=='DECOMP' | toupper(pentype)=='DECOMPOSITION'){
      tQ<- Q[,(i*K+1):((i+1)*K)] 
      tP_Q <- t(tQ) %*% solve(tQ %*% t(tQ)) %*% tQ
      tL_PEER<- phia*(diag(K)- tP_Q) + 1*tP_Q
      rm(tQ); rm(tP_Q)
    } else
      if(toupper(pentype)=='RIDGE'){
        tL_PEER<- diag(K)
      } else
        if(toupper(pentype)=='D2'){
          tL_PEER<- D.2
        } else
          if(toupper(pentype)=='USER'){
            tL_PEER<- L[(i*K+1):((i+1)*K),(i*K+1):((i+1)*K)]
          } 
    v <- diag(K)
    if (K > N) 
      v <- svd((data.matrix(W) * f_t[, (i + 1)]) %*% solve(tL_PEER))$v
    r <- ncol(v)
    tGamma.PEER.hat <- matrix(Gamma_PEER[(i * r + 1):((i + 
      1) * r)], ncol = 1)
    tGammaHat <- solve(tL_PEER) %*% v %*% tGamma.PEER.hat
    if (i == 0) 
      GammaHat <- matrix(tGammaHat, ncol = 1)
    if (i > 0) 
      GammaHat <- cbind(GammaHat, tGammaHat)
    rm(tL_PEER)
    rm(v)
    rm(tGammaHat)
  }
  colnames(GammaHat)<- paste('Gamma', 0:d, sep='')
  BetaHat<- summary(out_PEER)$tTable[,1]
  names(BetaHat)<- c('Intercept', colnames(covariates))
  fitted.vals<- summary(out_PEER)$fitted
  
  #Extracting model diagnostics
  logLik<- summary(out_PEER)$logLik
  AIC<- summary(out_PEER)$AIC
  BIC<- summary(out_PEER)$BIC
  
  #Extracting lambda and variance
  tVarCorr<- nlme::VarCorr(out_PEER, rdig=4)[,2]
  for(i in 0:d) assign(paste('lambda', i, sep=''), 
                       1/ as.numeric(unique(tVarCorr[(i*r+1):((i+1)*r)])))
  for(i in 0:d)
  {
    tLambda<- 1/ as.numeric(unique(tVarCorr[(i*r+1):((i+1)*r)]))
    if(i==0) lambda<- tLambda
    if(i>0) lambda<- c(lambda, tLambda)
  }
  names(lambda)<- paste('lambda', 0:d, sep='')
  print(lambda)
  sd_int.est<- as.numeric(unique(tVarCorr[((d+1)*r+1):((d+1)*r+N)]))
  sigma<- out_PEER$sigma
  Sigma.u<- sd_int.est
  sigma.e<- sigma
  
  #Returning output when se=F
  if(!se){
    status<- 0
    ret <- list(out_PEER, BetaHat,  fitted.vals,  
                GammaHat, AIC, BIC, logLik, 
                lambda, N, K, NT, Sigma.u, sigma.e, d, status)
    names(ret)<- c("fit", "BetaHat", "fitted.vals",
                   "GammaHat", "AIC", "BIC", "logLik",
                   "lambda", "N", "K", "TotalObs", "Sigma.u", "sigma", "d", "status")
    class(ret) <- "lpeer"
    return(ret)
  }
  
  ###---- Standard Error
  for(i in 0:d)
  {
    if(toupper(pentype)=='DECOMP' | toupper(pentype)=='DECOMPOSITION'){
      tQ<- Q[,(i*K+1):((i+1)*K)] 
      tP_Q <- t(tQ) %*% solve(tQ %*% t(tQ)) %*% tQ
      tL_PEER<- phia*(diag(K)- tP_Q) + 1*tP_Q
      rm(tQ); rm(tP_Q)
    } else
      if(toupper(pentype)=='RIDGE'){
        tL_PEER<- diag(K)
      } else
        if(toupper(pentype)=='D2'){
          tL_PEER<- D.2
        } else
          if(toupper(pentype)=='USER'){
            tL_PEER<- L[(i*K+1):((i+1)*K),(i*K+1):((i+1)*K)]
          } 
    tsigma<- as.numeric(unique(tVarCorr[(i*r+1):((i+1)*r)]))
    if(i==0) LL.inv<- tsigma^2*solve(t(tL_PEER)%*%tL_PEER) 
    if(i>0) LL.inv<- magic::adiag(LL.inv, tsigma^2*solve(t(tL_PEER)%*%tL_PEER))
    
    rm(tsigma); rm(tL_PEER)
  }
  
  
  rand.var<- Sigma.u^2*(Z%*%t(Z))
  
  V.1<- W1%*%LL.inv%*%t(W1)+rand.var+sigma.e^2*diag(rep(1, NT))
  V<- rand.var+sigma.e^2*diag(rep(1, NT))
  
  X.Vinv.X.inv<- solve(t(X)%*%solve(V.1)%*%X)
  X.Vinv.Y<- t(X)%*%solve(V.1)%*%Y
  
  se.Beta<- sqrt(diag(X.Vinv.X.inv%*%t(X)%*%solve(V.1)%*%V%*%solve(V.1)%*%X%*%X.Vinv.X.inv))
  names(se.Beta)<- c('Intercept', colnames(covariates))
  Beta<- cbind(BetaHat, se.Beta)
  
  p1<- LL.inv%*%t(W1)%*%solve(V.1)
  p2<- V.1 - X%*%X.Vinv.X.inv%*%t(X)
  p3<- solve(V.1)
  p<- p1%*%p2%*%p3
  
  SE.gamma<- sqrt(diag(p%*%V%*%t(p)))
  for(i in 0:d)
  {
    if(i==0) se.Gamma<- matrix(SE.gamma[(i*K+1):((i+1)*K)], ncol=1)
    if(i>0) se.Gamma<- cbind(se.Gamma, SE.gamma[(i*K+1):((i+1)*K)])
  } 
  colnames(se.Gamma)<- paste('Gamma', 0:d, sep='')
  
  #Returning output when se=T
  status<- 1
  ret <- list(out_PEER, BetaHat,  se.Beta, Beta, fitted.vals,  
              GammaHat, se.Gamma, AIC, BIC, logLik, V.1,
              V, lambda, N, K, NT, Sigma.u, sigma.e, d, status)
  names(ret)<- c("fit", "BetaHat", "se.Beta", "Beta", "fitted.vals",
                 "GammaHat", "se.Gamma", "AIC", "BIC", "logLik", "V1",
                 "V", "lambda", "N", "K", "TotalObs", "Sigma.u", "sigma", "d", "status")
  
  class(ret) <- "lpeer"
  ret
}