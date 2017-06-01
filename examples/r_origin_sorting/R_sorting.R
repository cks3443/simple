x <- sample(1:1000000000, 1000000000, replace = FALSE)

start.time <- Sys.time()

sort(x, decreasing = FALSE)

end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken