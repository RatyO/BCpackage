#' @include TimeSeriesTP-class.R BiascoTimeSeriesTP-class.R
#' @import sn
BC.joint <- setClass("JointCorrection",
                    contains = "BiascoTimeSeriesTP",
                    slots = c(obs = "TimeSeriesTP", ctrl = "TimeSeriesTP", scen = "TimeSeriesTP"),
                    prototype = prototype(obs = new("TimeSeriesTP"), ctrl = new("TimeSeriesTP"), scen = new("TimeSeriesTP"))
)

#initialize
setMethod(f = "initialize",
          signature = "JointCorrection",
          function(.Object, ..., obs = new("TimeSeriesTP"), ctrl = new("TimeSeriesTP"),
                   scen = new("TimeSeriesTP")){
            .Object <- callNextMethod(.Object, adj = scen)
            .Object@obs <- obs
            .Object@ctrl <- ctrl
            .Object@scen <- scen
            validObject(.Object)
            return(.Object)
          })

#getters

#' @rdname obs
setMethod(f = "obs",
          signature = "JointCorrection",
          definition = function(object){
            return(object@obs)
          })

#' @rdname ctrl
setMethod(f = "ctrl",
          signature = "JointCorrection",
          definition = function(object){
            return(object@ctrl)
          })

#' @rdname scen
setMethod(f = "scen",
          signature = "JointCorrection",
          definition = function(object){
            return(object@scen)
          })

#Setters

#' @rdname obs<-
setMethod(f = "obs<-",
          signature = "JointCorrection",
          definition = function(object, value){
            .Object@obs <- value
            validObject(object)
            return(object)
          })

#' @rdname ctrl<-
setMethod(f = "ctrl<-",
          signature = "JointCorrection",
          definition = function(object, value){
            object@ctrl <- value
            validObject(object)
            return(object)
          })

#' @rdname scen<-
setMethod(f = "scen<-",
          signature = "JointCorrection",
          definition = function(object, value){
            object@scen <- value
            validObject(object)
            return(object)
          })

#' @rdname show
setMethod(f = "show",
          signature = "JointCorrection",
          definition = function(object){
            cat("*** Class JointCorrection object, method show *** \n")
            cat("* method = "); print (object@method)
            cat("* bc.attributes = "); print (object@bc.attributes)
            cat("* adj@nvar = "); print (object@adj@nvar)
            cat("* adj@Dim = "); print (object@adj@Dim)
            cat("* adj@data (limited to first 100 values) = \n")
            if(nrow(object@adj@data)!=0){
              print(format(object@adj@data[1:min(nrow(object@adj@data),100),]),quote=FALSE)
            }else{}
            cat("* obs@nvar = "); print (object@obs@nvar)
            cat("* obs@Dim = "); print (object@obs@Dim)
            cat("* obs@data (limited to first 100 values) = \n")
            if(nrow(object@obs@data)!=0){
              print(format(object@obs@data[1:min(nrow(object@obs@data),100),]),quote=FALSE)
            }else{}
            cat("* ctrl@nvar = "); print (object@ctrl@nvar)
            cat("* ctrl@Dim = "); print (object@ctrl@Dim)
            cat("* ctrl@data (limited to first 100 values) = \n")
            if(nrow(object@ctrl@data)!=0){
              print(format(object@ctrl@data[1:min(nrow(object@ctrl@data),100),]),quote=FALSE)
            }else{}
            cat("* scen@nvar = "); print (object@scen@nvar)
            cat("* scen@Dim = "); print (object@scen@Dim)
            cat("* scen@data (limited to first 100 values) = \n")
            if(nrow(object@scen@data)!=0){
              print(format(object@scen@data[1:min(nrow(object@scen@data),100),]),quote=FALSE)
            }else{}
            cat("******* End Show (JointCorrectionObject) ******* \n")
          })

#' @rdname .JBC
setMethod(f = ".JBC",
          signature = "JointCorrection",
          definition = function(.Object, cond = "P", threshold = 0.01, 
                                jittering = T, jitter.amount = 1e-5, 
                                separate = F, fit.skew = T){

#            if(fit.skew)print("using skew-normal distribution")
            #Create data frames for the data. Update these data frames whenever necessary.
            obs <- list(T=.Object@obs@data[,1],
                        P=.Object@obs@data[,2],
                        margT=NA,margP=NA,pwet=NA,
                        wet=NA,dry=NA,cpar1=NA,cpar2=NA)
            ctrl <- list(T=.Object@ctrl@data[,1],
                         P=.Object@ctrl@data[,2],
                         margT=NA,margP=NA,pwet=NA,
                         wet=NA,dry=NA,cpar1=NA)
            scen <- list(T=.Object@scen@data[,1],
                         P=.Object@scen@data[,2],
                         margT=NA,margP=NA,pwet=NA,
                         wet=NA,dry=NA,cpar1=NA)
            adj <- list(T=array(NA,dim=c(length(.Object@scen@data[,1]))),
                        P=array(NA,dim=c(length(.Object@scen@data[,2]))),
                        margT=NA,margP=NA,pwet=NA,
                        wet=NA,dry=NA,cpar1=NA)
            
            if(jittering){
              obs$T <- obs$T+rnorm(length(obs$T))*jitter.amount
              obs$P <- obs$P+runif(length(obs$P))*jitter.amount
              ctrl$T <- ctrl$T+rnorm(length(ctrl$T))*jitter.amount
              ctrl$P <- ctrl$P+runif(length(ctrl$P))*jitter.amount
              scen$T <- scen$T+rnorm(length(scen$T))*jitter.amount
              scen$P <- scen$P+runif(length(scen$P))*jitter.amount
            }
            
            tmp <- .ppRain(ref = obs$P, adj = ctrl$P, ref.threshold = threshold)
            ctrl$P <- tmp$adj

            tmp <- .ppRain(ref = obs$P, adj = scen$P, ref.threshold = threshold)
            scen$P <- tmp$adj

            if(tmp$nDry[2]==length(scen$P)){
              warning("All dry days!")
              .Object@adj@data[,1] <- scen$T
              .Object@adj@data[,2] <- scen$P
              return(.Object)
            }

            obs$wet <- which(obs$P>threshold)
            obs$dry <- which(obs$P<=threshold)
            obs$pwet <- length(obs$wet)/length(obs$P)

            ctrl$wet <- which(ctrl$P>0)
            ctrl$dry <- which(ctrl$P==0)

            scen$wet <- which(scen$P>0)
            scen$dry <- which(scen$P==0)

            ctrl$pwet <- length(ctrl$P[which(ctrl$P>0)])/length(ctrl$P)
            scen$pwet <- length(scen$P[which(scen$P>0)])/length(scen$P)
            
            obs$margP <- .fitMarginal(as.numeric(obs$P[obs$wet]), type="gamma")
            ctrl$margP <- .fitMarginal(as.numeric(ctrl$P[ctrl$wet]), type="gamma")
            scen$margP <- .fitMarginal(as.numeric(scen$P[scen$wet]), type="gamma")
            
            if(separate){
              
              if(fit.skew){
                obs$margTW <- suppressWarnings(fitdistrplus::fitdist(as.numeric(obs$T[obs$wet]),"sn",
                                                    method="mle", start=list(xi=0,omega=1,alpha=1),
                                                    lower=c("-inf",0,"-inf"), upper=c("inf","inf","inf")))
                obs$margTD <- suppressWarnings(fitdistrplus::fitdist(as.numeric(obs$T[obs$dry]),"sn",
                                                    method="mle", start=list(xi=1,omega=1,alpha=1),
                                                    lower=c("-inf",0,"-inf"), upper=c("inf","inf","inf")))
                
                ctrl$margTW <- suppressWarnings(fitdistrplus::fitdist(as.numeric(ctrl$T[ctrl$wet]),"sn",
                                                     method="mle", start=list(xi=1,omega=1,alpha=1),
                                                     lower=c("-inf",0,"-inf"), upper=c("inf","inf","inf")))
                ctrl$margTD <- suppressWarnings(fitdistrplus::fitdist(as.numeric(ctrl$T[ctrl$dry]),"sn",
                                                     method="mle", start=list(xi=1,omega=1,alpha=1),
                                                     lower=c("-inf",0,"-inf"), upper=c("inf","inf","inf")))
              }else{
                obs$margTW <- .fitMarginal(as.numeric(obs$T[obs$wet]),type="norm")
                obs$margTD <- .fitMarginal(as.numeric(obs$T[obs$dry]),type="norm")
                
                ctrl$margTW <- .fitMarginal(as.numeric(ctrl$T[ctrl$wet]),type="norm")
                ctrl$margTD <- .fitMarginal(as.numeric(ctrl$T[ctrl$dry]),type="norm")
              }
              
            }else{
              if(fit.skew){
                obs$margTW <- obs$margTD <- suppressWarnings(fitdistrplus::fitdist(as.numeric(obs$T),"sn",
                                                                  method="mle",start=list(xi=0,omega=1,alpha=1),
                                                                  lower=c("-inf",0,"-inf"),upper=c("inf","inf","inf"))) 
                ctrl$margTW <- ctrl$margTD <- suppressWarnings(fitdistrplus::fitdist(as.numeric(ctrl$T),"sn",
                                                                    method="mle",start=list(xi=1,omega=1,alpha=1),
                                                                    lower=c("-inf",0,"-inf"),upper=c("inf","inf","inf"))) 
              }else{
                obs$margTW <- obs$margTD <- .fitMarginal(as.numeric(obs$T), type="norm")
                ctrl$margTW <- ctrl$margTD <- .fitMarginal(as.numeric(ctrl$T), type="norm")
              }
            }
            
            if(fit.skew){
              margin.names <- c("sn","gamma")
              marg1.obs <- list(xi = obs$margTW$estimate[1], omega = obs$margTW$estimate[2], 
                                alpha = obs$margTW$estimate[3])
              marg2.obs <- list(shape = obs$margP$estimate[1], rate = obs$margP$estimate[2])
              marg1.ctrl <- list(xi = ctrl$margTW$estimate[1], omega = ctrl$margTW$estimate[2], 
                                 alpha = ctrl$margTW$estimate[3])
              marg2.ctrl <- list(shape = ctrl$margP$estimate[1], rate = ctrl$margP$estimate[2])
              
            }else{
              marg1.obs <- list(mean=obs$margTW$estimate[1], sd=obs$margTW$estimate[2])
              marg2.obs <- list(shape=obs$margP$estimate[1], rate=obs$margP$estimate[2])
              marg1.ctrl <- list(mean=ctrl$margTW$estimate[1], sd=ctrl$margTW$estimate[2])
              marg2.ctrl <- list(shape=ctrl$margP$estimate[1], rate=ctrl$margP$estimate[2])
              margin.names <- c("norm","gamma")
            }
            
            if(fit.skew){
              U1 <- cbind(psn(x=obs$T[obs$wet], xi=marg1.obs$xi, omega=marg1.obs$omega, 
                             alpha=marg1.obs$alpha),
                       pgamma(obs$P[obs$wet], shape=marg2.obs$shape, rate=marg2.obs$rate))
              obs$cpar1 <- coef(fitCopula(normalCopula(dim=2), data=U1, method="ml"))
              
              U2 <- cbind(psn(x=ctrl$T[ctrl$wet], xi=marg1.ctrl$xi, omega=marg1.ctrl$omega, 
                             alpha=marg1.ctrl$alpha),
                       pgamma(ctrl$P[ctrl$wet], shape=marg2.ctrl$shape, rate=marg2.ctrl$rate))
              par(mfrow=c(1,2))
              
              ctrl$cpar1 <- coef(fitCopula(normalCopula(dim=2), data=U2, method="ml"))
            } else{
              U1 <- cbind(pnorm(obs$T[obs$wet], mean=marg1.obs$mean, sd=marg1.obs$sd),
                       pgamma(obs$P[obs$wet], shape=marg2.obs$shape, rate=marg2.obs$rate))
              
              obs$cpar1 <- coef(fitCopula(normalCopula(dim=2), data=U1, method="ml"))
              
              U2 <- cbind(pnorm(ctrl$T[ctrl$wet], mean=marg1.ctrl$mean, sd=marg1.ctrl$sd),
                       pgamma(ctrl$P[ctrl$wet], shape=marg2.ctrl$shape, rate=marg2.ctrl$rate))
              ctrl$cpar1 <- coef(fitCopula(normalCopula(dim=2), data=U2, method="ml"))
            }
            
            if(cond=="P"){
              print(cond)
              adj <- .adjPT(obs, ctrl, scen, fit.skew)
            } else {
              print(cond)
              adj <- .adjTP(obs, ctrl, scen, fit.skew)
            }
            fit.normCor <- copula::fitCopula(copula::normalCopula(dim=2),
                                             copula::pobs(matrix(c(adj$T[scen$wet],adj$P[scen$wet]),ncol=2)),
                                             method="itau",start=NULL,lower=NULL,upper=NULL,
                                             optim.method="BFGS",optim.control=list(maxit=100))
            
            adj$cpar1 <- fit.normCor@copula@parameters
            .Object@adj@data[,1] <- adj$T
            .Object@adj@data[,2] <- adj$P
            .Object@bc.attributes[["threshold"]] <- threshold
            .Object@bc.attributes[["cond"]] <- cond
            .Object@bc.attributes[["copula.param"]] <- adj$cpar1
            .Object@method <- "J1"
            return(.Object)
          })
