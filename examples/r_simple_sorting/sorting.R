library(rhdf5)

len <- 1000000000

inform <- c(len)
x <- sample(1:len, len, replace = FALSE)

h5write(inform, "infor.h5","data")
h5write()

system("simple -i infor 1 , x 1000000000")
h5write(inform, "infor.h5","data")

start.time <- Sys.time()

for (idx in 1:len) {
  
}

end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken