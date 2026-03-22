strip_model <- function(mod) {
  # Safe minimal stripping for glm / glm.nb prediction + SEs
  # Keep qr, terms, contrasts, xlevels for predict(se.fit=TRUE)
  mod$data              <- NULL
  mod$residuals         <- NULL
  mod$fitted.values     <- NULL
  mod$effects           <- NULL
  mod$linear.predictors <- NULL
  mod$deviance.resids   <- NULL
  mod$prior.weights     <- NULL
  mod$weights           <- NULL
  mod$call              <- NULL           # safe to drop
  mod$model             <- NULL           # optional, usually small
  
  # KEEP these for prediction:
  # mod$qr                <- NULL        # keep
  # mod$terms             <- NULL        # DO NOT DROP
  # mod$contrasts         <- NULL        # keep if factors present
  # mod$xlevels           <- NULL        # keep if factors
  
  # Optional: drop terms if you are 100% sure no factors in model
  # mod$terms <- NULL
  
  mod
}