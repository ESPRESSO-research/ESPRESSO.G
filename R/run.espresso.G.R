#' 
#' @title Runs a full ESPRESSO analysis
#' @description This function calls the functions required to run a full ESPRESSO analysis 
#'  where the model consit of an outcome (binary or continuous) determinant by a binary or 
#'  continuous environmental determinant.
#' @param simulation.params general parameters for the scenario(s) to analyse
#' @param pheno.params paramaters for the outcome variables
#' @param geno.params parameters for the genetic determinant
#' @param scenarios2run the indices of the scenarios one wish to analyse
#' @return a summary table that contains both the input parameters and the results of the analysis
#' @export
#' @author Amadou Gaye
#' @examples {
#'  
#' # load the table that hold the input parameters; each of the table hold parameters for 4 scenarios:
#' # scenario 1: a binary outcome determined by a binary exposure
#' # scenario 2: a binary outcome determined by a quantitative and normally distributed exposure 
#' # scenario 3: a quantitative outcome determined by a binary exposure
#' # scenario 4: a quantitative outcome determined by a quantitative and normally distributed exposure 
#' data(simulation.params) 
#' data(pheno.params)
#' data(geno.params)
#' 
#' # run the function for the first two scenarios (by default all the scenarios are ran)
#' run.espresso.G(simulation.params, pheno.params, geno.params, scenarios2run=c(1,2))
#'
#' # run the function for the last two scenarios (by default all the scenarios are ran)
#' run.espresso.G(simulation.params, pheno.params, geno.params, scenarios2run=c(3,4))
#' }
#'
run.espresso.G <- function(simulation.params=NULL, pheno.params=NULL, geno.params=NULL, scenarios2run=1){

  # IF AN INPUT FILE IS NOT SUPPLIED LOAD THE DEFAULT TABLES WARNING
  if(is.null(simulation.params)){
    cat("\n WARNING!\n")
    cat(" No simulation parameters supplied\n")
    cat(" The default simulation parameters will be used\n")
    simulation.params <- data(simulation.params)
  }
  
  if(is.null(pheno.params)){
    cat("\n WARNING!\n")
    cat(" No outcome parameters supplied\n")
    cat(" The default outcome parameters will be used\n")
    pheno.params <- data(pheno.params)
  }
  
  if(is.null(geno.params)){
    cat("\n WARNING!\n")
    cat(" No genetic parameters supplied\n")
    cat(" The default genetic parameters will be used\n")
    geno.params <- data(geno.params)
  }

  # MERGE INPUT FILES TO MAKE ONE TABLE OF PARAMETERS
  s.temp <- merge(simulation.params, pheno.params)
  s.parameters <- merge(s.temp, geno.params)
  
  
  #----------LOAD SET UP UP INITIAL PARAMETERS------------#
  
  # PRINT TRACER CODE EVERY Nth ITERATION
  # THIS ENSURES THAT YOU CAN SEE IF THE PROGRAM GRINDS TO A HALT FOR SOME REASON (IT SHOULDN'T)
  trace.interval <- 10
  
  
  # CREATE UP TO 20M SUBJECTS IN BLOCKS OF 20K UNTIL REQUIRED NUMBER OF
  # CASES AND CONTROLS IS ACHIEVED. IN GENERAL THE ONLY PROBLEM IN ACHIEVING THE
  # REQUIRED NUMBER OF CASES WILL OCCUR IF THE DISEASE PREVALENCE IS VERY LOW
  allowed.sample.size <- 20000000
  block.size <- 20000
  
  
  # DECLARE MATRIX THAT STORE THE RESULTS FOR EACH SCENARIO (ONE PER SCENARIO PER ROW)
  output.file <- "output.csv"
  output.matrix <- matrix(numeric(0), ncol=27)
  column.names <- c(colnames(s.parameters), "exceeded.sample.size?","numcases.required", "numcontrols.required", "numsubjects.required", "empirical.power", "modelled.power",
  "estimated.OR")
  write(t(column.names),output.file,dim(output.matrix)[2],append=TRUE,sep=";")
  
  
  #-----------LOOP THROUGH THE SCENARIOS - DEALS WITH ONE SCENARIO AT A TIME-------------
  
  for(j in c(scenarios2run))
  {
  
     # RANDOM NUMBER GENERATOR STARTS WITH SEED SET AS SPECIFIED 
     set.seed(s.parameters$seed.val[j])
  
     # SIMULATION PARAMETERS
     scenario.id <- s.parameters$scenario.id[j]				     
     seed.val <- s.parameters$seed.val[j]					          
     numsims <- s.parameters$numsims[j]					            
     numcases <- s.parameters$numcases[j]					          
     numcontrols <- s.parameters$numcontrols[j]		
     numsubjects <- s.parameters$numsubjects[j]				     
     baseline.OR <- s.parameters$RR.5.95[j]					           
     pval <- s.parameters$p.val[j]						                
     power <- s.parameters$power[j]
     
     # OUTCOME PARAMETERS
     pheno.model <- s.parameters$pheno.model[j]
     disease.prev <- s.parameters$disease.prev[j]
     pheno.error <- c(1-s.parameters$pheno.sensitivity[j],1-s.parameters$pheno.specificity[j])
     pheno.reliability <- s.parameters$pheno.reliability[j]    
  
     # GENETIC DETERMINANTS PARAMETERS
     geno.model<- s.parameters$geno.model[j]
     MAF <-  s.parameters$MAF[j]    
     geno.OR <- s.parameters$geno.OR[j]
     geno.efkt <- s.parameters$geno.efkt[j]
     geno.error <- c(1-s.parameters$geno.sensitivity[j],1-s.parameters$geno.specificity[j])
  
     # VECTORS TO HOLD BETA, SE AND Z VALUES AFTER EACH RUN OF THE SIMULATION
     beta.values <- rep(NA,numsims)
     se.values <- rep(NA,numsims)
     z.values<-rep(NA,numsims)
  
  
     # TRACER TO DETECT EXCEEDING MAX ALLOWABLE SAMPLE SIZE
     sample.size.excess <- 0
  
     # GENERATE AND ANALYSE DATASETS ONE AT A TIME 
     for(s in 1:numsims)            # s from 1 to total number of simulations
     {
  
        #----------------------------------GENERATE "TRUE" DATA-----------------------------#
  
        if(pheno.model == 0){ # UNDER BINARY OUTCOME MODEL
  		      # GENERATE CASES AND CONTROLS UNTILL THE REQUIRED NUMBER OF CASES, CONTROLS IS ACHIEVED 
  			     sim.data <- sim.CC.data.G(block.size, numcases, numcontrols, allowed.sample.size, disease.prev, geno.model, MAF, geno.OR, baseline.OR)
  			     true.data <- sim.data$data
  
        }else{ # UNDER QUANTITATIVE OUTCOME MODEL
          # GENERATE THE SPECIFIED NUMBER OF SUBJECTS
          true.data <- sim.QTL.data.G(numsubjects, geno.model, MAF, geno.efkt)
        }
  
        #------------SIMULATE ERRORS AND ADD THEM TO THE TRUE COVARIATES DATA TO OBTAIN OBSERVED COVARIATES DATA-----------#
  
        # ADD APPROPRIATE ERRORS TO PRODUCE OBSERVED GENOTYPES 
        observed.data <- get.observed.data.G(true.data,pheno.model,pheno.error,pheno.reliability,geno.model, MAF, geno.error)
  
        
        #--------------------------DATA ANALYSIS ----------------------------#
  
        glm.estimates <- glm.analysis.G(pheno.model, observed.data)
  
  			   beta.values[s] <- glm.estimates[[1]]
  			   se.values[s] <- glm.estimates[[2]]
  			   z.values[s] <- glm.estimates[[3]]
  			   
  			   # PRINT TRACER AFTER EVERY Nth DATASET CREATED
        if(s %% trace.interval ==0)cat("\n",s,"of",numsims,"runs completed in scenario",scenario.id)
  
     }
     cat("\n\n")
  
     #------------------------ SUMMARISE RESULTS ACROSS ALL SIMULATIONS---------------------------#
  
     # SUMMARISE PRIMARY PARAMETER ESTIMATES
     # COEFFICIENTS ON LOG-ODDS SCALE
     mean.beta <- mean(beta.values, na.rm=T)
     mean.se <- sqrt(mean(se.values^2, na.rm=T))
     mean.model.z <- mean.beta/mean.se
     
   
     #---------------------------POWER AND SAMPLE SIZE CALCULATIONS----------------------#
  
     # CALCULATE THE SAMPLE SIZE REQUIRED UNDER EACH MODEL
     sample.sizes.required <- samplsize.calc(numcases, numcontrols, numsubjects, pheno.model, pval, power, mean.model.z)
  
     # CALCULATE EMPIRICAL POWER AND THE MODELLED POWER 
     # THE EMPIRICAL POWER IS SIMPLY THE PROPORTION OF SIMULATIONS IN WHICH
     # THE Z STATISTIC FOR THE PARAMETER OF INTEREST EXCEEDS THE Z STATISTIC
     # FOR THE DESIRED LEVEL OF STATISTICAL SIGNIFICANCE
     power <- power.calc(pval, z.values, mean.model.z)
  
  
     #------------------MAKE FINAL A TABLE THAT HOLDS BOTH INPUT PARAMETERS AND OUTPUT RESULTS---------------#
  
     critical.res <- get.critical.results.G(j, pheno.model, geno.model, sample.sizes.required, power$empirical, power$modelled, mean.beta)
  
     # 	WHEN OUTCOME IS BINARY INFORM IF RECORD EXCEEDED MAXIMUM SAMPLE SIZE
     if(pheno.model==0){
       sample.size.excess <- sim.data$allowed.sample.size.exceeded
       if(sample.size.excess==1)
       {
         excess <- "yes"
         cat("\nTO GENERATE THE NUMBER OF CASES SPECIFIED AT OUTSET\n")
         cat("THE SIMULATION EXCEEDED THE MAXIMUM POPULATION SIZE OF ", allowed.sample.size,"\n")
       }else{
         excess <- "no"
       }
     }
     
     if(pheno.model==0){
        mod <- "binary"
        inparams <- s.parameters[j,]
        inparams [c(6,14,18)] <- "NA"
        inputs <- inparams
        outputs <- c(excess, critical.res[[2]], critical.res[[3]], "NA", critical.res[[4]], critical.res[[5]], critical.res[[6]])
     }else{
        mod <- "quantitative"
        inparams <- s.parameters[j,]
        inparams [c(4,5,11,12,13,17)] <- "NA"
        inputs <- inparams
        outputs <- c("NA", "NA", "NA", critical.res[[2]], critical.res[[3]], critical.res[[4]], critical.res[[5]])
     }
  
     jth.row <- as.character(c(inputs,outputs))
     write(t(jth.row),output.file,dim(output.matrix)[2],append=TRUE,sep=";")
  }
}