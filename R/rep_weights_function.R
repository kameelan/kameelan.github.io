#' My Function
#'
#' This function generates replicate weights for complex survey data.
#'
#' @param data Dataframe containing survey data.
#' @param method Method used to generate replicate weights: jackknife, bootstrap, and brr.
#' @param num_reps Number of replications used to generate replicate weights.
#' @param strata_var Variable used for stratification.
#'
#' @return The list of generated replicate weights.
#' @examples
#' data <- data.frame(
#'   id = 1:10,
#'   weight = runif(10, 1, 5),
#'   gender = rep(c("Male", "Female"), 5),
#'   age = sample(20:50, 10, replace = TRUE),
#'   cleaned_race_eth = sample(c("White", "Black", "Asian", "Other"), 10, replace = TRUE)
#' )
#' generate_rep_weights(data, method = "jackknife")
#' generate_rep_weights(data, method = "bootstrap", num_reps = 50)
#' generate_rep_weights(data, method = "brr", strata_var = "cleaned_race_eth")
#'
#' @export

generate_rep_weights <- function(data, method = "jackknife", num_reps = 50, strata_var = NULL) {
  replicate_weights <- list()

  if (method == "jackknife") {
    # Generate jackknife weights
    replicate_weights <- lapply(1:nrow(data), function(i) {
      replicate_weight <- rep(1, nrow(data))
      replicate_weight[i] <- 0
      replicate_weight
    })
  } else if (method == "bootstrap") {
    # Generate bootstrap weights
    replicate_weights <- replicate(num_reps, {
      sample_indices <- sample(1:nrow(data), replace = TRUE)
      table(factor(sample_indices, levels = 1:nrow(data)))
    }, simplify = FALSE)
  } else if (method == "brr" && !is.null(strata_var)) {
    # Generate BRR weights
    # Ensure the strata_var exists in the data
    if (strata_var %in% colnames(data)) {
      strata <- data[[strata_var]]
      unique_strata <- unique(strata)
      num_strata <- length(unique_strata)
      replicate_weights <- replicate(num_reps, {
        replicate_weight <- rep(1, nrow(data))
        strata_sample <- sample(unique_strata, num_strata / 2)
        replicate_weight[strata %in% strata_sample] <- 2
        replicate_weight[!(strata %in% strata_sample)] <- 0
        replicate_weight
      }, simplify = FALSE)
    } else {
      stop("Stratification variable not found in data.")
    }
  } else {
    stop("Invalid method or missing strata_var for BRR.")
  }

  return(replicate_weights)
}
