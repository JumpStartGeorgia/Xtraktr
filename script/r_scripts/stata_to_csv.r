#! /usr/bin/env Rscript

#######
## this script will generate 4 files
# 1: csv file of data
# 2: spss code file that contains question codes and answers
# 3: csv file of question codes and text
# 4: text file of question answers

## notes
# - the 2nd file contains a list of answers for each question,
#   but does not work properly if the data has values that are not in the specified list of answers.
#   when this occurs, the answers are dropped.
#   that is why the 4th file is needed.
# - currently I cannot figure out how to properly write out to csv in R, so the following files are a hack.
#   - 3rd file format: [1] "Question Code || Question Text"
#   - 4th file format: [1] "Question Code || Answer Value || Answer Text"
#   (additional code will be needed to convert this to csv format)


# five required arguments:
# - 1: stata file to read in
# - 2: csv file to save raw data to
# - 3: spss file to save variable codes to
# - 4: csv file containing variable code and question
# - 5: text file containing answers for questions in a special format

# take in the arguments
args <- commandArgs(TRUE)

print(paste('stata file to read in = ', args[1]))
print(paste('csv file for data = ', args[2]))
print(paste('spss file for codes = ', args[3]))
print(paste('csv file for questions labels = ', args[4]))
print(paste('text file for answers labels = ', args[5]))

#############################
# first, read in the data using factors so can generate sps file with answers in them
#############################
# read in dta
# - need value.label to be true so that label values are available on export
data <- read.dta(args[1], convert.factors = T)

# basic spss export
# canont use: write.foreign(data, 'out.csv', 'code.sps', package="SPSS")
# for may get error: cannot abbreviate the variable names to eight or fewer letters
# so use the following instead:
foreign:::writeForeignSPSS(data, gsub('.csv$','_bad.csv',args[2]), args[3], varnames=names(data))

#############################
# now, read in the data not using factors so can generate all other files without the code values being changed
#############################
# read in dta
# - need value.label to be true so that label values are available on export
data <- read.dta(args[1], convert.factors = F)

# basic spss export
# canont use: write.foreign(data, 'out.csv', 'code.sps', package="SPSS")
# for may get error: cannot abbreviate the variable names to eight or fewer letters
# so use the following instead:
foreign:::writeForeignSPSS(data, args[2], gsub('.sps$','_bad.sps',args[3]), varnames=names(data))

# write out the question labels
# dta does not include the codes in var.labels, so have to combine them by hand
# using hack of: code || text
var <- attr(data, 'var.labels')
val <- attr(data, 'val.labels')
sink(args[4])
# for each question
for (i in 1:length(names(data))){
  # write to file as code || text || var code
  print(paste(c(names(data)[i], var[i], val[i]), collapse=" || "))
}
sink()

# write out the full list of questions that have answers
table <- attr(data, 'label.table')
sink(gsub('.csv$','_temp.csv',args[5]))
# for each question
# - questions are in reverse order, so go backwards
for (i in length(table):1){
  # only continue if the question has answers
  if (length(unlist(table[i])) != 0){
    # for each answer in this question
    for (j in 1:length(unlist(table[i]))){
      # the answer text has the question code appended to it, so take it off using sub
      print(paste(c(names(table[i]), unlist(table[i])[j], sub(paste(c(names(table[i]), '.'), collapse=''), '', names(unlist(table[i])[j]))), collapse=" || "))
    }
  }
}
sink()


# quit
q()
