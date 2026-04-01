obj_names <- ls()

models <- Filter(
  function(obj_name) any(class(get(obj_name, envir = globalenv())) %in% "fixest"),
  obj_names
)
print(models)