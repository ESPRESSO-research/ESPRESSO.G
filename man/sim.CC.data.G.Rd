\name{sim.CC.data.G}
\alias{sim.CC.data.G}
\title{Simulates case and controls}
\usage{
sim.CC.data.G(block.size = 20000, numcases = 2000, numcontrols = 8000,
  allowed.sample.size = 2e+07, disease.prev = 0.1, geno.model = 0,
  MAF = 0.1, geno.OR = 1.5, baseline.OR = 12.36, pheno.error = c(0.1,
  0.1))
}
\arguments{
  \item{block.size}{number of observations to generate per
  iteration until the specified number of cases and
  controls is achieved.}

  \item{numcases}{number of cases to generate.}

  \item{numcontrols}{number of controls to generate.}

  \item{allowed.sample.size}{maximum number of observations
  allowed i.e. the total size of the population to sample
  from.}

  \item{disease.prev}{prevalence of the binary outcome.}

  \item{geno.model}{genetic model; binary=0 and and
  additive=1.}

  \item{MAF}{minor allele frequency of the genetic
  variant.}

  \item{geno.OR}{odds ratio of the genetic determinant.}

  \item{baseline.OR}{baseline odds ratio for subject on 95
  percent population centile versus 5 percentile. This
  parameter reflects the heterogeneity in disease risk
  arising from determinates that have not been measured or
  have not been included in the model.}

  \item{pheno.error}{misclassification rates: 1-sensitivity
  and 1-specificity}
}
\value{
a list which holds a matrix, \code{data}, that contains the
phenotype and genotype statuses and an integer,
\code{allowed.sample.size.exceeded}, which tells if the
maximum population size has been exceeded.
}
\description{
Generates affected and non-affected subjects until the set
sample size is achieved
}
\details{

}
\author{
Gaye A.
}
\keyword{internal}

