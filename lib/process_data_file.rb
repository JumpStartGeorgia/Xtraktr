module ProcessDataFile
  require 'csv'
  
  #######################
  #######################
  ##
  ## run a data file (spss, sas, etc) throuh an R script
  ## that generates CSV files of data, questions and answers
  ## 
  #######################
  #######################



  #######################
  ## global variables
  @@path = "#{Rails.root}/public/system/datasets/[dataset_id]/processed/"
  @@file_data = 'data.csv'
  @@file_questions = 'questions.csv'
  @@file_answers_complete = 'answers_complete.csv'
  @@file_answers_incomplete = 'answers_incomplete.csv'


  #######################
  # convert a spss file to csv
  def process_spss
    path = @@path.sub('[dataset_id]', self.id.to_s)
    # file has not be saved to proper place yet, so have to get queued file path
    file_to_process = self.datafile.queued_for_write[:original].path
    file_r = "#{Rails.root}/script/r_scripts/spss_to_csv.r"
    file_sps = path + "spss_code.sps"
    file_data = path + @@file_data
    file_questions = path + @@file_questions
    file_answers_complete = path + @@file_answers_complete
    file_answers_incomplete = path + @@file_answers_incomplete

    # make sure files exists
    if File.exists?(file_r) && File.exists?(file_to_process)

      # create dataset directory if not exist
      FileUtils.mkdir_p(File.dirname(file_data))

      # run the R script
      result = system 'Rscript', '--default-packages=foreign,MASS', file_r, file_to_process, file_data, file_sps, file_questions, file_answers_complete

      if result.nil?
        puts "Error was #{$?}"
      elsif result
        puts "You made it!"

        puts "=============================="
        puts "reading in questions from #{file_questions} and saving to questions attribute"
        # format: {code: text}
        self.questions = {}
        if File.exists?(file_questions)
          line_number = 0
          CSV.foreach(file_questions) do |row|
            line_number += 1
            # only add if the code and text are present
            if row[0].strip.present? && row[1].strip.present?
              # mongo does not allow '.' in key names, so replace with '|'
              self.questions[row[0].strip.gsub('.', '|')] = {text: row[1].strip, original_code: row[0].strip, is_mappable: false, has_code_answers: false}
            else
              puts "******************************"
              puts "Line #{line_number} of #{file_questions} is missing the code or text."
              puts "******************************"
            end
          end
        end
        puts " - added #{self.questions.keys.length} questions"

        # before can read in data, we have to add a header row to it
        # so the SmaterCSV library that reads in the csv has the correct keys for the values
        puts "=============================="
        puts "adding header to data csv"
        # read in data file and create new file with header
        data = CSV.read(file_data)
        CSV.open(file_data, 'w', write_headers: true, headers: self.questions.keys) do |csv|
          data.each do |row|
            csv << row
          end
        end


        puts "=============================="
        puts "reading in data from #{file_data} and saving to data attribute"
        if File.exists?(file_data)
          self.data = SmarterCSV.process(file_data, {downcase_header: false, strings_as_keys: true})
        end
        puts "added #{self.data.length} records"


        puts "=============================="
        puts "reading in answers from #{file_answers_complete} and converting to csv"
        # format of each line of file is: [1] "Question Code || Answer Value || Answer Text"
        answers_complete = []
        # save to answers attribute in dataset
        # format: answer[question code] = {value, text}
        self.answers = {}
        if File.exists?(file_answers_complete)
          line_number = 0
          File.open(file_answers_complete, "r") do |f|
            last_key = nil
            sort_order = 0
            f.each_line do |line|
              line_number += 1
              # take out the [1] " at the beginning and the closing "
              answer = line.strip.gsub('[1] "', '').gsub(/\"$/, '')
              values = answer.split(' || ')
              if values.length == 3
                # save for writing to csv
                answers_complete << [values[0].strip, values[1].strip, values[2].strip]

                # save to answers attribute
                key = values[0].strip.gsub('.', '|')
                # if this is a new key (question code), reset sort variables
                if last_key != key
                  last_key = key.dup
                  sort_order = 0
                end
                # create sort order that is based on order they are listed in data file
                sort_order += 1
                # - if this is the first answer for this question, initialize the array
                self.answers[key] = [] if self.answers[key].nil?
                self.answers[key] << {value: values[1].strip, text: values[2].strip, can_exclude: false, sort_order: sort_order}
                # update question to indciate it has answers
                self.questions[key][:has_code_answers] = true
              else
                puts "******************************"
                puts "ERROR"
                puts "An error occurred on line #{line_number} of #{file_answers_complete} while parsing the answers."
                puts "This line was not in the correct format of: [1] \"Question Code || Answer Value || Answer Text\""
                puts "******************************"
                break
              end
            end
          end   
        end   

        # if answers exists, write to csv file
        if answers_complete.length > 0
          puts "saving complete answers to csv"
          puts "++ - there were #{answers_complete.length} total answers recorded for #{answers_complete.map{|x| x[0]}.uniq.length} questions"
          CSV.open(file_answers_complete, 'w') do |csv|
            answers_complete.each do |answer|
              csv << answer
            end
          end
        end



        puts "=============================="
        puts "reading in incomplete answers from sps file #{file_sps}"
        # open the sps file and convert the list of answers into a csv file 
        # row format: question_code, answer code, answer text
        answers_incomplete = []
        found_labels = false
        next_line_question = false
        question_code = nil
        line_number = 0
        File.open(file_sps, "r") do |f|
          f.each_line do |line|
            line_number += 1
      #      puts "++ line #{line_number}"
            if found_labels
              if line.strip == '.'
      #          puts "++ - found '.', stopping parsing of answers"
                # this is the end of the list of answers so stop
                break
              elsif line.strip == '/'
      #          puts "++ - found /"
                # this is the end of a set of answers for a question
                question_code = nil
                next_line_question = true
              else
                # if this line is a question, start a new row array and save the question
                # else this is an answer
                if next_line_question
      #            puts "++ - found question: #{line}"
                  next_line_question = false
                  question_code = line.strip
                else
                  # this is an answer, record row in format: [question_code, value, text]
                  # line is in format of: value "text"

                  # strip space at beginning and end of line
                  answer = line.strip
                  # get index of space between value and text
                  # index will be used to pull out the answer code and answer text
      #            puts "++ -- found answer: #{line}"

                  index = answer.index(' "')
                  if index.nil? 
                    puts "******************************"
                    puts "ERROR"
                    puts "An error occurred on line #{line_number} of #{file_sps} while parsing the answers."
                    puts "This line was not in the correct format of: value 'answer text'"
                    puts "******************************"
                    break
                  else
                    answers_incomplete << [question_code, answer[0..index-1], answer[index+2..-2]]
                  end

                end
              end
            elsif line.strip == 'VALUE LABELS'
              # found beginning of list of answers
      #        puts "++++++++++++++ found value labels on line #{line_number}"
              found_labels = true
            end
          end
        end  

        puts "=============================="

        # if answers exists, write to csv file
        if answers_incomplete.length > 0
          puts "saving incomplete answers to csv"
          puts "++ - there were #{answers_incomplete.length} total answers recorded for #{answers_incomplete.map{|x| x[0]}.uniq.length} questions"
          CSV.open(file_answers_incomplete, 'w') do |csv|
            answers_incomplete.each do |answer|
              csv << answer
            end
          end
        end

        puts "=============================="
        # if complete answers length != bad answers length, show error message
        # this will happen if the data contains values that are not in the defined list of answers
        if answers_complete.length != answers_incomplete.length
          complete_questions = answers_complete.map{|x| x[0]}.uniq    
          incomplete_questions = answers_incomplete.map{|x| x[0]}.uniq
          # record question codes to questions_with_bad_answers attribute
          self.questions_with_bad_answers = complete_questions - incomplete_questions
          self.has_warnings = self.questions_with_bad_answers.present?
          puts "******************************"
          puts "WARNING"
          puts "When parsing your file, we found that there are #{complete_questions.length - incomplete_questions.length} questions "
          puts "that contain values that are not listed as one of the possible answers."
          puts "We suggest you review the values for these questions and fix accordingly."
#          puts "Here are the questions that had this issue:"
#          puts (complete_questions - incomplete_questions).map{|x| "#{x}\n"}
          puts "******************************"
        end

      end

    else
      puts "******************************"
      puts "WARNING"
      puts "The required R script file or the data file to process do not exist"
      puts "******************************"
    end
  end

end