BEGIN <- function() {
  dyn.load('/usr/lib/libsl2R.so')
}

CREATE <- function(NAME, X) {
  X <- as.numeric(X)
  .Call('CREATE', NAME, X)
}

UPDATE <- function(NAME, X) {
  X <- as.numeric(X)
  .Call('UPDATE', NAME, X)
}

GET <- function(NAME) {
  X <- .Call('GET', NAME)
  return (X)
}

RUN <- function(CMD) {
  result <- .Call('RUN', CMD)
}

END <- function() {
  dyn.unload('/usr/lib/libsl2R.so')
}