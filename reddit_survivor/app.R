#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/


#DASHBOARD CREATION
library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(rsconnect)

# Sample data, replace with your own data
# cleaned_data <- YOUR_CLEANED_DATA_HERE

ui <- dashboardPage(
  dashboardHeader(title = "Outwit. Outplay. OutData!"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Winner Predictions by Castaway", tabName = "picks", icon = icon("bar-chart")),
      menuItem("Winner Predictions Distribution", tabName = "densityplot", icon = icon("chart-area")),
      uiOutput(outputId = "sidebarChoices")
    )
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML('
      .skin-blue .main-header .logo {
        width: 300px;
      }
      .skin-blue .main-header .navbar {
        margin-left: 300px;
      }
      '))), 
    tabItems(
      # First tab content
      tabItem(tabName = "picks",
              fluidRow(
                box(
                  title = "Reddit Winner Prediction Votes",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotOutput(outputId = "picksPlot")
                ),
              )),
      
      # Second tab content
      tabItem(tabName = "densityplot",
              fluidRow(
                box(
                  title = "Distribution of Reddit Winner Predictions, Seasons 31 - 43",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotOutput(outputId = "densityWinLose")
                ),
                box(
                  title = "Total Reddit winner prediction votes, Seasons 31 - 43",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  tableOutput(outputId = "mannWhitneyData")
                ),
                box(
                  title = "Mann-Whitney Test Results",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  tableOutput(outputId = "mannWhitneyTable")
                ),
                # box(
                #   title = "Overall Density of Reddit Winner Predictions",
                #   status = "primary",
                #   solidHeader = TRUE,
                #   width = 12,
                #   plotOutput(outputId = "densityAll")
                # )
              ))
    )
  )
)

server <- function(input, output) {
  
  library(tidyverse)
  library(dplyr)
  library(purrr)
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
        result == "Sole Survivor" ~ "Sole Survivor",
        TRUE ~ "Loser")),
      season = as.character(season))
    
  
  
  #Reactive data for the first plot
  filtered_data <- reactive({
    cleaned_data %>% 
      filter(season == input$Season) %>%
      mutate(winner = ifelse(result == "Sole Survivor", "Sole Survivor", "Other"))
  })
  
  #Render the plot for number of votes each contestant received 
  output$picksPlot <- renderPlot({
    ggplot(filtered_data(), aes(x = reorder(castaway.x, -Picks), y = Picks, fill = winner)) +
      geom_bar(stat = "identity") +
      coord_flip() +
      labs(
        title = paste("Reddit votes for predicted winner, Season", input$Season),
        x = "Castaway",
        y = "Number of Votes"
      ) +
      scale_fill_manual(name = "Legend",
                        values = c("Sole Survivor" = "#f0dd52", "Other" = "#299bd1"),
                        labels = c("Losers", "Sole Survivor")) +
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
        title = "Density of Reddit votes for winners and losers, Seasons 31 - 43",
        x = "Winner Prediction Votes",
        y = "Density"
      ) +
      theme_minimal() +
      theme(legend.position = "bottom")
  })
  
    
  #Render the overall density plot with the median line
  # output$densityAll <- renderPlot({
  #   cleaned_data %>%
  #     ggplot(aes(x = Picks)) +
  #     geom_density(fill = "#299bd1", alpha = 0.5) +
  #     geom_vline(aes(xintercept = median(Picks)),
  #                linetype = "dashed",
  #                size = 1) +
  #     labs(
  #       title = "Density of all preseason winner predictions, Seasons 31 - 43",
  #       x = "Winner Prediction Votes",
  #       y = "Density"
  #     ) +
  #     theme_minimal()
  # })
  
  #Add spread of votes for castaways across seasons 31-43, grouped by 'winner,' to dashboard
  output$mannWhitneyData <- renderTable({
    cleaned_data %>%
      group_by(winner) %>%
      summarise("Total Number of Votes" = list(sum(Picks)),
                Median = list(median(Picks)),
                IQR = list(IQR(Picks))
                )
  })
  
  #Add Mann Whitney results to server function
  output$mannWhitneyTable <- renderTable({
    #Format the Mann-Whitney test
    cleaned_data %>%
      summarise(mann_whitney = list(wilcox.test(Picks ~ winner, data = .))) %>%
      mutate(
        Statistic = map_dbl(mann_whitney, "statistic"),
        P_Value = map_dbl(mann_whitney, "p.value"),
        P_Value = ifelse(P_Value < 0.05, "<0.05", round(P_Value, 3))
      ) %>%
      select(Statistic, P_Value)})
    
  
  
output$sidebarChoices <- renderUI({
    selectInput(
      inputId = "Season",
      label = "Choose a Season:",
      choices = sort(unique(as.character(cleaned_data$season))),
      selected = unique(as.character(cleaned_data$season))[1]
    )
  })
}

shinyApp(ui = ui, server = server)

deployApp(appName = "survivor_winner_prediction", appDir = "C:\\R\\portfolio\\survivor\\reddit_survivor")
 
