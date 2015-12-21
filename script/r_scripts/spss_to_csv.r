#! /usr/bin/env Rscript

#######
## this script will generate 3 files
# 1: csv file of data
# 3: csv file of question codes and text
# 3: csv file of answer values and text

## four required arguments:
# - 1: spss file to read in
# - 2: csv file to save raw data to
# - 3: csv file containing variable code and question
# - 4: csv file containing answers for questions

# take in the arguments
args <- commandArgs(TRUE)

print(paste('spss file to read in = ', args[1]))
print(paste('csv file for data = ', args[2]))
print(paste('csv file for questions labels = ', args[3]))
print(paste('csv file for answers labels = ', args[4]))


# function to clean bad characters in text
clean_text <- function(text){
  return(gsub("\x85", '...', gsub("\x91", "'", gsub("\x92", "'", gsub("\x93", '"', gsub("\x94", '"', text))))))
}

# read in the data with labels so can test if each variable is factor
data <- read.spss(args[1], use.value.labels=T, to.data.frame=F)


# pull out the questions/answers to variables to be used soon
answer_labels <- attr(data, 'label.table')
question_labels <- attr(data, 'variable.labels')

# record which questions are numeric and which are categorical (factors)
# - is used to convert factor data to numeric
# - and to set the question data type value in the csv
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
# - format is: question code, question text, data type
questions <- c()
# vector to store all questions/answers
# - format is: question code, answer value, answer, text
answers <- c()
# record the number of answers found so can use to tell matrix how many rows are needed
num_answers <- 0

# for each question
for (i in 1:length(question_labels)){
  # determine the question data type
  # - use the is_factor_list / is_numeric_list to check type
  # - c = categorical / factor
  # - n = numerical
  data_type <- ''
  if (is_factor_list[i] == TRUE){
    data_type <- 'c'
  }else if (is_numeric_list[i] == TRUE){
    data_type <- 'n'
  }
  # - format is: question code, question text, data type
  questions <- c(questions, c(names(question_labels[i]), clean_text(question_labels[i])), data_type)
}

# build the answers
# - have to do this separate from the questions for the answer and question length might not match
for (i in 1:length(answer_labels)){
  # only continue if the question has answers
  answer_length <- length(unlist(answer_labels[i]))
  if (answer_length > 0){
    # for each answer in this question
    # the answers are ordered backwards,
    # so go through the answers backwards to get them in the correct order
    for (j in answer_length:1){
      # record the number of rows
      num_answers <- num_answers + 1

      question_code <- names(answer_labels[i])
      answer_text <- unlist(answer_labels[i])[j]
      
      # the answer text has the question code appended to it, so take it off using sub
      # make sure the answer text is properly encoded as utf8
      answer_text_clean <- clean_text(sub(paste(c(question_code, '.'), collapse=''), '', names(answer_text)))

      # - format is: question code, answer value, answer text
      answers <- c(answers, c(question_code, answer_text, answer_text_clean))

    }
  }
}

# create the array of questions/answers
question_array <- matrix(questions, nrow=length(question_labels), ncol=3, byrow = TRUE)
answer_array <- matrix(answers, nrow=num_answers, ncol=3, byrow = TRUE)

# add variable names so they appear as col headers in csv
colnames(question_array) <- c('Question Code', 'Question Text', 'Question Data Type')
colnames(answer_array) <- c('Question Code', 'Answer Value', 'Answer Text')

# create csv
write.csv(question_array, args[3], row.names = F)
write.csv(answer_array, args[4], row.names = F)



##########
## CREATE DATA CSV
##########
# read in the data without factors so data csv is using correct codes
# - tried doing it with the data with factors and then converting factors to numeric
#   but R starts numbers at 1 for factors and does not pay attention to original values
#   so this does not work for it will not match the answer csv values.
#      # convert factor data to numeric before writing out csv
#      data[is_factor_list] <- lapply(data[is_factor_list], as.numeric)
#      write.csv(data, args[2], row.names = F, na = "")
write.csv(read.spss(args[1], use.value.labels=F, to.data.frame=F), args[2], row.names = F, na = "")



# quit
q()
