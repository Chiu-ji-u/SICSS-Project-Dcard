install.packages("tidyverse")
install.packages("quanteda")
install.packages("quanteda.textplots")
install.packages("quanteda.textstats")
install.packages("sysfonts")
install.packages("showtext")
install.packages("jiebaR")

library(tidyverse)
library(quanteda)
library(quanteda.textplots)
library(quanteda.textstats)

####################################################################################
## Chinese Text Analysis                                                          ##
####################################################################################

# Doing text analysis can be tricky, but doing Chinese text analysis can be even trickier
# There are a few extra things we need to consider

######################### Showing Chinese Figures #########################
library(readr)
exam_content <- read.csv("C:/Users/user/Desktop/exam-content.csv")
corpus_ios <- corpus(exam_content$excerpt, text_field = "message")

# Creating DFM
tokens_ios <- tokens(corpus_ios,
                     remove_punct = TRUE,
                     remove_numbers = TRUE,
                     remove_url = TRUE,
                     remove_symbols = TRUE,
                     verbose = TRUE)
dfm_ios <- dfm(tokens_ios)


features <- topfeatures(dfm_ios, 50)  # Putting the top 100 words into a new object
data.frame(list(term = names(features), frequency = unname(features))) %>% # Create a data.frame for ggplot
  ggplot(aes(x = reorder(term,-frequency), y = frequency)) + # Plotting with ggplot2
  geom_point() +
  coord_flip() +
  theme_bw() +
  labs(x = "Term", y = "Frequency") +
  theme(axis.text.x=element_text(angle=90, hjust=1))

customstopwords <- c("與", "年", "月", "日")

stopwords <- fread("C:/Users/user/Desktop/stop-words.csv", encoding = "UTF-8")

dfm_ios <- dfm_remove(dfm_ios, c(stopwords, stopwords('en'), customstopwords), min_nchar = 2)

#stopwords("zh", source = "misc")
# Inspecting the results again
topfeatures(dfm_ios, 50)

textplot_wordcloud(dfm_ios)

# You would notice Chinese characters are not displayed correctly in the previous graph.
# This is because the default font in R doesn't support Chinese
# To fix it, we simply need to change the font
# Changing font in R can be tricky, but luckily these packages make it easier
library(sysfonts)
font_add_google("Noto Sans TC", "Noto Sans TC")
library(showtext)
showtext_auto()

textplot_wordcloud(dfm_ios)
