# encoding: utf-8
module ExportData
  require 'csv'
  require 'zipruby'

  # create a zip file of the request type
  # if type is not codebook, include coodebook in zip
  # update dataset with path to the file
  # type = codebook, csv, spss, stata, r
  def self.create_file(dataset, type='codebook', use_processed_csv=false)
    start = Time.now

    # only contine if the dataset is valid
    if dataset.valid?

      # set global vars
      set_global_vars

      current_locale = dataset.current_locale.dup

      # make sure dataset has url object
      dataset.create_urls_object
      get_url_params(dataset)

      # create files for each locale in the dataset
      dataset.languages.each do |locale|
        puts "@@@@@@@@@@@@@@@@ creating files for locale #{locale}"

        dataset.current_locale = locale

        # set the file paths for this dataset
        set_dataset_file_paths(dataset)

        # all options require codebook, so create it
        codebook(dataset)

        # make the csv files if needed
        if !use_processed_csv && ['csv', 'spss', 'stata', 'r'].include?(type)
          build_csv_headers(dataset)
          build_csv_files(dataset)
        end

        # generate the requested files
        case type
          when 'csv'
            csv(dataset, use_processed_csv)
          when 'spss'
            spss(dataset, use_processed_csv)
          when 'stata'
            stata(dataset, use_processed_csv)
          when 'r'
            r(dataset, use_processed_csv)
        end

      end

      dataset.current_locale = current_locale
      set_url_params(dataset)

      dataset.save

    end

    puts "@@@@@@@@@@@@@@@@ it took #{(Time.now-start).round(3)} seconds to create #{type} files for dataset"

    return nil
  end


  # create all files for a dataset that do not exist yet
  def self.create_all_files(dataset, use_processed_csv=false)
    start = Time.now

    # only contine if the dataset is valid
    if dataset.valid?

      # set global vars
      set_global_vars

      current_locale = dataset.current_locale.dup

      # make sure dataset has url object
      dataset.create_urls_object
      get_url_params(dataset)

      # if force_reset_download_files is true,
      # make sure the reset_download_files flag is also true
      if dataset.force_reset_download_files?
        dataset.reset_download_files = true
        dataset.force_reset_download_files = false
        # save the dataset now so if another cron job is started, this dataset will not be processed again
        dataset.save
      end

      # create files for each locale in the dataset
      dataset.languages.each do |locale|
        puts "@@@@@@@@@@@@@@@@ creating files for locale #{locale}"

        dataset.current_locale = locale

        # set the file paths for this dataset
        set_dataset_file_paths(dataset)

        # make the csv files
        if !use_processed_csv
          build_csv_headers(dataset)
          build_csv_files(dataset)
        end

        # generate all of the files
        codebook(dataset)
        csv(dataset, use_processed_csv)
        spss(dataset, use_processed_csv)
        stata(dataset, use_processed_csv)
        r(dataset, use_processed_csv)

      end

      dataset.current_locale = current_locale
      set_url_params(dataset)

      # indicate that the files are up to date
      # unless using procesed csv because the real files still need to be created
      dataset.reset_download_files = use_processed_csv

      dataset.save
    end

    puts "@@@@@@@@@@@@@@@@ it took #{(Time.now-start).round(3)} seconds to create all files for dataset"
  end


  # make sure all datasets have data files
  def self.create_all_dataset_files(use_processed_csv=false)
    start = Time.now
    puts "*** use_processed_csv = #{use_processed_csv}"

    count = Dataset.needs_download_files.count
    Dataset.needs_download_files.each_with_index do |dataset, index|
      puts "=========================================="
      puts "=========================================="
      puts "============ dataset #{index+1} out of #{count}"
      puts "============ the script has been running for #{(Time.now-start).round(3)} seconds so far"
      puts "=========================================="
      puts "=========================================="
      puts ""
      puts ">>>>>>>>>> dataset: #{dataset.title}"
      puts ">>>>>>>>>> use_processed_csv: #{use_processed_csv}"
      # create the data files for this dataset
      create_all_files(dataset, use_processed_csv)
    end

    puts "=========================================="
    puts "=========================================="
    puts ">>>>>>>> it took #{(Time.now-start).round(3)} seconds to create all files for all datasets"
  end


  # generate download files for datasets that need it now
  def self.create_all_forced_dataset_files
    start = Time.now

    count = Dataset.needs_download_files_now.count
    Dataset.needs_download_files_now.each_with_index do |dataset, index|
      puts "=========================================="
      puts "=========================================="
      puts "============ dataset #{index+1} out of #{count}"
      puts "============ the script has been running for #{(Time.now-start).round(3)} seconds so far"
      puts "=========================================="
      puts "=========================================="
      puts ""
      puts ">>>>>>>>>> dataset: #{dataset.title}"
      # create the data files for this dataset
      create_all_files(dataset)
    end

    puts "=========================================="
    puts "=========================================="
    puts ">>>>>>>> it took #{(Time.now-start).round(3)} seconds to create all files for datasets that needed them now"
  end


  #########################################
  #########################################
  #########################################
  #########################################

private


  #########################################
  #########################################
  # create codebook file
  # format:
  # question code - question
  # answers:
  #   value - text
  def self.codebook(dataset)
    puts '>>>>>>>>>>>>>>> creating codebok'
    start = Time.now

    # create the public files
    generate_codebook(dataset)

    # create the admin files
    generate_codebook(dataset, true)


    puts "-- it took #{(Time.now-start).round(3)} seconds to create the codebook files"
    return nil
  end


  #########################################
  #########################################
  # create codebook file
  # format:
  # question code - question
  # answers:
  #   value - text
  def self.generate_codebook(dataset, is_admin=false)
    puts ">>> generating codebook, is admin = #{is_admin} "
    start = Time.now

    codebook_file_path = is_admin ? @admin_codebook_file_path : @codebook_file_path
    download_path = is_admin ? @admin_dataset_download_path : @dataset_download_path
    staging_path = is_admin ? @admin_dataset_download_staging_path : @dataset_download_staging_path
    zip_name = "codebook.zip"
    readme_name = "readme_codebook.doc"
    zip_file_path = "#{download_path}/#{dataset.current_locale}/#{zip_name}"
    readme_file_path = "#{staging_path}/#{dataset.current_locale}/#{readme_name}"

    # create the codebook
    if !File.exists?(codebook_file_path) || dataset.reset_download_files?
      output = ''

      # add title
      output << dataset.title
      output << "\n"
      output << "Codebook Generated On: #{I18n.l(start, format: :file)}"
      output << "\n\n"

      # if the dataset is weighted, list all of the weights and which questions they apply to
      if dataset.is_weighted?
        weights = dataset.weights
        output << "============================"
        output << "\n"
        output << "WEIGHTS"
        output << "\n\n"
        if weights.length == 1
          output << "This dataset contains a weight."
          output << "\n"
          output << "Below is the question that is the weight and a list of the questions that applies to the weight."
        else
          output << "This dataset contains weights."
          output << "\n"
          output << "Below are the questions that are the weights and a list of the questions that apply to the weights."
        end
        output << "\n\n"
        weights.each do |weight|
          output << "=============="
          output << "\n"
          output << "Weight Name: #{weight.text}"
          output << "\n"
          output << "Question With Weight Values: #{weight.source_question.code_with_text}"
          output << "\n"
          output << "Questions the Weight Applies To: "
          if weight.is_default || weight.applies_to_all
            output << "All Questions"
          else
            weight.applies_to_questions.each do |question|
              output << "\n"
              output << '    '
              output << question.code_with_text
            end
          end
          output << "\n\n"
        end

        output << "\n\n"
      end

      # add each question/answer
      # - use only questions/answers that can be downloaded and analyzed
      output << "============================"
      output << "\n"
      output << "QUESTIONS"
      output << "\n\n"
      question_type = is_admin ? nil : 'download'
      items = dataset.arranged_items(reload_items: true, question_type: question_type, include_questions: true, include_groups: true, include_subgroups: true)
      output << generate_codebook_items(items, is_admin)
      output << "============================"

      #######################
      # create codebook file
      puts "- creating codebook file"
      File.open(codebook_file_path, 'w') {|f| f.write(output) }
    end


    # create the readme
    create_readme(readme_file_path, 'codebook', dataset)

    # create the zip file
    if File.exists?(readme_file_path) && File.exists?(codebook_file_path)
      create_zip(dataset, zip_file_path, [
          {file_name: @readme_file, file_path: readme_file_path},
          {file_name: @codebook_file, file_path: codebook_file_path}
        ]
      )
    end

    # record the path to the file in the dataset
    if is_admin
      @urls[:admin_codebook][dataset.current_locale] = "#{dataset.admin_data_download_path}/#{dataset.current_locale}/#{zip_name}"
    else
      @urls[:codebook][dataset.current_locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/#{zip_name}"
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to create the codebook file, is admin = #{is_admin}"
    return nil
  end

  def self.generate_codebook_items(items, is_admin, group_type=nil)
    output = ''
    group_indent = ''
    question_indent = ''

    if group_type == 'group'
      group_indent = '    '
      question_indent = '    '
    elsif group_type == 'subgroup'
      group_indent = '    '
      question_indent =  '    '
    elsif group_type == 'subgroup2'
      group_indent = '        '
      question_indent =  '        '
    end

    items.each do |item|
      if item.class == Group

        # add group
        output << generate_codebook_group(item, group_indent)

        # add subgroup/questions
        group_type = group_type.nil? ? 'group' : group_type == 'group' ? 'subgroup' : 'subgroup2'
        output << generate_codebook_items(item.arranged_items, is_admin, group_type)

      elsif item.class == Question
        # add question
        output << generate_codebook_question(item, is_admin, question_indent)
      end
    end
    return output
  end

  def self.generate_codebook_group(group, indent='')
    output = ''

    output << "#{indent}=============="
    output << "\n"
    output << "#{indent}#{group.title}"
    if group.description.present?
      output << " - #{clean_text(group.description)}"
    end
    output << "\n"
    output << "#{indent}=============="
    output << "\n"
    output << "\n"

    return output
  end

  def self.generate_codebook_question(question, is_admin, indent='')
    output = ''

    output << "#{indent}--------------"
    output << "\n"
    output << "#{indent}#{question.original_code} - #{clean_text(question.text)}"
    output << "\n"
    if question.notes.present?
      output << "#{indent}#{I18n.t('app.common.notes')}: #{question.notes}"
      output << "\n"
    end
    answers = is_admin ? question.answers : question.answers.all_for_analysis
    if answers.present?
      output << "#{indent}#{I18n.t('app.common.answers')}:"
      output << "\n"
      answers.each do |answer|
        output << "#{indent}  #{answer.value} - #{clean_text(answer.text)}"
        output << "\n"
      end
    end
    output << "\n"

    return output
  end

  #########################################
  #########################################
  # create csv file
  def self.csv(dataset, use_processed_csv=false)
    puts '>>>>>>>>>>>>>>> creating csv'
    start = Time.now

    csv_file = "csv.csv"
    csv_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{csv_file}"

    # create the public files
    generate_csv(dataset, use_processed_csv)

    # create the admin files
    generate_csv(dataset, use_processed_csv, true)

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the csv files"
    return nil
  end

  # create csv file
  def self.generate_csv(dataset, use_processed_csv=false, is_admin=false)
    puts ">>> generating csv, is admin = #{is_admin} "
    start = Time.now

    codebook_file_path = is_admin ? @admin_codebook_file_path : @codebook_file_path
    download_path = is_admin ? @admin_dataset_download_path : @dataset_download_path
    staging_path = is_admin ? @admin_dataset_download_staging_path : @dataset_download_staging_path

    csv_file = "csv.csv"
    zip_name = "csv.zip"
    readme_name = "readme_csv.doc"
    csv_file_path = "#{staging_path}/#{dataset.current_locale}/#{csv_file}"
    readme_file_path = "#{staging_path}/#{dataset.current_locale}/#{readme_name}"
    zip_file_path = "#{download_path}/#{dataset.current_locale}/#{zip_name}"

    #######################
    # create csv file
    if !File.exists?(csv_file_path) || dataset.reset_download_files?
      if use_processed_csv
        puts "- copying processed csv file"
        copy_processed_csv(csv_file_path)
      else
        puts "- creating csv file with text and header"
        copy_csv_file(csv_file_path, is_admin, with_raw_data: false, with_header: true)
      end
    end

    # create the readme
    create_readme(readme_file_path, 'csv', dataset)

    # create the zip file
    if File.exists?(readme_file_path) && File.exists?(codebook_file_path) && File.exists?(csv_file_path)
      create_zip(dataset, zip_file_path, [
          {file_name: @readme_file, file_path: readme_file_path},
          {file_name: @codebook_file, file_path: codebook_file_path},
          {file_name: csv_file, file_path: csv_file_path}
        ]
      )
    end

    # record the path to the file in the dataset
    if is_admin
      @urls[:admin_csv][dataset.current_locale] = "#{dataset.admin_data_download_path}/#{dataset.current_locale}/#{zip_name}"
    else
      @urls[:csv][dataset.current_locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/#{zip_name}"
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to create the csv file, is admin = #{is_admin}"
    return nil
  end



  #########################################
  #########################################
  # create spss file
  # notes
  # - strings cannot be more than 60 chars
  def self.spss(dataset, use_processed_csv=false)
    puts '>>>>>>>>>>>>>>> creating spss'
    start = Time.now

    csv_file = "spss.csv"
    csv_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{csv_file}"


    # create the public files
    generate_spss(dataset, use_processed_csv)

    # create the admin files
    generate_spss(dataset, use_processed_csv, true)

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the spss and csv files"
    return nil
  end


  # create spss file
  # notes
  # - strings cannot be more than 60 chars
  def self.generate_spss(dataset, use_processed_csv=false, is_admin=false)
    puts ">>> generating spss, is admin = #{is_admin}"
    start = Time.now

    output = ''

    questions = is_admin ? dataset.questions : dataset.questions.for_download
    codebook_file_path = is_admin ? @admin_codebook_file_path : @codebook_file_path
    download_path = is_admin ? @admin_dataset_download_path : @dataset_download_path
    staging_path = is_admin ? @admin_dataset_download_staging_path : @dataset_download_staging_path

    csv_file = "spss.csv"
    spss_file = 'spss.sps'
    zip_name = "spss.zip"
    readme_name = "readme_spss.doc"
    spss_file_path = "#{staging_path}/#{dataset.current_locale}/#{spss_file}"
    csv_file_path = "#{staging_path}/#{dataset.current_locale}/#{csv_file}"
    readme_file_path = "#{staging_path}/#{dataset.current_locale}/#{readme_name}"
    zip_file_path = "#{download_path}/#{dataset.current_locale}/#{zip_name}"


    if !File.exists?(spss_file_path) || dataset.reset_download_files?
      #######################
      ## create spss file
      puts "- creating spss file"

      # add title
      output << "TITLE \"#{shorten_text(dataset.title)}\".\n\n"

      # add data list file line
      output << "***********************************"
      output << "\n"
      output << '* IMPORTANT: you must update the path to the file to include the full path (e.g., C:\Desktop\...).'
      output << "\n"
      output << "***********************************"
      output << "\n"
      output << "DATA LIST FILE= \"#{csv_file}\"  free (\",\")\n"


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
        output << shorten_text(clean_text(question.text))
        # output << question.original_code
        output << "\" \n"
      end
      output << " . \n\n"


      # add value labels (answer)
      output << "VALUE LABELS \n"
      questions.each do |question|
        answers = is_admin ? question.answers : question.answers.all_for_analysis
        if answers.present?
          output << "/ \n"
          output << question.original_code
          output << " \n"
          answers.each do |answer|
            output << ' ' # not needed - just to make it easier to read
            output << answer.value
            output << ' "'
            output << shorten_text(clean_text(answer.text))
            output << "\" \n"
          end
        end
      end
      output << " . \n\n"


      # finish the file
      output << 'EXECUTE.'

      # write out spss file
      File.open(spss_file_path, 'w') {|f| f.write(output) }
    end

    #######################
    # create csv file
    if !File.exists?(csv_file_path) || dataset.reset_download_files?
      if use_processed_csv
        puts "- copying processed csv file to #{csv_file_path}"
        copy_processed_csv(csv_file_path)
      else
        puts "- creating csv file with raw data and no header"
        copy_csv_file(csv_file_path, is_admin)
      end
    end

    # create the readme
    create_readme(readme_file_path, 'spss', dataset)

    # create the zip file
    if File.exists?(readme_file_path) && File.exists?(codebook_file_path) && File.exists?(csv_file_path) && File.exists?(spss_file_path)
      create_zip(dataset, zip_file_path, [
          {file_name: @readme_file, file_path: readme_file_path},
          {file_name: @codebook_file, file_path: codebook_file_path},
          {file_name: csv_file, file_path: csv_file_path},
          {file_name: spss_file, file_path: spss_file_path}
        ]
      )
    end

    # record the path to the file in the dataset
    if is_admin
      @urls[:admin_spss][dataset.current_locale] = "#{dataset.admin_data_download_path}/#{dataset.current_locale}/#{zip_name}"
    else
      @urls[:spss][dataset.current_locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/#{zip_name}"
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to create the spss and csv files, is admin = #{is_admin}"
    return nil
  end


  #########################################
  #########################################
  # create stata file
  # notes:
  # if provide the automatic flag, stata will automatically create the variable values
  # you tell stata that the variable has unique values by add ':name_fmt' after question code
  # create labels:
      # label define sexfmt 0 "Male" 1 "Female"
      # infile str16 name sex:sexfmt age using persons
  def self.stata(dataset, use_processed_csv=false)
    puts '>>>>>>>>>>>>>>> creating stata'
    start = Time.now

    csv_file = "stata.csv"
    csv_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{csv_file}"

    # create the public files
    generate_stata(dataset, use_processed_csv)

    # create the admin files
    generate_stata(dataset, use_processed_csv, true)

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the stata and csv files"
    return nil
  end

  # create stata file
  # notes:
  # if provide the automatic flag, stata will automatically create the variable values
  # you tell stata that the variable has unique values by add ':name_fmt' after question code
  # create labels:
      # label define sexfmt 0 "Male" 1 "Female"
      # infile str16 name sex:sexfmt age using persons
  def self.generate_stata(dataset, use_processed_csv=false, is_admin=false)
    puts ">>> creating stata, is_admin = #{is_admin}"
    start = Time.now

    output = ''

    questions = is_admin ? dataset.questions : dataset.questions.for_download
    codebook_file_path = is_admin ? @admin_codebook_file_path : @codebook_file_path
    download_path = is_admin ? @admin_dataset_download_path : @dataset_download_path
    staging_path = is_admin ? @admin_dataset_download_staging_path : @dataset_download_staging_path

    csv_file = "stata.csv"
    stata_file = "stata.do"
    zip_name = "stata.zip"
    readme_name = "readme_stata.doc"
    stata_file_path = "#{staging_path}/#{dataset.current_locale}/#{stata_file}"
    csv_file_path = "#{staging_path}/#{dataset.current_locale}/#{csv_file}"
    readme_file_path = "#{staging_path}/#{dataset.current_locale}/#{readme_name}"
    zip_file_path = "#{download_path}/#{dataset.current_locale}/#{zip_name}"


    if !File.exists?(stata_file_path) || dataset.reset_download_files?
      #######################
        # create stata file
      puts "- creating stata file"
      output << '* IMPORTANT: you must update the path to the file at the end of the next line to include the full path (e.g., C:\Desktop\...)'
      output << "\n\n"
      # output << 'infile '
      output << 'insheet '
      questions.each do |question|
        output << question.original_code
        if question.has_code_answers
          output << ":#{question.original_code}_fmt"
        end
        output << ' '
      end
      output << " using  #{csv_file} "
      # output << " using  #{csv_file} , automatic "

      # write out stata file
      File.open(stata_file_path, 'w') {|f| f.write(output) }
    end

    #######################
    # create csv file
    if !File.exists?(csv_file_path) || dataset.reset_download_files?
      if use_processed_csv
        puts "- copying processed csv file"
        copy_processed_csv(csv_file_path)
      else
        puts "- creating csv file with text and no header"
        copy_csv_file(csv_file_path, is_admin, with_raw_data: false)
      end
    end

    # create the readme
    create_readme(readme_file_path, 'stata', dataset)

    # create the zip file
    if File.exists?(readme_file_path) && File.exists?(codebook_file_path) && File.exists?(csv_file_path) && File.exists?(stata_file_path)
      create_zip(dataset, zip_file_path, [
          {file_name: @readme_file, file_path: readme_file_path},
          {file_name: @codebook_file, file_path: codebook_file_path},
          {file_name: csv_file, file_path: csv_file_path},
          {file_name: stata_file, file_path: stata_file_path}
        ]
      )
    end

    # record the path to the file in the dataset
    if is_admin
      @urls[:admin_stata][dataset.current_locale] = "#{dataset.admin_data_download_path}/#{dataset.current_locale}/#{zip_name}"
    else
      @urls[:stata][dataset.current_locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/#{zip_name}"
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to create the stata and csv files, is admin = #{is_admin}"
    return nil
  end


  #########################################
  #########################################
  # create r file that reads in csv file
  def self.r(dataset, use_processed_csv=false)
    puts '>>>>>>>>>>>>>>> creating r'
    start = Time.now

    csv_file = "r.csv"
    csv_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{csv_file}"

    # create the public files
    generate_r(dataset, use_processed_csv)

    # create the admin files
    generate_r(dataset, use_processed_csv, true)


    puts "-- it took #{(Time.now-start).round(3)} seconds to create the r and csv files"
    return nil
  end


  #########################################
  #########################################
  # create r file that reads in csv file
  def self.generate_r(dataset, use_processed_csv=false, is_admin=false)
    puts ">>> generating r, is admin = #{is_admin} "
    start = Time.now

    output = ''

    questions = is_admin ? dataset.questions : dataset.questions.for_download
    codebook_file_path = is_admin ? @admin_codebook_file_path : @codebook_file_path
    download_path = is_admin ? @admin_dataset_download_path : @dataset_download_path
    staging_path = is_admin ? @admin_dataset_download_staging_path : @dataset_download_staging_path

    csv_file = "r.csv"
    r_file = 'r.r'
    zip_name = "r.zip"
    readme_name = "readme_r.doc"
    r_file_path = "#{staging_path}/#{dataset.current_locale}/#{r_file}"
    csv_file_path = "#{staging_path}/#{dataset.current_locale}/#{csv_file}"
    readme_file_path = "#{staging_path}/#{dataset.current_locale}/#{readme_name}"
    zip_file_path = "#{download_path}/#{dataset.current_locale}/#{zip_name}"


    if !File.exists?(r_file_path) || dataset.reset_download_files?
      #######################
      # create r file
      puts "- creating r file"
      output << '#! /usr/bin/env Rscript'
      output << "\n\n"
      output << "###########################"
      output << "\n"
      output << "# IMPORTANT: update the setwd line below to the directory where the csv file is located"
      output << "\n"
      output << "###########################"
      output << "\n"
      output << "setwd(\".\")"
      output << "\n\n"
      output << "# read in the csv file to a variable called 'data'"
      output << "\n"
      output << "data <- read.csv('#{csv_file}', header=TRUE)"
      output << "\n\n"
      output << "# quit"
      output << "\n"
      output << "q()"


      # write out r file
      File.open(r_file_path, 'w') {|f| f.write(output) }
    end

    #######################
    # create csv file
    if !File.exists?(csv_file_path) || dataset.reset_download_files?
      if use_processed_csv
        puts "- copying processed csv file"
        copy_processed_csv(csv_file_path)
      else
        puts "- creating csv file with text and header code"
        copy_csv_file(csv_file_path, is_admin, with_raw_data: false, with_header_code_only: true)
      end
    end

    # create the readme
    create_readme(readme_file_path, 'r', dataset)

    # create the zip file
    if File.exists?(readme_file_path) && File.exists?(codebook_file_path) && File.exists?(csv_file_path) && File.exists?(r_file_path)
      create_zip(dataset, zip_file_path, [
          {file_name: @readme_file, file_path: readme_file_path},
          {file_name: @codebook_file, file_path: codebook_file_path},
          {file_name: csv_file, file_path: csv_file_path},
          {file_name: r_file, file_path: r_file_path}
        ]
      )
    end

    # record the path to the file in the dataset
    if is_admin
      @urls[:admin_r][dataset.current_locale] = "#{dataset.admin_data_download_path}/#{dataset.current_locale}/#{zip_name}"
    else
      @urls[:r][dataset.current_locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/#{zip_name}"
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to create the r and csv files, is admin = #{is_admin}"
    return nil
  end


  #########################################
  #########################################
  #########################################
  #########################################

  def self.clean_text(text)
    if !text.nil?
      x = text.gsub('\\n', ' ').gsub('\\r', ' ').strip
      if x.present?
        return x
      end
    end
    return nil
  end

  def self.shorten_text(text)
    if text.length > 50
      return text[0..50]
    end
    return text
  end

  #########################################
  #########################################

  # build csv headers for both public and admin downloads
  # for both code and code-text
  # values are stored in @headers hash
  def self.build_csv_headers(dataset)
    puts ">>>> building csv header"
    start = Time.now

    # to store the csv headers
    @headers = {code: {admin: [], public: []}, text: {admin: [], public: []}}

    # get the index to the questions that can be downloaded (public)
    public_indexes = dataset.questions.each_index.select{|i| dataset.questions[i].can_download?}

    dataset.questions.each_with_index do |question, index|
      @headers[:code][:admin] << question.original_code
      @headers[:text][:admin] << "#{question.original_code} - #{question.text}"
      if public_indexes.include?(index)
        @headers[:code][:public] << @headers[:code][:admin].last
        @headers[:text][:public] << @headers[:text][:admin].last
      end
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to build the csv headers"
    return nil
  end

  # build raw csv files for both public and admin downloads
  # for both raw data and text data
  # these files will then be copied and used when generating the csv files for csv, spss, stata, r
  def self.build_csv_files(dataset)
    puts ">>>> build_csv_files"
    start = Time.now

    csv_data = {raw: {admin: [], public: []}, text: {admin: [], public: []}}

    # get the index to the questions that can be downloaded (public)
    public_indexes = dataset.questions.each_index.select{|i| dataset.questions[i].can_download?}

    dataset.questions.each_with_index do |question, index|
      # raw data
      csv_data[:raw][:admin] << dataset.data_items.code_data(question.code)
      if public_indexes.include?(index)
        csv_data[:raw][:public] << csv_data[:raw][:admin].last
      end

      # text data
      csv_data[:text][:admin] << dataset.data_items.code_data(question.code)
      # now replace data values with answer text
      question.answers.sorted.each do |answer|
        csv_data[:text][:admin].last.select{ |x| x == answer.value }.each{ |x| x.replace( answer.text ) }
      end
      # clean the text
      csv_data[:text][:admin].last.each do |x|
        x.replace(clean_text(x)) if x.present?
      end

      # now add to public if needed
      if public_indexes.include?(index)
        csv_data[:text][:public] << csv_data[:text][:admin].last
      end

    end

    #######
    # now create csv files
    CSV.open(@csv_raw_data_file_path, 'w') do |csv|
      csv_data[:raw][:public].transpose.each do |row|
        csv << row
      end
    end
    CSV.open(@admin_csv_raw_data_file_path, 'w') do |csv|
      csv_data[:raw][:admin].transpose.each do |row|
        csv << row
      end
    end
    CSV.open(@csv_text_data_file_path, 'w') do |csv|
      csv_data[:text][:public].transpose.each do |row|
        csv << row
      end
    end
    CSV.open(@admin_csv_text_data_file_path, 'w') do |csv|
      csv_data[:text][:admin].transpose.each do |row|
        csv << row
      end
    end


    csv_data = nil

    puts "--- it took #{(Time.now-start).round(3)} seconds to build the csv files"
    return nil
  end

  #########################################
  #########################################

  # build csv for both public and admin downloads
  # return hash with admin array and public array
  def self.build_csv(dataset, options={})
    with_raw_data = options[:with_raw_data].nil? ? true : options[:with_raw_data]
    with_header = options[:with_header].nil? ? false : options[:with_header]
    with_header_code_only = options[:with_header_code_only].nil? ? false : options[:with_header_code_only]

    data = {admin: [], public: []}
    header = {admin: [], public: []}
    csv = {admin: [], public: []}
    csv_data = {admin: [], public: []}

    if dataset.present? && dataset.questions.present?
      # get the index to the questions that can be downloaded (public)
      public_indexes = dataset.questions.each_index.select{|i| dataset.questions[i].can_download?}

      #######
      # if header/data has already been built once, just use it again
      have_header = false
      have_data = false
      if @header_code.present? && with_header_code_only
        puts "*** using existing header with code"
        header[:public] = @header_code[:public]
        header[:admin] = @header_code[:admin]
        have_header = true
      elsif @header_text.present? && !with_header_code_only
        puts "*** using existing header with text"
        header[:public] = @header_text[:public]
        header[:admin] = @header_text[:admin]
        have_header = true
      end

      if @csv_raw_data.present? && with_raw_data
        puts "*** using existing data with code"
        csv_data[:admin] = @csv_raw_data[:admin]
        csv_data[:public] = @csv_raw_data[:public]
        have_data = true
      elsif @csv_text_data.present? && !with_raw_data
        puts "*** using existing data with text"
        csv_data[:admin] = @csv_text_data[:admin]
        csv_data[:public] = @csv_text_data[:public]
        have_data = true
      end

      #######
      # if not have header yet, create it
      if !have_header && (with_header || with_header_code_only)
        puts "---- building header"
        @header_code = {admin: [], public: []}
        @header_text = {admin: [], public: []}

        dataset.questions.each_with_index do |question, index|
          if with_header_code_only
            header[:admin] << question.original_code
            @header_code[:admin] << header[:admin].last
            if public_indexes.include?(index)
              header[:public] << header[:admin].last
              @header_code[:public] << header[:admin].last
            end
          else
            header[:admin] << "#{question.original_code} - #{question.text}"
            @header_text[:admin] << header[:admin].last
            if public_indexes.include?(index)
              header[:admin] << header[:admin].last
              @header_text[:public] << header[:admin].last
            end
          end
        end
      end

      #######
      # if not have data yet, create it
      if !have_data
        puts "---- building data"
        dataset.questions.each_with_index do |question, index|
          if with_raw_data
            puts "--->> getting csv raw data for #{question.code}"
            # use the data values
            data[:admin] << dataset.data_items.code_data(question.code)
            if public_indexes.include?(index)
              data[:public] << data[:admin].last
            end
          else
            # replace the data values with the answer text
            puts "--->> getting csv text data for #{question.code}"
            # get original data
            question_data_admin = dataset.data_items.code_data(question.code)
            question_data_public = question_data_admin.present? ? question_data_admin.dup : nil

            # now replace data values with answer text
            question.answers.sorted.each do |answer|
              # only need to update the public if this answer is not excluded
              if public_indexes.include?(index) && !answer.exclude
                question_data_public.select{ |x| x == answer.value }.each{ |x| x.replace( answer.text ) }
              end
              question_data_admin.select{ |x| x == answer.value }.each{ |x| x.replace( answer.text ) }
            end

            data[:admin] << question_data_admin
            if public_indexes.include?(index)
              data[:public] << question_data_public
            end
          end
        end

        puts "data admin length = #{data[:admin].length}; dataset questions length = #{dataset.questions.length}"
        puts "data public length = #{data[:public].length}; public index length = #{public_indexes.length}"

        # now use transpose to get in proper format
        data[:admin].transpose.each do |row|
          csv_data[:admin] << row.map{|x|
            y = x.nil? || x.empty? ? nil : clean_text(x)
            y.present? ? y : nil
          }
        end

        data[:public].transpose.each do |row|
          csv_data[:public] << row.map{|x|
            y = x.nil? || x.empty? ? nil : clean_text(x)
            y.present? ? y : nil
          }
        end

        # save the data for quick use by other methods
        if with_raw_data
          @csv_raw_data[:public] = csv_data[:public]
          @csv_raw_data[:admin] = csv_data[:admin]
        else
          @csv_text_data[:public] = csv_data[:public]
          @csv_text_data[:admin] = csv_data[:admin]
        end
      end


      #######
      # admin csv
      csv[:admin] = CSV.generate do |csv_row|
        # add header
        if with_header_code_only || with_header
          csv_row << header[:admin]
        end

        # add data
        csv_data[:admin].each do |row|
          csv_row << row
        end
      end

      #######
      # public csv
      csv[:public] = CSV.generate do |csv_row|
        # add header
        if with_header_code_only || with_header
          csv_row << header[:public]
        end

        csv_data[:public].each do |row|
          csv_row << row
        end
      end
    end


    return csv
  end

  #########################################
  #########################################

  def self.create_readme(file_name, type, dataset)
    output = ''
    url_helpers = Rails.application.routes.url_helpers
    # it is possible that the dataset locale is not an app locale
    # if this is the case, use the current locale
    locale = I18n.available_locales.include?(dataset.current_locale.to_sym) ? dataset.current_locale : I18n.locale
    # if the dataset is public, use the public url, else the admin one
    url = dataset.public? ? url_helpers.explore_data_dashboard_url(locale: locale, id: dataset.slug) : url_helpers.dataset_url(locale: I18n.locale, id: dataset.slug)
    # if the urls updated_at does not exist, use the dataset updated_at
    date = dataset.urls.updated_at.present? ? dataset.urls.updated_at : dataset.updated_at

    if !File.exists?(file_name) || dataset.reset_download_files?
      puts '- creating readme'
      # heading
      output << I18n.t('export_data.dataset', title: dataset.title)
      output << "\n"
      if dataset.slug.present?
        output << I18n.t('export_data.download_from', app_name: I18n.t("app.common.#{@app_key_name}.app_name"), url: url)
        output << "\n"
      end
      output << I18n.t('export_data.last_update', date: I18n.l(date, format: :long))
      output << "\n\n\n"

      case type
        when 'codebook'
          output << I18n.t('export_data.instructions.codebook')
        when 'csv'
          output << I18n.t('export_data.instructions.csv',
                    codebook: I18n.t('export_data.instructions.codebook'),
                    csv: I18n.t('export_data.instructions.csv_main'))
        when 'spss'
          output << I18n.t('export_data.instructions.spss',
                    codebook: I18n.t('export_data.instructions.codebook'),
                    csv: I18n.t('export_data.instructions.csv_main'))
        when 'stata'
          output << I18n.t('export_data.instructions.stata',
                    codebook: I18n.t('export_data.instructions.codebook'),
                    csv: I18n.t('export_data.instructions.csv_main'))
        when 'r'
          output << I18n.t('export_data.instructions.r',
                    codebook: I18n.t('export_data.instructions.codebook'),
                    csv: I18n.t('export_data.instructions.csv_main'))
      end

      # write the file
      File.open(file_name, 'w') {|f| f.write(output) }
    end
  end

  #########################################
  #########################################


  # create a zip file with the files provided
  # - files is an array of hash: {file_name, file_path}
  #   where file_name is the name to use for the file in the zip
  def self.create_zip(dataset, zip_file_path, files=[])

    FileUtils.rm zip_file_path if dataset.reset_download_files? && File.exists?(zip_file_path)

    if !File.exists?(zip_file_path)
      puts "- creating zip"
      # zip the files and move to the main folder
      ZipRuby::Archive.open(zip_file_path, ZipRuby::CREATE) do |zipfile|
        title = dataset.title.to_ascii.gsub(/[\\ \/ \: \* \? \" \< \> \| \, \. ]/,'')
        zipfile.add_dir(title)
        files.each do |file|
          # args: file name (with directory), source
          zipfile.add_file("#{title}/#{file[:file_name]}", file[:file_path])
        end
      end
    end
  end


  # copy the original processed csv file to the one passed in
  def self.copy_processed_csv(csv_file_path)
    FileUtils.cp @processed_file_path, csv_file_path if File.exists?(@processed_file_path)
  end


  # copy the appropriate csv file and add header if needed
  def self.copy_csv_file(csv_file_path, is_admin, options={})
    puts ">>>> copy csv file"

    start = Time.now

    with_raw_data = options[:with_raw_data].nil? ? true : options[:with_raw_data]
    with_header = options[:with_header].nil? ? false : options[:with_header]
    with_header_code_only = options[:with_header_code_only].nil? ? false : options[:with_header_code_only]

    # determine which file to copy from
    orig_csv_file = if is_admin
      with_raw_data == true ? @admin_csv_raw_data_file_path : @admin_csv_text_data_file_path
    else
      with_raw_data == true ? @csv_raw_data_file_path : @csv_text_data_file_path
    end
    headers = nil
    if with_header || with_header_code_only
      if is_admin
        headers = with_header_code_only == true ? @headers[:code][:admin] : @headers[:text][:admin]
      else
        headers = with_header_code_only == true ? @headers[:code][:public] : @headers[:text][:public]
      end
    end

    # if file exists, continue
    if orig_csv_file.present? && File.exists?(orig_csv_file)
      # if header is needed, add it
      if headers.present?
        puts "---> adding headers to csv file"
        CSV.open(csv_file_path, "w") do |csv|
          csv << headers
          CSV.foreach(orig_csv_file, 'r') do |row|
            csv << row
          end
        end
      else
        FileUtils.cp orig_csv_file, csv_file_path
      end
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to copy the csv file"
    return nil
  end


  #########################################
  #########################################
  ## mongoid does not detect a change in value if updating a translation locale like: x.title_translations['en'] = 'title'
  ## instead, you have replace the entire translations attribute
  ## and that is what these functions are for
  ## the first one saves the exisitng values locally
  ## then after the local values are updated, the urls object is updated

  def self.get_url_params(dataset)
    @urls = {codebook: {}, csv: {}, r: {}, spss: {}, stata: {}, admin_codebook: {}, admin_csv: {}, admin_r: {}, admin_spss: {}, admin_stata: {}}
    @urls[:codebook] = dataset.urls.codebook_translations.dup if dataset.urls.codebook_translations.present?
    @urls[:csv] = dataset.urls.csv_translations.dup if dataset.urls.csv_translations.present?
    @urls[:r] = dataset.urls.r_translations.dup if dataset.urls.r_translations.present?
    @urls[:spss] = dataset.urls.spss_translations.dup if dataset.urls.spss_translations.present?
    @urls[:stata] = dataset.urls.stata_translations.dup if dataset.urls.stata_translations.present?

    @urls[:admin_codebook] = dataset.urls.admin_codebook_translations.dup if dataset.urls.admin_codebook_translations.present?
    @urls[:admin_csv] = dataset.urls.admin_csv_translations.dup if dataset.urls.admin_csv_translations.present?
    @urls[:admin_r] = dataset.urls.admin_r_translations.dup if dataset.urls.admin_r_translations.present?
    @urls[:admin_spss] = dataset.urls.admin_spss_translations.dup if dataset.urls.admin_spss_translations.present?
    @urls[:admin_stata] = dataset.urls.admin_stata_translations.dup if dataset.urls.admin_stata_translations.present?
  end

  def self.set_url_params(dataset)
    dataset.urls.codebook_translations = @urls[:codebook] if @urls[:codebook].present?
    dataset.urls.csv_translations = @urls[:csv] if @urls[:csv].present?
    dataset.urls.r_translations = @urls[:r] if @urls[:r].present?
    dataset.urls.spss_translations = @urls[:spss] if @urls[:spss].present?
    dataset.urls.stata_translations = @urls[:stata] if @urls[:stata].present?

    dataset.urls.admin_codebook_translations = @urls[:admin_codebook] if @urls[:admin_codebook].present?
    dataset.urls.admin_csv_translations = @urls[:admin_csv] if @urls[:admin_csv].present?
    dataset.urls.admin_r_translations = @urls[:admin_r] if @urls[:admin_r].present?
    dataset.urls.admin_spss_translations = @urls[:admin_spss] if @urls[:admin_spss].present?
    dataset.urls.admin_stata_translations = @urls[:admin_stata] if @urls[:admin_stata].present?
  end



  def self.set_global_vars
    # @app_key_name = 'xtraktr'
    @app_key_name = 'unicef'

    # set file name to appear in zip file
    @readme_file = 'README.doc'
    @codebook_file = 'codebook.doc'
    @csv_raw_data_file = 'csv_raw_data.csv'
    @csv_text_data_file = 'csv_text_data.csv'

  end


  def self.set_dataset_file_paths(dataset)
    # folder paths for public and admin files
    @dataset_download_path = "#{Rails.public_path}#{dataset.data_download_path}"
    @dataset_download_staging_path = "#{Rails.public_path}#{dataset.data_download_staging_path}"
    @admin_dataset_download_path = "#{Rails.public_path}#{dataset.admin_data_download_path}"
    @admin_dataset_download_staging_path = "#{Rails.public_path}#{dataset.admin_data_download_staging_path}"

    # path to the processed csv file
    @processed_file_path = "#{Rails.public_path}/system/datasets/#{dataset.id}/processed/data.csv"

    # make sure path exists
    FileUtils.mkpath("#{@dataset_download_path}/#{dataset.current_locale}")
    FileUtils.mkpath("#{@dataset_download_staging_path}/#{dataset.current_locale}")
    FileUtils.mkpath("#{@admin_dataset_download_path}/#{dataset.current_locale}")
    FileUtils.mkpath("#{@admin_dataset_download_staging_path}/#{dataset.current_locale}")

    # set path to codebook here since used in all methods
    @codebook_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{@codebook_file}"
    @admin_codebook_file_path = "#{@admin_dataset_download_staging_path}/#{dataset.current_locale}/#{@codebook_file}"
    @csv_raw_data_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{@csv_raw_data_file}"
    @csv_text_data_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{@csv_text_data_file}"
    @admin_csv_raw_data_file_path = "#{@admin_dataset_download_staging_path}/#{dataset.current_locale}/#{@csv_raw_data_file}"
    @admin_csv_text_data_file_path = "#{@admin_dataset_download_staging_path}/#{dataset.current_locale}/#{@csv_text_data_file}"
  end


end
