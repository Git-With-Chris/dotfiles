# ~/.Rprofile - sourced by R at startup.
#
# Note on where this belongs: R looks for ~/.Rprofile using R_USER, which is not
# always $HOME. On Linux it normally is. On Windows with redirected Documents it
# is not - check with  Rscript -e 'cat(path.expand("~"))'  if it seems ignored.
# A project-level .Rprofile (renv creates one) overrides this file entirely.

if (interactive()) {
  # Blank line between a command's output and the next prompt.
  #
  # Doing this as options(prompt = "\n> ") does draw the blank line, but
  # RStudio's console then leaves the input cursor sitting on that blank line
  # instead of after the ">". So emit the newline *after* each top-level
  # command instead and leave the prompt string itself untouched.
  #
  # Returning TRUE keeps the callback registered. To turn it off for a session:
  #   removeTaskCallback("blank_line_before_prompt")
  invisible(addTaskCallback(
    function(expr, value, ok, visible) {
      cat("\n")
      TRUE
    },
    name = "blank_line_before_prompt"
  ))
}
