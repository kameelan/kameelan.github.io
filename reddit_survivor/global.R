library(tidyverse)
library(dplyr)
library(readxl)
library(ggplot2)
library(survivoR)
library(shinydashboard)
library(shiny)

#Read in dataset made from r/Survivor Winner Prediction spreadsheets and threads. 
#NOTE: Season 44 was excluded from this analysis, bc r/Survivor did not collect winner predictions for this season. 
winner_predictions <- read_excel("survivor_winner_predictions.xlsx") %>%
  subset(Season < 44) %>%
  rename(full_name = Player) %>%
  mutate(season = as.character(Season),
         full_name = ifelse(full_name == "Dean Kowalksi", "Dean Kowalski", full_name))


#Read in survivoR dataset from R, only selecting seasons 31-46
castaways_31_43 <- castaways %>%
  filter(version_season %in% c("US31", "US32", "US33", "US34", "US35", 
                               "US36", "US37", "US38", "US39", "US40", 
                               "US41", "US42", "US43")) %>%
  select(season, full_name, castaway_id, castaway, age, city, state, result, jury_status) %>%
  mutate(full_name = ifelse(full_name == "James Thomas Jr.", "J.T. Thomas", full_name),
         full_name = ifelse(full_name == "Elie Scot", "Elie Scott", full_name)) %>%
  filter(!(full_name == "Chris Underwood" & result == "3rd voted out")) #Drop observation for Chris Underwood voted out 3rd

# Find rows in `winner_predictions` that are not in `castaways_31_43`
# mismatched_in_predictions <- anti_join(winner_predictions, castaways_31_43, by = "full_name")
# 
# # Find rows in `castaways_31_43` that are not in `winner_predictions`
# mismatched_in_castaways <- anti_join(castaways_31_43, winner_predictions, by = "full_name")


#Merge winner_predictions and castaways_31_44 dataframes
prediction_castaways <- merge(castaways_31_43, winner_predictions, by.x = c('full_name', 'season'), by.y = c('full_name', 'season'))
summary(prediction_castaways)

#Merge w/ castaway details
prediction_castaway_details <- left_join(prediction_castaways, castaway_details, by = 'castaway_id')

#Recode race variable
cleaned_data <- prediction_castaway_details %>%
  mutate(cleaned_race_eth = case_when(
    is.na(race) & poc == "White" ~ "White",
    race == "Black" & ethnicity == "Hispanic or Latino" ~ "Black, Hispanic or Latino",
    race == "White" & ethnicity == "Hispanic or Latino" ~ "White, Hispanic or Latino",
    is.na(race) & ethnicity == "Hispanic or Latino" ~ "Unspecified, Hispanic or Latino",
    race == "White" ~ "White",
    race == "Black" ~ "Black",
    race == "Asian" ~ "Asian",
    race == "Brazilian" ~ "Other",
    race == "Asian, Black" ~ "Multiracial"),
    winner = as.factor(case_when(
      result == "Sole Survivor" ~ 1,
      TRUE ~ 0))) %>%
  mutate(season = as.character(season))