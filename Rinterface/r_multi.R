L <- 5000
TL <- L*L

A <- 1:TL

A[1:TL] <- 1

length(A)

m_A <- matrix(A, nrow = L)
m_B <- matrix(A, nrow = L)


start.time <- Sys.time()

C <- m_A %*% m_B

end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken