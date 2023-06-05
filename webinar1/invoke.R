#' @name invoke()
#' @title Invoke MOVES from R
#' @author Timothy Fraser, PhD
#' @note June 5, 2023
#'
#' @description
#' A function for invoking MOVES from the Windows command line via R!
#' Uses rstudioapi package to run MOVES as a background job,
#' so you can keep on coding while MOVES works.
#'
#' @param rs Path to your runspec. Must be FULL File path, with backlashes, eg. "/".
#' @param moves Path to your MOVES folder. Usually doesn't change. Must use backslashes, eg. "/"
#' @param shell  Path to write your `invoke` script to. Default is a temporary file.
#'

invoke = function(rs, moves =  "C:/Users/Public/EPA/MOVES/MOVES3.1", shell = tempfile(fileext = ".R") ){


  # R doesn't play nice with forward slashes,
  # so we'll need to use this bizzare chunk to help R parse them correctly.
  rs2 = gsub(x = rs, pattern = "/", "\\\\\\\\")
  moves2 = gsub(x = moves, pattern = "/", "\\\\\\\\")

  # Build the script
  script = paste(
    "#' @name shell_script.R",
    "#' @title Shell Script for Invoking MOVES",
    "#' @author Tim Fraser, PhD",
    "#' ",
    "# Run the following code in the shell!",
    "shell(",
    "# Insert command line code, as 1 line, punctuated by &&",
    paste0(
      "  cmd = 'cd ",
      # Set directory to MOVES
      paste0('"', moves2,  '" '),
      ' && ',
      # Set environment with MOVES specifications
      'setenv',
      ' && ',
      # Load ant
      'ant',
      ' && ',
      # Run your runspec
      paste0('ant run -Drunspec="', rs2, '"'),
      " ",
      "', "),
    "  translate = TRUE, intern = FALSE, mustWork = TRUE",
    ")",
    sep = "\n"
  )
  # Write the script to file
  cat(script, file = shell, sep = "\n")

  # Print the script to the console
  cat(script, sep = "\n")
}
