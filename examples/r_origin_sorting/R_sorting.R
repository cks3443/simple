x <- 10000000:1

start.time <- Sys.time()

sort(x, decreasing = FALSE)

end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken