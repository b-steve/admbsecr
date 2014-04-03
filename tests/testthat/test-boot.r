context("Testing bootstrapping")

test_that("simple model bootstrapping", {
    set.seed(8871)
    boot.fit <- boot.admbsecr(simple.hn.fit, N = 5, prog = FALSE)
    means.test <- c(7.6667469, 1.7383131, 2165.68, 5.705, 0.0616552)
    boot.means <- apply(boot.fit$boot$boots, 2, mean)
    relative.error <- max(abs((boot.means - means.test)/means.test))
    expect_that(relative.error < 1e-4, is_true())
    expect_that(coef(boot.fit), is_identical_to(coef(simple.hn.fit)))
    ses.test <- c(387.9411, 0.4969067, 0.008813962, 0.1886847, 0.08700770)
    boot.ses <- stdEr(boot.fit, "all")
    relative.error <- max(abs((boot.ses - ses.test)/ses.test))
    expect_that(relative.error < 1e-4, is_true())
})
