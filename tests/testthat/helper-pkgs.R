# Write a minimal fake package to a temp dir for snapshot/compare tests.
make_pkg <- function(code, exports, version = "1.0.0") {
  dir <- tempfile("pkg-")
  dir.create(file.path(dir, "R"), recursive = TRUE)
  writeLines(c("Package: fakepkg", paste("Version:", version)),
             file.path(dir, "DESCRIPTION"))
  writeLines(code, file.path(dir, "R", "code.R"))
  writeLines(sprintf("export(%s)", exports), file.path(dir, "NAMESPACE"))
  dir
}
