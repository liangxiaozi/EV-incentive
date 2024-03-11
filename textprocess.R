library(tidyverse)
library(tidytext)
library(textdata)
library(udpipe)
library(SnowballC)
library(rvest)
library(igraph)
library(ggraph)

# replace with your own working directory!!!
setwd("/Users/liangxiao/Desktop/Y2 Winter/R II/Final Project/final-project-mikaela-xiao")

# text data wrangling ----

# State Regulations California Code of Regulations, Title 13 - Motor Vehicles, Division 1 - Department of Motor Vehicles, Chapter 1 - Department of Motor Vehicles, Article 3 - Vehicle Registration and Titling, from Legal Information Institute, Cornell Law School

# Alternative: directly get access to the archived data by applying:
### text <- read.table("data/raw/text.txt") ###
# And jump to line 45
path <- "https://www.law.cornell.edu/regulations/california/title-13/division-1/chapter-1/article-3"

# read html
response <- read_html(path)

# scrape all sub-article urls
url <- response |> 
  html_element(".toc") |> 
  html_elements("a") |> 
  html_attr("href")

# make urls full
full_url <- paste0("https://www.law.cornell.edu", url)

# loop
text <- list()

for (i in 1:length(full_url)) {
  response_inner <- read_html(full_url[i]) # read sub-article htmls
  
  text[i] <- response_inner |> # store sub-article texts
    html_elements(".tab-pane.active") |> # including main body and notes
    html_text2()
}

# collapse scraped texts (If you load the archived data, start from here!!!)
full_text <- paste0(text)

# udpipe NLP
parsed <- udpipe(tolower(full_text), "english") |> 
  mutate(lemma = tolower(lemma)) |> # lower-case lemma
  filter(!lemma %in% stop_words$word, # remove stop words
         !upos %in% c("PUNCT", "CCONJ", "NUM", "X")) # remove punctuation, conjunction, number and others

# create a dictionary on EV
clean_dict <- c("clean")

# 1. Sentiment analysis ----

# 1.1 Overall sentiment ----

# pull AFINN lexicon
sentiment_afinn <- get_sentiments("afinn")

# Overall AFINN mean
parsed |> 
  left_join(sentiment_afinn, by = c("lemma" = "word")) |> 
  summarise(sentiment = mean(value, na.rm = TRUE))

# Overall AFINN plot
parsed |> 
  left_join(sentiment_afinn, by = c("lemma" = "word")) |> 
  ggplot(aes(x = value)) +
  geom_bar() +
  scale_x_continuous(name = "AFINN",
                     breaks = -4:3) +
  labs(title = "Article 3 - Vehicle Registration and Titling",
       subtitle = "AFINN sentiment analysis")

ggsave("image/text_overall_AFINN.png")

# 1.2 EV ("clean") sentiment ----

# Words referring to EV
EV_children <- parsed |> 
  filter(lemma %in% clean_dict) |> 
  inner_join(parsed |> 
               select(doc_id, head_token_id, lemma), by = c("token_id" = "head_token_id", "doc_id" = "doc_id"))

EV_children_sentiment <- EV_children |> 
  select(doc_id, lemma.y) |>
  rename(word = lemma.y)

# Words being referred to by EV
EV_parents <- parsed |> 
  filter(lemma %in% clean_dict) |>  
  inner_join(parsed |> 
               select(doc_id, token_id, lemma), by = c("head_token_id" = "token_id", "doc_id" = "doc_id"))

EV_parents_sentiment <- EV_parents |> 
  select(doc_id, lemma.y) |>
  rename(word = lemma.y)

# combine children and parents
EV_words <- rbind(EV_children_sentiment, EV_parents_sentiment) |> 
  left_join(sentiment_afinn, by = "word") 

# EV AFINN mean
EV_words |> 
  summarise(sentiment = mean(value, na.rm = TRUE))

# EV AFINN plot
EV_words |> 
  ggplot(aes(x = value)) +
  geom_bar() +
  scale_x_continuous(name = "AFINN",
                     breaks = -3:2) +
  labs(title = "Dependency on EV, Article 3 - Vehicle Registration and Titling",
       subtitle = "AFINN sentiment analysis")

ggsave("image/text_EV_AFINN.png")

# 2. Frequency bigram ----

EV_children_freq <- EV_children |> 
  rename(parent = lemma.x, child = lemma.y) |> 
  select(doc_id, parent, child)

EV_parents_freq <- EV_parents |>  
  rename(child = lemma.x, parent = lemma.y) |> 
  select(doc_id, parent, child)

bigrams <- rbind(EV_children_freq, EV_parents_freq)

bigram_counts <- bigrams  |> 
  group_by(doc_id, parent, child) |> 
  summarize(n = n()) |> 
  ungroup()

bigram_counts |> 
  arrange(-n)

bigram_graph <- bigram_counts |> 
  filter(n > 3) |> # keep only words with frequency of dependence over 3
  select(parent, child, n) |> 
  graph_from_data_frame() 

ggraph(bigram_graph, layout = "fr") +
  geom_edge_link(aes(edge_alpha = n), 
                 show.legend = FALSE, 
                 arrow = arrow(length = unit(4, 'mm')), 
                 end_cap = circle(.07, 'inches')) +
  geom_node_point(color = "lightblue", size = 5) + 
  geom_node_text(aes(label = name), 
                 vjust = 1, 
                 hjust = 1, 
                 size = 5) + 
  theme_void()

ggsave("image/text_frequency_bigram.png")

# 3. Cooccurrences ----

cooc_corr <- parsed |> 
  filter(upos %in% c("NOUN", "PROPN", "VERB", "ADV", "ADJ")) |> 
  document_term_frequencies(document = "sentence_id", 
                            term = "lemma") |> 
  document_term_matrix() |> 
  dtm_cor() |> 
  as_cooccurrence() |> 
  arrange(desc(cooc))

cooc_corr |> 
  filter(term1 %in% clean_dict | term2 %in% clean_dict) |> 
  head(10)
