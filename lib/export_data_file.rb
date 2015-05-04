# encoding: utf-8
module ExportDataFile
  require 'csv'

  #########################################
  #########################################
  # create csv file
  def self.create_csv
    start = Time.now

    output = ''
    d = Dataset.first
    questions = d.questions.for_analysis
    puts "- there are #{questions.length} questions"
    filename = d.title.strip.latinize.to_ascii.gsub(' ', '_').gsub(/[\\ \/ \: \* \? \" \< \> \| \, \. ]/,'')
    csv_file = "#{Rails.root}/tmp/#{filename}.csv"
    
    #######################
    # create csv file
    puts "- creating csv file"
    File.open(csv_file, 'w') {|f| f.write(build_csv(d, questions, with_raw_data: false, with_header: true)) }

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the csv file"
    return nil  end



  #########################################
  #########################################
  # create spss file
  def self.create_spss
    start = Time.now

    output = ''
    d = Dataset.first
    questions = d.questions.for_analysis
    puts "- there are #{questions.length} questions"
    filename = d.title.strip.latinize.to_ascii.gsub(' ', '_').gsub(/[\\ \/ \: \* \? \" \< \> \| \, \. ]/,'')
    spss_file = "#{Rails.root}/tmp/#{filename}.sps"
    csv_file = "#{Rails.root}/tmp/#{filename}_SPSS.csv"
    

    #######################
    ## create spss file
    puts "- writing to file: #{spss_file}"

    # add title
    output << "TITLE \"#{d.title}\".\n\n"

    # add data list file line
    output << "DATA LIST FILE= \"#{filename}.csv\"  free (\",\")\n"


    # add question codes
    output << '/ '
    questions.each do |question|
      output << question.original_code
      output << ' '
    end
    output << " . \n\n"

    # add variable labels (question code/text)
    output << "VARIABLE LABELS \n"
    questions.each do |question|
      output << question.original_code
      output << ' "'
#      output << question.text
      output << question.original_code
      output << "\" \n"
    end
    output << " . \n\n"


    # add value labels (answer)
    output << "VALUE LABELS \n"
    questions.each do |question|
      output << "/ \n"
      output << question.original_code
      output << " \n"
      question.answers.all_for_analysis.each do |answer|
        output << ' ' # not needed - just to make it easier to read
        output << answer.value
        output << ' "'
        output << answer.text
        output << "\" \n"
      end
    end
    output << " . \n\n"


    # finish the file
    output << 'EXECUTE.'

    # write out spss file
    File.open(spss_file, 'w') {|f| f.write(output) }


    #######################
    # create csv file
    puts "- creating csv file"
    File.open(csv_file, 'w') {|f| f.write(build_csv(d, questions)) }

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the spss and csv files"
    return nil
  end


  #########################################
  #########################################
  # create stata file
  # notes:
  # create labels:
      # label define sexfmt 0 "Male" 1 "Female"
      # infile str16 name sex:sexfmt age using persons  

# When infile is directed to use a value label and it finds an entry in the file that does not match
# any of the codings recorded in the label, it prints a warning message and stores missing for the
# observation. By specifying the automatic option, you can instead have infile automatically add
# new entries to the value label
      
  def self.create_stata
    start = Time.now


    puts "-- it took #{(Time.now-start).round(3)} seconds to create the stata and csv files"
    return nil
  end



private

  def self.build_csv(dataset, questions, options={})
    with_raw_data = options[:with_raw_data].nil? ? true : options[:with_raw_data]
    with_header = options[:with_header].nil? ? false : options[:with_header]

    data = []
    header = []
    csv = nil

    if dataset.present? && questions.present?
      questions.each do |question|
        header << "#{question.original_code} - #{question.text}"

        if with_raw_data
          # use the data values
          data << dataset.data_items.code_data(question.code)
        else
          # replace the data values with the answer text

          # get original data
          question_data = dataset.data_items.code_data(question.code)

          # now replace data values with answer text
          question.answers.all_for_analysis.each do |answer|
            question_data.select{ |x| x == answer.value }.each{ |x| x.replace( answer.text ) }
          end

          data << question_data
        end
      end

      # now use transpose to get in proper format
      csv = CSV.generate do |csv_row|
        if with_header
          csv_row << header
        end

        data.transpose.each do |row|
          csv_row << row
        end
      end
    end

    return csv
  end

end