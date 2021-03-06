## dunnettT3Test.R
## Part of the R package: PMCMRplus
##
## Copyright (C) 2017, 2018 Thorsten Pohlert
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  A copy of the GNU General Public License is available at
##  http://www.r-project.org/Licenses/
##
#' @name dunnettT3Test
#' @title Dunnett's T3 Test
#' @description
#' Performs Dunnett's all-pairs comparison test for normally distributed
#' data with unequal variances.
#'
#' @template class-PMCMR
#'
#' @details
#' For all-pairs comparisons in an one-factorial layout
#' with normally distributed residuals but unequal groups variances
#' the T3 test of Dunnett can be performed. A total of \eqn{m = k(k-1)/2}
#' hypotheses can be tested. The null hypothesis
#' H\eqn{_{ij}: \mu_i(x) = \mu_j(x)} is tested in the two-tailed test
#' against the alternative
#' A\eqn{_{ij}: \mu_i(x) \ne \mu_j(x), ~~ i \ne j}.
#'
#' The p-values are computed from the studentized maximum modulus distribution
#' that is the equivalent of the multivariate t distribution
#' with \eqn{\rho = 0}. The function \code{\link[mvtnorm]{pmvt}} is used to
#' calculate the \eqn{p}-values.
#'
#' @references
#' C. W. Dunnett (1980) Pair wise multiple comparisons in the unequal
#'  variance case, \emph{Journal of the American Statistical
#'  Association} \bold{75}, 796--800.
#'
#' @keywords htest
#' @concept allPairsComparisons
#'
#' @examples
#' set.seed(245)
#' mn <- rep(c(1, 2^(1:4)), each=5)
#' sd <- rep(1:5, each=5)
#' x <- mn + rnorm(25, sd = sd)
#' g <- factor(rep(1:5, each=5))
#'
#' fit <- aov(x ~ g)
#' shapiro.test(residuals(fit))
#' bartlett.test(x ~ g) # var1 != varN
#' anova(fit)
#' summary(dunnettT3Test(x, g))
#'
#' @seealso
#' \code{\link[mvtnorm]{pmvt}}
#' @importFrom mvtnorm pmvt
#' @importFrom stats complete.cases
#' @importFrom stats var
#' @export
dunnettT3Test <- function(x, ...) UseMethod("dunnettT3Test")

#' @rdname dunnettT3Test
#' @method dunnettT3Test default
#' @aliases dunnettT3Test.default
#' @template one-way-parms
#' @export
dunnettT3Test.default <-
function(x, g, ...){
        ## taken from stats::kruskal.test

    if (is.list(x)) {
        if (length(x) < 2L)
            stop("'x' must be a list with at least 2 elements")
        DNAME <- deparse(substitute(x))
        x <- lapply(x, function(u) u <- u[complete.cases(u)])
        k <- length(x)
        l <- sapply(x, "length")
        if (any(l == 0))
            stop("all groups must contain data")
        g <- factor(rep(1 : k, l))
        x <- unlist(x)
    }
    else {
        if (length(x) != length(g))
            stop("'x' and 'g' must have the same length")
        DNAME <- paste(deparse(substitute(x)), "and",
                       deparse(substitute(g)))
        OK <- complete.cases(x, g)
        x <- x[OK]
        g <- g[OK]
        if (!all(is.finite(g)))
            stop("all group levels must be finite")
        g <- factor(g)
        k <- nlevels(g)
        if (k < 2)
            stop("all observations are in the same group")
    }

    ## prepare dunnettT3 test
    ni <- tapply(x, g, length)
    n <- sum(ni)
    xi <- tapply(x, g, mean)
    s2i <- tapply(x, g, var)

    s2in <- 1 / (n - k) * sum(s2i * (ni - 1))

    compare.stats <- function(i,j) {
        dif <- xi[i] - xi[j]
        A <- (s2i[i] / ni[i] + s2i[j] / ni[j])
        tval <- dif / sqrt(A)
        return(tval)
    }

    PSTAT <- pairwise.table(compare.stats,levels(g), p.adjust.method="none" )

    getDf <- function(i, j){
        A <- (s2i[i] / ni[i] + s2i[j] / ni[j])
        df <- A^2 / (s2i[i]^2 / (ni[i]^2 * (ni[i] - 1)) +
                    s2i[j]^2 / (ni[j]^2 * (ni[j] - 1)))
        return(df)
        }

    DF <- pairwise.table(getDf, levels(g), p.adjust.method="none" )

    ## prepare matrix
    m <- k * (k - 1) / 2 # number of comparisons
    cr <- diag(m)
    pval <- rep(NA, m)

    ## use Studentized Maximum Modulus Distribution
    ## equals Two-sided Multivariate t distribution
    ## use mvtnorm critical values

    df <- as.vector(DF)
    df <- df[!is.na(df)]
    df <- round(df, digits = 0) # round to integer
    pstat <- as.vector(PSTAT)
    pstat <- pstat[!is.na(pstat)]

    for (i in 1:m){
        lo <- -rep(abs(pstat[i]), m)
        up <- rep(abs(pstat[i]), m)
        pval[i] <- 1 - pmvt(lower = lo,
                            upper = up,
                            df = df[i],
                            corr = cr)
    }

    ## create output matrix
    PVAL <- PSTAT
    PVAL[!is.na(PVAL)] <- pval

    DIST <- "t"
    alternative <- "two.sided"
    METHOD <- paste0("Dunnett's T3 test for multiple comparisons\n",
                     "\t\twith unequal variances")
    p.adjust.method <- "single-step"
    MODEL <- data.frame(x, g)
    ans <- list(method = METHOD, data.name = DNAME, p.value = PVAL,
                statistic = PSTAT, p.adjust.method = p.adjust.method,
                model = MODEL, dist = DIST, alternative = alternative)
    class(ans) <- "PMCMR"
    ans
}

#' @rdname dunnettT3Test
#' @method dunnettT3Test formula
#' @aliases dunnettT3Test.formula
#' @template one-way-formula
#' @export
dunnettT3Test.formula <-
function(formula, data, subset, na.action, ...)
{
    mf <- match.call(expand.dots=FALSE)
    m <- match(c("formula", "data", "subset", "na.action"), names(mf), 0L)
    mf <- mf[c(1L, m)]
    mf[[1L]] <- quote(stats::model.frame)

   if(missing(formula) || (length(formula) != 3L))
        stop("'formula' missing or incorrect")
    mf <- eval(mf, parent.frame())
    if(length(mf) > 2L)
       stop("'formula' should be of the form response ~ group")
    DNAME <- paste(names(mf), collapse = " by ")
    names(mf) <- NULL
    y <- do.call("dunnettT3Test", c(as.list(mf)))
    y$data.name <- DNAME
    y
}
