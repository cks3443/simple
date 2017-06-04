library(rhdf5)

len <- 1000000000

inform <- c(len, 0)
x <- sample(1:len, len, replace = FALSE)

cmd <- paste("simple -i infor 2 , x ", len)
#system(cmd)

#h5write(inform, "infor.h5","data")
#h5write(x, "x.h5", "data")

############ TIMESTAMP ############

start.time <- Sys.time()

system(cmd)
#for (idx in 1:len) {
#}

end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken