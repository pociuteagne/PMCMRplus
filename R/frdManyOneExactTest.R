## frdManyOneExactTest.R
## Part of the R package: PMCMR
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
##
#' @name frdManyOneExactTest
#' @title  Exact Many-to-One Test
#' for Unreplicated Blocked Data
#'
#' @description
#' Performs an exact non-parametric many-to-one comparison test
#' for Friedman-type ranked data according to Eisinga et al. (2017).
#'
#' @details
#' For many-to-one comparisons (pairwise comparisons with one control)
#' in a two factorial unreplicated complete block design
#' with non-normally distributed residuals, an exact test can be
#' performed on Friedman-type ranked data.
#'
#' Let there be \eqn{k} groups including the control,
#' then the number of treatment levels is \eqn{m = k - 1}.
#' A total of \eqn{m} pairwise comparisons can be performed between
#' the \eqn{i}-th treatment level and the control.
#' H\eqn{_i: \theta_0 = \theta_i} is tested in the two-tailed case against
#' A\eqn{_i: \theta_0 \ne \theta_i, ~~ (1 \le i \le m)}.
#'
#' The exact \eqn{p}-values
#' are computed using the code of \code{"pexactfrsd.R"}
#' that was a supplement to the publication of Eisinga et al. (2017).
#' Additionally, any of the \eqn{p}-adjustment methods
#' as included in \code{\link{p.adjust}} can be selected, for \eqn{p}-value
#' adjustment.
#'
#' @inherit frdAllPairsExactTest references
# @references
# R. Eisinga, T. Heskes, B. Pelzer, M. Te Grotenhuis (2017),
#  Exact p-values for Pairwise Comparison of Friedman Rank Sums,
#  with Application to Comparing Classifiers, \emph{BMC Bioinformatics}, 18:68.
#
#' @concept FriedmanTest
#' @concept Rank
#' @concept ManyToOne
#' @keywords htest nonparametric
#' @example examples/frdManyOne.R
#' @seealso
#' \code{\link{friedmanTest}}, \code{\link[stats]{friedman.test}},
#' \code{\link{frdManyOneDemsarTest}}, \code{\link{frdManyOneNemenyiTest}}.
#'
#' @template class-PMCMR
#' @export
frdManyOneExactTest <- function(y, ...) UseMethod("frdManyOneExactTest")

#' @rdname frdManyOneExactTest
#' @method frdManyOneExactTest default
#' @aliases frdManyOneExactTest.default
#' @param p.adjust.method method for adjusting p values
#'    (see \code{\link{p.adjust}}).
#' @importFrom stats p.adjust
#' @importFrom stats p.adjust.methods
#' @importFrom Rmpfr mpfr
#' @import gmp
#' @template two-way-parms
#' @export
frdManyOneExactTest.default <-
    function(y, groups, blocks, p.adjust.method = p.adjust.methods, ...)
{
    ## Check arguments
    p.adjust.method <- match.arg(p.adjust.method)
 #   alternative <- match.arg(alternative)

    ## 2019-10-16
    ## novel external function
    ans <- frdRanks(y, groups, blocks)
    r <- ans$r
    n <- nrow(r)
    k <- ncol(r)
    GRPNAMES <- colnames(r)

    METHOD <- c("Eisinga-Heskes-Pelzer and Grotenhuis",
                " many-to-one test for a two-way",
                 " balanced complete block design")
    Ri <- colSums(r)
    compareRi <- function(i){
        d <- Ri[i] - Ri[1]
        d
    }
    PSTATv <- rep(NA, k-1)
    for (i in 2:k) {PSTATv[i-1] <- compareRi(i)}
    PADJv <- sapply(PSTATv, function(PSTATv) {
        pexactfrsd(d = abs(PSTATv), k = k, n = n, option="pvalue")
        })
    PADJv <- p.adjust(PADJv, method = p.adjust.method, n = (k - 1))
    DIST <- "D"
    LNAME <- GRPNAMES[2:k]
    alternative = "two.sided"

    ## build matrix
    PSTAT <- matrix(data=PSTATv, nrow = (k-1), ncol = 1,
                    dimnames = list(LNAME, GRPNAMES[1]))
    PVAL <- matrix(data=PADJv, nrow = (k-1), ncol = 1,
                   dimnames = list(LNAME, GRPNAMES[1]))
    #MODEL <- data.frame(x = y, g = groups, b = blocks)
    ans <- list(method = METHOD,
                data.name = ans$DNAME,
                p.value = PVAL,
                statistic = PSTAT,
                p.adjust.method = p.adjust.method,
                alternative = alternative,
                dist = DIST,
                model = ans$MODEL)
    class(ans) <- "PMCMR"
    ans
}
