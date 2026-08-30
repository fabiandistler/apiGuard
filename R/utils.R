# Small internal helpers ------------------------------------------------------

`%||%` <- function(a, b) if (is.null(a)) b else a

na_to_missing <- function(x) if (is.na(x)) "<missing>" else x
