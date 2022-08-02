install.packages("BTM")
install.packages("textplot")
install.packages("ggraph")
install.packages("concaveman")
install.packages("udpipe")
library(jiebaR)
library(tidyverse)
library(data.table)
library(quanteda)
library(quanteda.textplots)
library(quanteda.textstats)
library(BTM)
library(textplot)
library(ggraph)
library(concaveman)
library(udpipe)
library(lubridate)

# change font in R
library(sysfonts)
font_add_google("Noto Sans TC", "Noto Sans TC")
library(showtext)
showtext_auto()

# set working directory
setwd("C:/Users/user/Desktop/project")

fresh_post_latest <- fread("fresh-post-latest.csv", encoding = "UTF-8") %>%
  mutate(title = str_replace_all(title, "\\.", ""),
         Date = as.Date(createdAt))
  #filter(str_detect(topics, "面試"))

#https://bbs.pinggu.org/forum.php?mod=viewthread&action=printable&tid=3774967

# create posts for the comparison between 2021 and 2022
int1 <- interval(ymd("2021-02-01"), ymd("2021-08-01"))
int2 <- interval(ymd("2022-02-01"), ymd("2022-08-01"))

fresh_post_latest_yr <- fresh_post_latest %>% 
  filter(Date %within% int1 | Date %within% int2) %>%
  mutate(yr = ifelse(Date %within% int1, 2021, 2022))

#create posts for the comparison between different admission channels 
fresh_post_latest_adm <- fresh_post_latest %>%
  mutate(adm_channel = case_when(str_detect(topics, "個申|申請") ~ "個申",
                                 str_detect(topics, "指考|分科") ~ "分科",
                                 str_detect(topics, "繁星") ~ "繁星"))

# create corpus
corpus <- corpus(fresh_post_latest_yr, text_field = "title")
#corpus_subset(corpus, str_detect(topics, ""))
#sum_corpus = as.data.frame(summary(corpus))
docvars(corpus)
tokeniser <- worker()

# custom dictionary
mydictionary = fread("dictionary.csv", encoding = "UTF-8")
new_user_word(tokeniser, mydictionary$customtoken) 

# Using jieba with quanteda 
raw_texts <- as.character(corpus) # getting text from the corpus
tokenised_texts <- purrr::map(raw_texts, segment, tokeniser) 

# Chinese stopwords
ch_stop <- stopwords("zh", source = "misc")

# Creating DFM
tokens <- tokens(tokenised_texts,
  remove_punct = TRUE,
  remove_numbers = TRUE,
  remove_url = TRUE,
  remove_symbols = TRUE,
  verbose = TRUE,
  pattern = ch_stop
)
dfms <- tokens %>% dfm()

# custom stop words
stw <- fread("stop-words.csv", encoding = "UTF-8")
customstopwords <- stw$customstopwords
dfms <- dfm_remove(dfms, c(stopwords('chinese', source = "misc"), 
                           stopwords('english'),
                           customstopwords), min_nchar = 2)

# set document-level variables for comparison between 2021 and 2022
docvars(dfms, "yr") <- fresh_post_latest_yr$yr
yr_comparison <- textstat_keyness(dfms, target = docvars(dfms, "yr") == 2022)

# plot 
textplot_keyness(yr_comparison, labelsize = 8, margin = 0.01, n = 10, show_legend = F)

# Calculate relative frequency by admission channel
dfm_weight <- dfms %>% dfm_remove(c("分科", "指考", "測驗", "個申", "申請", "繁星"))   

docvars(dfm_weight, "adm_channel") <- fresh_post_latest_adm$adm_channel

dfm_weight <- dfm_weight %>% dfm_weight(scheme = "prop")

freq_weight <- textstat_frequency(dfm_weight, n = 15, 
                                  groups = dfm_weight$adm_channel)

ggplot(data = freq_weight, aes(x = nrow(freq_weight):1, y = frequency)) +
  geom_point() +
  facet_wrap(~ group, scales = "free") +
  coord_flip() +
  scale_x_continuous(breaks = nrow(freq_weight):1,
                     labels = freq_weight$feature) +
  labs(x = NULL, y = "Relative frequency")

# Find the most common 20 words in the posts
features <- topfeatures(dfms, 20) # Putting the top 20 words into a new object
data.frame(list(term = names(features), frequency = unname(features))) %>% # Create a data.frame for ggplot
  ggplot(aes(
    x = reorder(term, -frequency),
    y = frequency,
    fill = term,
  )) + # Plotting with ggplot2
  geom_bar(stat = "identity") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 16), 
        axis.text.y = element_text(hjust = 1, size = 16),
        axis.title.y = element_text(size = 16)) +
  theme(plot.title = element_text(hjust = 0.5, size = 18)) +
  ylab("Frequency") +
  xlab("") +
  ggtitle("Most Frequent Texts in title 20210201 ~ 20210801")

# plot the change of number of posts following the timeline --------------------
fresh_post_latest %>%
  mutate(Date = as.Date(createdAt)) %>%
  filter(Date > "2020-12-31") %>%
  group_by(Date) %>%
  summarise(post_count = n()) %>%
  ggplot(aes(x = Date, y = post_count)) +
  geom_line() +
  #geom_point() +
  geom_vline(aes(xintercept = as.Date("2021-02-24"), color = "學測成績放榜"), 
             linetype = "dashed") +
  geom_vline(aes(xintercept = as.Date("2021-03-31"), color = "個申一階放榜"), 
             linetype = "dashed") +
  geom_vline(aes(xintercept = as.Date("2021-05-02"), color = "個申二階開始放榜"), 
             linetype = "dashed") +
  #geom_text(x = as.Date("2022-05-02"), y = 0, label="個申二階開始放榜", colour = "blue", size = 4) +
  geom_vline(aes(xintercept = as.Date("2022-03-01"), color = "學測成績放榜"), 
             linetype = "dashed") +
  geom_vline(aes(xintercept = as.Date("2022-03-31"), color = "個申一階放榜"), 
             linetype = "dashed") +
  geom_vline(aes(xintercept = as.Date("2022-05-02"), color = "個申二階開始放榜"), 
             linetype = "dashed") +
  theme(legend.position = "bottom") +
  scale_color_manual(name = "", values = c("學測成績放榜" = "#00AFBB", 
                                           "個申一階放榜" = "#E7B800",
                                           "個申二階開始放榜" = "#FC4E07")) +
  #theme_bw() +
  labs(title = "發文次數", x = "日期", y = "次數")

# plot the tags of posts used more than 500 times in the posts -----------------
fresh_post_latest %>% 
  select(id, title, topics) %>% 
  mutate(topics = str_replace_all(topics, "[\\[\\]]", "")) %>% 
  separate(topics, into = str_c("tp", 1:10), sep = ",") %>% 
  pivot_longer(tp1:tp10, names_to = "tp", values_to = "topics", values_drop_na = T) %>%
  mutate(topics = str_replace_all(topics, " ", "")) %>%
  filter(str_detect(topics, "")) %>% 
  group_by(topics) %>% 
  summarise(tpn = n()) %>% 
  filter(tpn > 500) %>%
  ggplot(aes(x = reorder(topics, tpn), y = tpn)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  theme_minimal() +
  labs(title = "使用次數", x = "發文標籤", y = "次數")

# plot the number of users' identity mentioned more than 150 times in the posts 
fresh_post_latest %>% 
  #mutate(school_enc = iconv(school, to = "UTF-8")) %>%
  group_by(school) %>%
  summarise(post_count = n()) %>%
  filter(post_count >= 150) %>%
  ggplot(aes(x = reorder(school, post_count), y = post_count)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  theme_bw() +
  labs(title = "發文次數", x = "學校", y = "次數")

#topics <- fresh_content_old %>% select(topics) %>%
#  separate(topics, c("a", "b"), sep = ",")

# Topic model -------------------------------------------------------------
install.packages("stm")
library(stm)
my_lda_fit = stm(dfms, K = 5)
plot(my_lda_fit)

#BTM trial
topics <- fresh_post_latest %>% select(id, topics) 
anno <- topics %>% BTM(k = 5)
scores <- predict(anno, newdata = topics)

# Inspecting the results again
topfeatures(dfms, 30)
textplot_wordcloud(dfms)