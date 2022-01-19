# Takes a function or an expression (wrapped in {}), and makes it into a function
# which can take all the metadata available from impac.
make_impac_func <- function(x) {

  y <- rlang::enquo(x)
  express <- rlang::quo_get_expr(y)

  if(rlang::is_call(express, name = "function")) {
    x <- rlang::eval_tidy(y)
  } else {
    x <- express
  }

  fun_vars <- rlang::pairlist2(.x = ,
                               .y = ,
                               .i = ,
                               .s = ,
                               .meta = ,
                               .img = ,
                               .np = ,
                               .c = ,
                               ... = )

  if(rlang::is_expression(x)) {
    body_ <- x
  } else {
    if(rlang::is_function(x)) {
      body_ <- rlang::fn_body(x)
      extra_args <- rlang::fn_fmls(x)
      fun_vars <- c(extra_args, fun_vars)
    } else {
      stop("`x` must be a function or an R expression")
    }
  }

  new_func <- rlang::new_function(fun_vars, body_)

  new_func

}
