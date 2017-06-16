sl_begin <- function() {
  dyn.load('/usr/lib/libsimplelang.so')
}

sl_push <- function(NAME, X) {
  X <- as.numeric(X)
  .Call('sl_create', NAME, X)
}

sl_interpreter <- function(NAME) {
  .Call('sl_lc', NAME)
}

sl_copyHostToDevice <- function(NAME) {
  .Call('cpyMemHostToDevice')
}

sl_copyDeviceToHost <- function(NAME) {
  .Call('cpyMemDeviceToHost')
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

sl_host <- function(maxProc) {
  .Call('sl_host', maxProc);
}

sl_end <- function() {
  .Call('sl_end')
  dyn.unload('/usr/lib/libsimplelang.so')
}


############### rs_multi ###############
sl_begin()

#L <- 6300
L <- 500
TL <- L*L

A <- 1:TL
A[1:TL] <- 1

B <- 1:TL
B[1:TL] <- 1

C <- 1:TL
inp <- c(L)

sl_push('A', A)
sl_push('B', B)
sl_push('C', C)
sl_push('inp', inp)

sl_interpreter('multi.txt')

sl_device(0, TL)

C <- sl_get('C')

C[1]
print('end')
sl_end()
