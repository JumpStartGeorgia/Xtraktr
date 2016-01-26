#! /usr/bin/env Rscript

#######
## this script will generate 3 files
# 1: csv file of data
# 3: csv file of question codes and text
# 3: csv file of answer values and text

## four required arguments:
# - 1: stata file to read in
# - 2: csv file to save raw data to
# - 3: csv file containing variable code and question
# - 4: csv file containing answers for questions


#######
## notes
# - if the data file is using variables to define the answers, the answer csv file
#   will only have the answers to the variables and not to each of the questions that use the variables


# take in the arguments
args <- commandArgs(TRUE)

print(paste('stata file to read in = ', args[1]))
print(paste('csv file for data = ', args[2]))
print(paste('csv file for questions labels = ', args[3]))
print(paste('csv file for answers labels = ', args[4]))


# function to clean bad characters in text
clean_text <- function(text){
  return(gsub("\x85", '...', gsub("\x91", "'", gsub("\x92", "'", gsub("\x93", '"', gsub("\x94", '"', text))))))
}

# read in the data with factors so know which as factors and which are not
data <- read.dta(args[1], convert.factors = T)

# pull out the questions/answers to variables to be used soon
# - variable codes is needed because in stata you can create a variable that defines answers and then
#    reuse the answers on questions. 
#    answer_labels uses the variable code and not the question code so need variable code to be able to switch to question code
answer_labels <- attr(data, 'label.table')
question_labels <- iconv(attr(data, 'var.labels'), 'CP1252', 'UTF-8', sub="byte")
variable_codes <- iconv(attr(data, 'val.labels'), 'CP1252', 'UTF-8', sub="byte")

# record with questions are numeric and which are categorical (factors)
# is used to convert factor data to numeric
# and to set the question data type value in the csv
# note - due to the way read.spss works, if the unique list of data answers > the list of possible answers, 
#        the question will be marked as numeric
#        - this could happen if the question is a range of x..y (least .. best) and the data file only
#          defined the least answer and best answer, but nothing in between
is_factor_list <- sapply(data, is.factor)
is_numeric_list <- sapply(data, is.numeric)

##########
## CREATE QUESTION AND ANSWER TEXT CSV
##########

# vector to store all questions
# - format is: question code, question text, variable code, data type
questions <- c()
# vector to store all questions/answers
# - format is: question code, answer value, answer, text
answers <- c()
# record the number of answers found so can use to tell matrix how many rows are needed
num_answers <- 0

# build the questions
for (i in 1:length(question_labels)){
  # get question and variable code
  question_code <- iconv(names(data[i]), 'CP1252', 'UTF-8', sub="byte")
  variable_code <- variable_codes[i]
  # choose the correct code to get the answers for this question
  # - if variable code exists, use it, else question code
  if (is.null(variable_code)){
    correct_code <- question_code
  }else{
    correct_code <- variable_code
  }
  # see if this question has answers
  question_answers_length <- length(answer_labels[[correct_code]])
  # determine the question data type
  # - use the is_factor_list / is_numeric_list to check type
  # - c = categorical / factor
  # - n = numerical
  # read.dta will mark a question as numeric if the question data does not match predefined answers
  # (which can be caused by bad data entry or missing answers)
  # we feel it is better to default to categorical question instead of numeric, 
  # so if question is numeric but has categorical questions, save it as categorical to be safe
  data_type <- ''
  if (is_factor_list[i] == TRUE || (is_numeric_list[i] == TRUE && question_answers_length > 0)){
    data_type <- 'c'
  }else if (is_numeric_list[i] == TRUE){
    data_type <- 'n'
  }
  # - format is: question code, question text, data type, variable code
  questions <- c(questions, c(question_code, clean_text(question_labels[i]), data_type, variable_code))
}

# build the answers
# - have to do this separate from the questions for the answer and question length might not match
for (i in 1:length(answer_labels)){
  # only continue if the question has answers
  answer_length <- length(unlist(answer_labels[i]))
  if (answer_length > 0){
    # for each answer in this question
    for (j in 1:answer_length){
      # record the number of rows
      num_answers <- num_answers + 1

      question_code <- names(answer_labels[i])
      answer_text <- unlist(answer_labels[i])[j]
      
      # the answer text has the question code appended to it, so take it off using sub
      # make sure the answer text is properly encoded as utf8
      answer_text_clean <- clean_text(iconv(sub(paste(c(question_code, '.'), collapse=''), '', names(answer_text)), 'CP1252', 'UTF-8', sub="byte"))

      # - format is: question code, answer value, answer text
      answers <- c(answers, c(question_code, answer_text, answer_text_clean))
    }
  }
}


# create the array of questions/answers
question_array <- matrix(questions, nrow=length(question_labels), ncol=4, byrow = TRUE)
answer_array <- matrix(answers, nrow=num_answers, ncol=3, byrow = TRUE)

# add variable names so they appear as col headers in csv
colnames(question_array) <- c('Question Code', 'Question Text', 'Question Data Type', 'Question Variable')
colnames(answer_array) <- c('Question Code', 'Answer Value', 'Answer Text')

# create csv
write.csv(question_array, args[3], row.names = F)
write.csv(answer_array, gsub('.csv$','_temp.csv',args[4]), row.names = F)


##########
## CREATE DATA CSV
##########
# read in the data without factors so data csv is using correct codes
# - tried doing it with the data with factors and then converting factors to numeric
#   but R starts numbers at 1 for factors and does not pay attention to original values
#   so this does not work for it will not match the answer csv values.
#     # convert factor data to numeric before writing out csv
#     data[is_factor_list] <- lapply(data[is_factor_list], as.numeric)
#     write.csv(data, args[2], row.names = F, na = "")
#write.csv(read.dta(args[1], convert.factors = F), args[2], row.names = F, na = "")
write.table(read.dta(args[1], convert.factors = F), args[2], row.names = F, col.names = FALSE, na = "", fileEncoding = 'UTF-8', qmethod = "double", sep=",", dec=".", quote = TRUE)

q()
