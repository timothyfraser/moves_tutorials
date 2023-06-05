#' @name 02_build_script.R
#' @title Webinar 1 Code for Building Scripts to Invoke MOVES (June 5, 2023)
#' @author Timothy Fraser, PhD


# If you have a LOT of MOVES runs to process,
# it can get pretty tedious to use a point-and-click software.
# So how could we iterate this?

# Let's load these packages
library(rstudioapi) # For invoking background jobs

# Let's learn how to invoke MOVES from within the R coding environment.

# We'll need to...

# 0. Get our file paths straight.
# 1. Write a shell() R script to invoke MOVES
# 2. Write an R function to write the shell() R script
# 3. Run a Background Job to Run the shell() R script


# Load our invoke function
source("webinar1/invoke.R")

rs = "C:/Users/tmf77/OneDrive - Cornell University/Documents/rstudio/moves_tutorials/webinar1/rs_tompkins_2023.xml"
moves = "C:/Users/Public/EPA/MOVES/MOVES3.1"

invoke(rs = rs, moves = moves, shell = "webinar1/shell_script.R")

# Now start a background job with that temporary path
rstudioapi::jobRunScript(
  # Run this script...
  path = "webinar1/shell_script.R",
  # Name the job...
  name = "myjob",
  # Use project working directory...
  workingDir = getwd())
