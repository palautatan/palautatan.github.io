cv.hist.fun <- function(x){
  ### histogram cross validation function
  n <- length(x)
  a <- min(x)
  b <- max(x)
  k <- 100
  nbins <- seq(1,n,length=k)  ###number of bins
  nbins <- round(nbins)
  h <- (b-a)/nbins            ###width of bins
  risk <- rep(0,k)
  for(i in 1:k){
    ###get counts N_j
    br <- seq(a,b,length=nbins[i]+1)
    N <- hist(x,breaks=br,plot=F)$counts
    risk[i] <- sum(N^2)/(n^2*h[i])  - (2/(h[i]*n*(n-1)))*sum(N*(N-1))
  }
  hbest <- h[risk==min(risk)]
  hbest <- hbest[1]  ###in case of tie take first (smallest) one
  mbest <- (b-a)/hbest   ###optimal number of bins
  list(risk=risk, nbins=nbins, h=h, mbest=mbest, hbest=hbest)
}



ci.fun <- function(x,alpha=.05,m=0){
  a <- min(x); b <- max(x)
  x <- (x-a)/(b-a)
  n <- length(x)
  if(m==0)m <- round(sqrt(n))
  c <- (qnorm(1-(alpha/m))/sqrt(2))*sqrt(m/n)
  br <- seq(0,1,length=m+1)
  h  <- 1/m
  p  <- hist(x,breaks=br,plot=F)$counts/n
  f  <- p/h
  u  <- (sqrt(f) + c)^2
  l  <- (pmax(sqrt(f) - c,0))^2
  Grid <- rep((1:(m-1))/m,rep(2,m-1))
  Grid <- c(0,Grid,1)
  Grid <- Grid*(b-a) + a
  f <- f/(b-a); l <- l/(b-a); u <- u/(b-a);
  U <- rep(u,rep(2,m))
  L <- rep(l,rep(2,m))
  F <- rep(f,rep(2,m))
  return(list(f=f,u=u,l=l,m=m,Grid=Grid,U=U,L=L,F=F))
}
