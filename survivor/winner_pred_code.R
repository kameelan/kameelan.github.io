#GOALS:
# 1. Visualize distribution of winner prediction picks by season
# 2. Visualize distribution of winner prediction picks of loser vs winner_predictions
# 3. Build log reg model to see if winner ~ reddit prediction picks
# If I have time/energy, are there other variables that can be added to model? 

library(tidyverse)
library(dplyr)
library(readxl)
library(ggplot2)
library(survivoR)
library(shinydashboard)
library(shiny)
library(randomForest)
library(ggcorrplot)
library(caret)
library(gam)
library(caTools)
library(e1071)
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

class(cleaned_data$season)
colors <- season_palettes

#Goal 1: Visualize r/Survivor winner pick predictions by season
#for each season, generate plot showing number of picks for each player

# Define the UI
ui <- fluidPage(
  titlePanel("Number of Picks per Contestant by Season"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "Season",
        label = "Choose a Season:",
        choices = sort(unique(as.character(cleaned_data$season))),
        selected = unique(as.character(cleaned_data$season))[1]
      )
    ),
    
    mainPanel(
      plotOutput(outputId = "picksPlot")
    )
  )
)

# Define the server logic
server <- function(input, output) {
  
  #cleaned_data <- cleaned_data %>% mutate(season = as.character(season))
  
  # Create a reactive expression to filter the data based on selected season
  filtered_data <- reactive({
    cleaned_data %>% 
      filter(season == input$Season) %>%
      mutate(winner = ifelse(result == "Sole Survivor", "Sole Survivor", "Other"),
             pct = Picks / sum(Picks) * 100) #Calculate % of picks for each contestant
  })
  
  # Create the plot
  output$picksPlot <- renderPlot({
    ggplot(filtered_data(), aes(x = reorder(castaway.x, Picks), y = Picks, fill = winner)) +
      geom_bar(stat = "identity") +
      geom_text(aes(
        label = paste0(Picks, " (", round(pct, 1), "%)"),  # Display `n (%)`
        hjust = -0.1  # Adjust horizontal position slightly outside the bars
      ), size = 3) +
      coord_flip() +  # Flips the axes for better readability
      labs(
        title = paste("r/Survivor Preseason Winner Predictions, Season", input$Season),
        x = "Contestant",
        y = "Winner Prediction Votes"
      ) +
      expand_limits(y = max(filtered_data()$Picks) * 1.1) + # Increase limit by 10%
      scale_fill_manual(name = "Legend", values = c("Sole Survivor" = "#f0dd52", "Other" = "#299bd1")) +
      theme_minimal()
  })
}

# Run the application 
shinyApp(ui = ui, server = server)



#DASHBOARD CREATION
library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)

# Sample data, replace with your own data
# cleaned_data <- YOUR_CLEANED_DATA_HERE

ui <- dashboardPage(
  dashboardHeader(title = "Survivor Data Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Number of Picks", tabName = "picks", icon = icon("bar-chart")),
      menuItem("Winner Prediction Density Plot", tabName = "densityplot", icon = icon("chart-area")),
      selectInput(
        inputId = "Season",
        label = "Choose a Season:",
        choices = sort(unique(as.character(cleaned_data$season))),
        selected = unique(as.character(cleaned_data$season))[1]
      )
    )
  ),
  
  dashboardBody(
    tabItems(
      # First tab content
      tabItem(tabName = "picks",
              fluidRow(
                box(
                  title = "Number of Picks per Contestant by Season",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotOutput(outputId = "picksPlot")
                )
              )),
      
      # Second tab content
      tabItem(tabName = "densityplot",
              fluidRow(
                box(
                  title = "Distribution of Preseason Winner Predictions",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotOutput(outputId = "densityWinLose")
                ),
                box(
                  title = "Overall Density of Winner Predictions",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotOutput(outputId = "densityAll")
                )
              ))
    )
  )
)

server <- function(input, output) {
  
  # Reactive data for the first plot
  filtered_data <- reactive({
    cleaned_data %>% 
      filter(season == input$Season) %>%
      mutate(winner = ifelse(result == "Sole Survivor", "Sole Survivor", "Other"))
  })
  
  # Render the picks plot
  output$picksPlot <- renderPlot({
    ggplot(filtered_data(), aes(x = reorder(castaway.x, -Picks), y = Picks, fill = winner)) +
      geom_bar(stat = "identity") +
      coord_flip() +
      labs(
        title = paste("Number of Picks in Season", input$Season),
        x = "Contestant",
        y = "Number of Picks"
      ) +
      scale_fill_manual(values = c("Sole Survivor" = "#f0dd52", "Other" = "#299bd1")) +
      theme_minimal() +
      theme(legend.position = "bottom")
  })
  
  #Render the density plot with winners vs. non-winners
  output$densityWinLose <- renderPlot({
    cleaned_data %>%
      mutate(winner = ifelse(result == "Sole Survivor", "Sole Survivor", "Other")) %>%
      ggplot(aes(x = Picks, fill = winner)) +
      geom_density(alpha = 0.5) +
      scale_fill_manual(
        name = "Legend",
        values = c("Other" = "#299bd1", "Sole Survivor" = "#f0dd52"),
        labels = c("Losers", "Sole Survivor")
      ) +
      labs(
        title = "Density of Preseason Winner Predictions, Seasons 31 - 43",
        x = "Winner Prediction Votes",
        y = "Density"
      ) +
      theme_minimal() +
      theme(legend.position = "bottom")
  })
  
  #Render the overall density plot with the median line
  output$densityAll <- renderPlot({
    cleaned_data %>%
      ggplot(aes(x = Picks)) +
      geom_density(fill = "#299bd1", alpha = 0.5) +
      geom_vline(aes(xintercept = median(Picks)),
                 linetype = "dashed",
                 size = 1) +
      labs(
        title = "Overall Density of Preseason Winner Predictions, Seasons 31 - 43",
        x = "Winner Prediction Votes",
        y = "Density"
      ) +
      theme_minimal()
  })
}

shinyApp(ui = ui, server = server)

deployApp(appName = "survivor_winner_prediction", appDir = "C:\\R\\portfolio\\survivor")

# #Make dataset for machine learning model
# data_model <- cleaned_data %>%
#   select(c(winner, Picks, age, state, gender, cleaned_race_eth, occupation, personality_type))
# 
# #write.csv(data_model, "data_model.csv")
# 
# #Create dummy variables for categorical predictors
# dummy <- dummyVars("~.", data = data_model)
# 
# set.seed(123)
# split = sample.split(data_model$winner, SplitRatio = 0.75)
# training_set = subset(data_model, split == TRUE) 
# test_set = subset(data_model, split == FALSE)
# 
# 
# 
# classifier = svm(formula = winner ~ ., 
#                  data = training_set, 
#                  type = 'C-classification', 
#                  kernel = 'linear')
# print(classifier)
# 
# test_set$state <- factor(test_set$state, levels = levels(training_set$state))
# test_set$gender <- factor(test_set$gender, levels = levels(training_set$gender))
# test_set$cleaned_race_eth <- factor(test_set$cleaned_race_eth, levels = levels(training_set$cleaned_race_eth))
# test_set$occupation <- factor(test_set$occupation, levels = levels(training_set$occupation))
# test_set$personality_type <- factor(test_set$personality_type, levels = levels(training_set$personality_type))
# 
# #Build random forest classifier
# cleaned_data.rf <- randomForest(
#   winner ~ .,
#   data = data_model,
#   importance = TRUE,
#   proximity = TRUE
# )
# 
# # Predicting the Test set results 
# y_pred = predict(classifier, newdata = test_set[-1]) 
# 
# 
# #Build random forest classifier
# cleaned_data.rf <- randomForest(
#   winner ~ .,
#   data = data_model,
#   importance = TRUE,
#   proximity = TRUE
# )
# 
# logReg <- glm(winner ~ ., data = data_model, family = "binomial")
# print(logReg)
# 
# print(cleaned_data.rf)
# plot(cleaned_data.rf)
# 
# 
# 
# 
# 
# 
# 
# 
# 
