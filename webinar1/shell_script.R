#' @name shell_script.R
#' @title Shell Script for Invoking MOVES
#' @author Tim Fraser, PhD
#' 
# Run the following code in the shell!
shell(
# Insert command line code, as 1 line, punctuated by &&
  cmd = 'cd "C:\\Users\\Public\\EPA\\MOVES\\MOVES3.1"  && setenv && ant && ant run -Drunspec="C:\\Users\\tmf77\\OneDrive - Cornell University\\Documents\\rstudio\\moves_tutorials\\webinar1\\rs_tompkins_2023.xml" ', 
  translate = TRUE, intern = FALSE, mustWork = TRUE
)
