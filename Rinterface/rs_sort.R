sl_begin <- function() {
  dyn.load('/usr/lib/libsl2R.so')
}

sl_create <- function(NAME, X) {
  X <- as.numeric(X)
  .Call('sl_create', NAME, X)
}

sl_lc <- function(NAME) {
  .Call('sl_lc', NAME)
}

sl_update <- function(NAME, X) {
  X <- as.numeric(X)
  .Call('sl_update', NAME, X)
}

sl_get <- function(NAME) {
  X <- .Call('sl_get', NAME)
  return (X)
}

sl_run <- function(CMD) {
  result <- .Call('sl_run', CMD)
}

sl_device <- function(id, maxProc) {
  .Call('sl_device', id, maxProc);
}

sl_end <- function() {
  dyn.unload('/usr/lib/libsl2R.so')
}

####### YOUR CODE ###############################


