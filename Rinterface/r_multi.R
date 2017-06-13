L <- 500
TL <- L*L

A <- 1:TL

A[1:TL] <- 1

mA <- matrix(A, nrow = L)
mB <- matrix(A, nrow = L)
mC <- matrix(A, nrow = L)

mC <- mA %*% mB
