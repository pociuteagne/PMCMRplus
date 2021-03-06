% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tamhaneDunnettTest.R
\name{tamhaneDunnettTest}
\alias{tamhaneDunnettTest}
\alias{tamhaneDunnettTest.default}
\alias{tamhaneDunnettTest.formula}
\title{Tamhane-Dunnett Many-to-One Comparison Test}
\usage{
tamhaneDunnettTest(x, ...)

\method{tamhaneDunnettTest}{default}(x, g, alternative = c("two.sided",
  "greater", "less"), ...)

\method{tamhaneDunnettTest}{formula}(formula, data, subset, na.action,
  alternative = c("two.sided", "greater", "less"), ...)
}
\arguments{
\item{x}{a numeric vector of data values, or a list of numeric data
vectors.}

\item{\dots}{further arguments to be passed to or from methods.}

\item{g}{a vector or factor object giving the group for the
corresponding elements of \code{"x"}.
Ignored with a warning if \code{"x"} is a list.}

\item{alternative}{the alternative hypothesis.
Defaults to \code{"two.sided"}.}

\item{formula}{a formula of the form \code{response ~ group} where
\code{response} gives the data values and \code{group} a vector or
factor of the corresponding groups.}

\item{data}{an optional matrix or data frame (or similar: see
\code{\link{model.frame}}) containing the variables in the
formula \code{formula}.  By default the variables are taken from
\code{environment(formula)}.}

\item{subset}{an optional vector specifying a 
subset of observations to be used.}

\item{na.action}{a function which indicates what should happen when
the data contain \code{NA}s.  Defaults to \code{getOption("na.action")}.}
}
\value{
A list with class \code{"PMCMR"} containing the following components:
\describe{
 \item{method}{a character string indicating what type of test was performed.}
 \item{data.name}{a character string giving the name(s) of the data.}
 \item{statistic}{lower-triangle matrix of the estimated
quantiles of the pairwise test statistics.}
 \item{p.value}{lower-triangle matrix of the p-values for the pairwise tests.}
 \item{alternative}{a character string describing the alternative hypothesis.}
\item{p.adjust.method}{a character string describing the method for p-value
adjustment.}
\item{model}{a data frame of the input data.}
\item{dist}{a string that denotes the test distribution.}
}
}
\description{
Performs Tamhane-Dunnett's multiple comparisons test with one control.
For many-to-one comparisons in an one-factorial layout
with normally distributed residuals and unequal variances
Tamhane-Dunnett's test can be used. A total of \eqn{m = k-1}
hypotheses can be tested. The null hypothesis
H\eqn{_{i}: \mu_0(x) = \mu_i(x)} is tested in the two-tailed test
against the alternative
A\eqn{_{i}: \mu_0(x) \ne \mu_i(x), ~~ 1 \le i \le k-1}.

The p-values for the test are calculated from the multivariate t distribution
as implemented in the function \code{\link[mvtnorm]{pmvt}}.
}
\examples{
set.seed(245)
mn <- c(1, 2, 2^2, 2^3, 2^4)
x <- rep(mn, each=5) + rnorm(25)
g <- factor(rep(1:5, each=5))

fit <- aov(x ~ g - 1)
shapiro.test(residuals(fit))
bartlett.test(x ~ g - 1)
anova(fit)
summary(tamhaneDunnettTest(x, g, alternative = "greater"))

}
\references{
OECD (ed. 2006) \emph{Current approaches in the statistical analysis
   of ecotoxicity data: A guidance to application - Annexes}. OECD Series
   on testing and assessment, No. 54.
}
\seealso{
\code{\link[mvtnorm]{pmvt}}, \code{\link{welchManyOneTTest}}
}
\concept{ManyOneComparisons}
\keyword{htest}
