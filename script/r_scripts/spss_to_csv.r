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
# - currently I cannot figure out how to properly write out to csv in R, so this file is a hack.
#   each line is formatted as: [1] "Question Code || Answer Code || Answer Text"
#   code will be needed to convert this to csv format


# five required arguments:
# - 1: spss file to read in
# - 2: csv file to save raw data to
# - 3: spss file to save variable codes to
# - 4: csv file containing variable code and question
# - 5: text file containing answers for questions in a special format

# take in the arguments
args <- commandArgs(TRUE)

print(paste('spss file to read in = ', args[1]))
print(paste('csv file for data = ', args[2]))
print(paste('spss file for codes = ', args[3]))
print(paste('csv file for questions labels = ', args[4]))
print(paste('text file for answers labels = ', args[5]))

# read in spss
# - need value.label to be true so that label values are available on export
data <- read.spss(args[1], use.value.label=T, to.data.frame=F)

# basic spss export
#write.foreign(data, 'out.csv', 'code.sps', package="SPSS")
# if get error: cannot abbreviate the variable names to eight or fewer letters
# switch to:
foreign:::writeForeignSPSS(data, args[2], args[3], varnames=names(data))
#foreign:::writeForeignSPSS(data, args[2], args[3], varnames=attr(data, 'variable.labels'))

# write out the question labels
write.csv(attr(data, 'variable.labels'), args[4])

# write out the full list of questions that have answers
table <- attr(data, 'label.table')
sink(args[5])
# for each question
for (i in 1:length(table)){
  # only continue if the question has answers
  if (length(unlist(table[i])) != 0){
    # for each answer in this question
    # the answers are ordered backwards,
    # so go through the answers backwards to get them in the correct order
    for (j in length(unlist(table[i])):1){
      # the answer text has the question code appended to it, so take it off using sub
      print(paste(c(names(table[i]), unlist(table[i])[j], sub(paste(c(names(table[i]), '.'), collapse=''), '', names(unlist(table[i])[j]))), collapse=" || "))
    }
  }
}
sink()


# quit
q()
