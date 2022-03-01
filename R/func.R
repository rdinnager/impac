# Takes a function or an expression (wrapped in {}), and makes it into a function
# which can take all the metadata available from impac.
make_impac_func <- function(x, name) {

  y <- rlang::enquo(x)
  express <- rlang::quo_get_expr(y)

  if(rlang::is_call(express, name = "function")) {
    x <- rlang::eval_tidy(y)
  } else {
    x <- express
  }

  fun_vars <- rlang::pairlist2()

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

  rlang::env_bind(impac_exec_env,
                  fun_vars = fun_vars,
                  body_ = body_,
                  name = name)

  rlang::with_env(impac_exec_env,
                  rlang::env_bind_lazy(impac_exec_env, !!!setNames(list(rlang::new_function(fun_vars, body_)), name),
                                       .eval_env = impac_exec_env)
  )

}


## convenience functions

#' Return the space left in a packed image (as squared pixels)
#'
#' This function is a convenience function that can be called inside
#' a function-like object passed to `impac()`, to retrieve some information
#' about the context of the current `impac()` run.
#'
#' @return Squared pixels area of unoccupied space on current packed image
#' @export
#'
#' @examples
space_left <- function() {
  warning("space_left() can only be usefully called inside a function-like object passed to impac. Calling it here does nothing.")
}

.space_left <- function() {
  area <- length(.mask)
  (area - sum(.mask)) / area
}
