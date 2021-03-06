#  normalScoresAllPairsTest.R
#
#  Copyright (C) 2017, 2018 Thorsten Pohlert
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  http://www.r-project.org/Licenses/

#' @title Lu-Smith All-Pairs Comparison Normal Scores Test
#' @description Performs Lu-Smith all-pairs comparison
#' normal scores test.
#' @details
#' For all-pairs comparisons in an one-factorial layout
#' with non-normally distributed residuals Lu and Smith's
#' normal scores transformation can be used prior to
#' an all-pairs comparison test. A total of \eqn{m = k(k-1)/2}
#' hypotheses can be tested. The null hypothesis
#' H\eqn{_{ij}: F_i(x) = F_j(x)} is tested in the two-tailed test
#' against the alternative
#' A\eqn{_{ij}: F_i(x) \ne F_j(x), ~~ i \ne j}.
#' For \code{p.adjust.method = "single-step"} the
#' Tukey's studentized range distribution is used to calculate
#' p-values (see \code{\link{Tukey}}). Otherwise, the
#' t-distribution is used for the calculation of p-values
#' with a latter p-value adjustment as
#' performed by \code{\link{p.adjust}}.
#'
#' @name normalScoresAllPairsTest
#' @template class-PMCMR
#' @keywords htest nonparametric
#' @concept NormalScores
#' @concept AllPairsComparison
#' @references
#' Lu, H., Smith, P. (1979) Distribution of normal scores statistic
#' for nonparametric one-way analysis of variance.
#' \emph{Journal of the American Statistical Association} \bold{74}, 715--722.
#' @seealso
#' \code{\link{normalScoresTest}}, \code{\link{normalScoresManyOneTest}}, \code{\link[SuppDists]{normOrder}}.
#' @export
normalScoresAllPairsTest <- function(x, ...) UseMethod("normalScoresAllPairsTest")

#' @rdname normalScoresAllPairsTest
#' @method normalScoresAllPairsTest default
#' @aliases normalScoresAllPairsTest.default
#' @template one-way-parms
#' @param p.adjust.method method for adjusting p values (see \code{\link{p.adjust}}).
#' @importFrom stats ptukey
#' @importFrom stats pt
#' @importFrom stats p.adjust
#' @importFrom stats p.adjust.methods
#' @importFrom stats pairwise.table
#' @importFrom stats complete.cases
#' @importFrom SuppDists normOrder
#' @export
normalScoresAllPairsTest.default <-
    function(x, g,  p.adjust.method = c("single-step", p.adjust.methods), ...)
{
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
                                        #
        if (is.null(x$p.adjust.method)){
            p.adjust.method <- p.adjust.methods[1]
        } else {
            p.adjust.method <- x$p.adjust.method
        }
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

    n <- length(x)
    if (n < 2)
        stop("not enough observations")
    r <- rank(x, ties.method = "random")
    p.adjust.method <- match.arg(p.adjust.method)

    ## transform to xi-scores
    eij <- normOrder(n)
    zscores <- eij[r]

    ei <- tapply(zscores, g, sum)
    ni <- tapply(zscores, g, length)
    s2 <- (1 / (n - 1)) * sum(zscores^2)
    STATISTIC <- (1 / s2) * sum(ei^2 / ni)
    PARAMETER <- k - 1
    Smn <- ei / ni

    compare.stats <- function(i,j) {
        dif <- abs(Smn[i] - Smn[j])
        B <- (1 / ni[i] + 1 / ni[j])
        val <- dif / sqrt(s2 * (n-1-STATISTIC)/(n-k) * B)
        return(val)
    }
    PSTAT <- pairwise.table(compare.stats,levels(g),
                            p.adjust.method="none" )

    if (p.adjust.method != "single-step"){
        compare.levels <- function(i,j) {
            dif <- abs(Smn[i] - Smn[j])
            B <- (1 / ni[i] + 1 / ni[j])
            val <- dif / sqrt(s2 * (n-1-STATISTIC)/(n-k) * B)
            pval <- 2 * pt(abs(val), df=n - k, lower.tail=FALSE)
            return(pval)
        }
        PVAL <- pairwise.table(compare.levels,levels(g),
                               p.adjust.method=p.adjust.method )
        DIST <- "t"
        PARMS <- n - k
        names(PARMS) <- "df"
    } else {
        compare.tukey <- function(i,j) {
            dif <- abs(Smn[i] - Smn[j])
            B <- (1 / ni[i] + 1 / ni[j])
            qval <- sqrt(2) * dif / sqrt(s2 * (n-1-STATISTIC)/(n-k) * B)
            pval <- ptukey(abs(qval), nmeans = k, df=n - k, lower.tail=FALSE)
            return(pval)
        }
        PVAL <- pairwise.table(compare.tukey, levels(g),
                               p.adjust.method="none")
        PSTAT <- PSTAT * sqrt(2)
        DIST <- "q"
        PARMS <- c(k, n-k)
        names(PARMS) <- c("nmeans", "df")
    }
    METHOD <- paste("Lu-Smith normal scores test for", "
               multiple comparisons of independent samples", sep="\t")
    MOD <- data.frame(x = x, g= g)
    ans <- list(method = METHOD, data.name = DNAME, p.value = PVAL,
                statistic = PSTAT, p.adjust.method = p.adjust.method,
                dist = DIST, model = MOD, parameter = PARMS)
    class(ans) <- "PMCMR"
    return(ans)
}

#' @rdname normalScoresAllPairsTest
#' @method normalScoresAllPairsTest formula
#' @aliases normalScoresAllPairsTest
#' @template one-way-formula
#' @export
normalScoresAllPairsTest.formula <-
    function(formula, data, subset, na.action,
             p.adjust.method = c("single-step", p.adjust.methods), ...)
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
    p.adjust.method <- match.arg(p.adjust.method)
    names(mf) <- NULL
    y <- do.call("normalScoresAllPairsTest",
                 c(as.list(mf), p.adjust.method = p.adjust.method))
    y$data.name <- DNAME
    y
}
