---
title: "README"
author: "Kameela P. Noah"
date: '2024-10-23'
output: html_document
editor_options: 
  markdown: 
    wrap: 72
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# Outwit. Outplay. Outdata.

## Visualizing r/survivor winner predictions

### Project Overview

Survivor is a competition reality TV show run since 1997. Contestants,
or "Castaways," are marooned on remote islands around the world.
Castaways compete in various challenges for rewards and immunity, and
fight for the title of "Sole Survivor" and \$1 million. Contestants are
eliminated through votes by fellow castaways each week.

Survivor has a wide-reaching, diverse fanbase. Fans love to discuss
player strategies, unique personalities, weekly challenges, and guess
winners. The vibrant Reddit community, r/survivor, is very active.

r/survivor Redditors love data! Before each season airs, r/survivor
members participate in a survey to predict the season's Sole Survivor.
These predictions are based on pre-impressions. Voters only have access
to the castaways' names, ages, occupations, residence, and gender. After
each episode premieres, moderators reveal the number of votes the
eliminated contestant received.

I love Survivor, and I'm a data nerd! I was curious to see if the
distribution of winner prediction votes for winners and losers differed.
Did winners have a higher number of votes than losers? *Could Reddit
predict Sole Survivors?*

### Methods

I gathered winner prediction survey results from the r/survivor *Winner
Pick Statistics* threads. These results are available under the *season
archive* bookmark. *Winner Pick Statistics* data was available for
seasons 31 - 47, with the exception of 44.

Each season had its own discussion thread (some more complete than
others). For some seasons, winner prediction survey results for each
castaway were neatly summarized in Google sheets. For others, data were
manually recorded from each episode's *Winner Pick Statistics* thread. I
entered all these winner predictions in a spreadsheet,
survivor_winner_predictions.xlsx.

I merged this data with data from the SurvivoR dataset. This dataset was
created by [dohem](https://github.com/doehm) and is available for
download via [GitHub](https://github.com/doehm/survivoR)! It included
information about contestant demographics, winner status, challenge
results, and more. Data for seasons 1 - 44 were available.

After merging the two datasets, data for 13 seasons were available. I
analyzed *Winner Pick Statistics* for seasons 31 (my favorite) through
43. I examined the distribution of winner prediction votes for each
castaway, per season. The distribution of votes across all available
seasons was also generated.

I performed a Chi-square analysis to determine if winners had a higher
amount of votes than losers.

I decided to build a R Shiny dashboard to share my findings with the
r/survivor community. THE DASHBAORD CONTAINS SPOILERS!

### Results

My analysis revealed:

-   

### Considerations

The availability of data for this analysis was limited; I evaluated data
from 13 seasons out of 47. It is possible these 13 seasons are not
representative of the entire Survivor franchise. Additionally, I chose
to examine U.S. Survivor seasons only.

Due to the limited sample size, there were only 13 winners. The small
amount of positive cases could have led to bias. Due to this small
sample size of winners, I was reluctant to perform statistical modelling
that may have been inaccurate. Resulting models would have likely
struggled to predict winners and have poor sensitivity.

### Summary
