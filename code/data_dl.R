
if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  # This has a specific username and password because I DONT want people to have access to this!
  source("Z:/Projects/ConnectToOracle.R")
} else {
  # For those without a ConnectToOracle file
  library(rstudioapi)
  library(RODBC)
  channel <- odbcConnect(dsn = "AFSC", 
                         uid = rstudioapi::showPrompt(title = "Username", 
                                                      message = "Oracle Username", default = ""), 
                         pwd = rstudioapi::askForPassword("Enter Password"),
                         believeNRows = FALSE)
}


maxyr <- 2007
compareyr <- 2004

locations <- c(
  "GAP_PRODUCTS.CRUISE",
  "GAP_PRODUCTS.HAUL",
  "GAP_PRODUCTS.CPUE"
)

print(Sys.Date())

error_loading <- c()
for (i in 1:length(locations)){
  print(locations[i])
  
  a <- RODBC::sqlQuery(channel = channel, 
                       query = paste0("SELECT *
    FROM ", locations[i], "
    FETCH FIRST 1 ROWS ONLY;"))
  
  end0 <- c()
  if ("SURVEY_DEFINITION_ID" %in% names(a) & !(locations[i] %in% "GAP_PRODUCTS.BIOMASS")) {
    end0 <- c(end0) # , "SURVEY_DEFINITION_ID IN (143, 98)"
  }
  if ("YEAR" %in% names(a) & !(locations[i] %in% 
                               c("GAP_PRODUCTS.SIZECOMP", "GAP_PRODUCTS.AGECOMP", 
                                 "GAP_PRODUCTS.BIOMASS", 
                                 "GAP_PRODUCTS.CRUISE", "GAP_PRODUCTS.CPUE",
                                 "GAP_PRODUCTS.HAUL")) ) {
    end0 <- c(end0, paste0("YEAR IN (",paste0(maxyr:compareyr, collapse = ","), ")"))
  }
  
  # if (locations[i] %in% c("GAP_PRODUCTS.CRUISE")) {
  #   cruises0 <- a
  # }
  # 
  # if (locations[i] %in% c("GAP_PRODUCTS.HAUL")) {
  #   end0 <- c(end0, paste0("YEAR IN (",text_list(x = maxyr:(maxyr-9), sep = ", ", sep_last2 = ", ", sep_last = ", "), ")"))
  # }
  # 
  # if ("YEAR" %in% names(a) & locations[i] %in% c("GAP_PRODUCTS.CPUE")) {
  #   end0 <- c(end0, paste0("YEAR IN (",text_list(x = maxyr:(maxyr-9), sep = ", ", sep_last2 = ", ", sep_last = ", "), ")"))
  # }
  
  end0 <- ifelse(is.null(end0), "", paste0(" WHERE ", paste0(end0, collapse = " AND ")))
  
  start0 <- ifelse(!("START_TIME" %in% names(a)), 
                   "*", 
                   paste0(paste0(names(a)[names(a) != "START_TIME"], sep = ",", collapse = " "),
                          " TO_CHAR(START_TIME,'MM/DD/YYYY HH24:MI:SS') START_TIME "))
  
  a <- RODBC::sqlQuery(channel, paste0("SELECT ", start0, " FROM ", locations[i], end0, "; "))
  
  if (is.null(nrow(a))) { # if (sum(grepl(pattern = "SQLExecDirect ", x = a))>1) {
    error_loading <- c(error_loading, locations[i])
  } else {
    write.csv(x = a, 
              here::here("data",
                         paste0(tolower(gsub(pattern = '.', 
                                             replacement = "_", 
                                             x = locations[i], 
                                             fixed = TRUE)),
                                ".csv")))
  }
  remove(a)
}
error_loading
