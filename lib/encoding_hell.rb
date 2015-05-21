# encoding: utf-8
module EncodingHell
  require 'csv'

  def self.run
    file = "/home/jason/Downloads/barrier\ questions\ take2.csv"

    if !File.exists? file
      puts "!!!!! file does not exist (#{file})"
      return
    end

    d = Dataset.find('551cf0022c17430337000002')

    if !d.present?
      puts "!!!!! dataset not found"
      return
    end


    # read in file
    rows = CSV.read(file)


    # first reset test to dummy text
    puts "------------------"
    puts "- reseting text data"
    (1..rows.length-1).each do |index|
      q = d.questions[index-1]

      # set the text
      I18n.locale = :en
      q.text = ('a'..'z').to_a.shuffle[0,8].join
      I18n.locale = :ka
      q.text = ('a'..'z').to_a.shuffle[0,8].join
    end

    d.save
    d.reload


    # # go through each row and try saving to see which works and which does not
    # # (1..rows.length-1).each do |index|
    # I18n.locale = :en
    # (3..5).each do |index|
    #   puts "------------------------"
    #   row = rows[index]

    #   puts "- index = #{index}"
    #   puts '-- en = ' + row[1]

    #   q = d.questions[index-1]
    #   q.text = d.clean_text(row[1].latinize)

    # end
    # d.save
    # d.reload

    # I18n.locale = :ka
    # (3..5).each do |index|
    #   puts "------------------------"
    #   row = rows[index]

    #   puts "- index = #{index}"
    #   puts '-- ka = ' + row[2]

    #   q = d.questions[index-1]
    #   q.text = d.clean_text(row[2].latinize)

    # end
    # d.save
    # d.reload

    # I18n.locale = :ka
    # (3..5).each do |index|
    #   puts "------------------------"
    #   row = rows[index]

    #   puts "- index = #{index}"
    #   puts '-- ka = ' + row[2]

    #   q = d.questions[index-1]
    #   q.text = d.clean_text(row[2].georgianize)

    # end
    # d.save
    # d.reload

    # puts "------------------------"
    # puts "------------------------"

    # # now check if save actuall occurred
    # (3..5).each do |index|
    #   puts "------------"
    #   puts "--> index #{index}"
    #   row = rows[index]
    #   q = d.questions[index-1]
    #   puts "--- #{q.text_translations['en']}"
    #   puts "--- #{row[1]}"
    #   puts "--- #{q.text_translations['ka']}"
    #   puts "--- #{row[2].latinize_georgianize}"
    #   if (q.text_translations['en'] == row[1])
    #     puts "--> EN GOOD!"
    #   else
    #     puts "--> **** en not match"
    #   end
    #   if (q.text_translations['ka'] == row[2].latinize_georgianize)
    #     puts "--> KA GOOD!"
    #   else
    #     puts "--> @@@@ ka not match"
    #   end
    # end    



    # go through each row and try saving to see which works and which does not
    # (1..rows.length-1).each do |index|
    (3..5).each do |index|
      puts "------------------------"
      row = rows[index]

      puts "- index = #{index}"

      # set the text
      I18n.locale = :en
      q = d.questions[index-1]
      q.text = d.clean_text(row[1])
      d.save
      d.reload

      I18n.locale = :ka
      q = d.questions[index-1]
      # q.text = d.clean_text((d.clean_text(row[2]).latinize(String::LANG_MAP_TO_GEO3)).georgianize(String::LANG_MAP_TO_GEO4))
      text = row[2].latinize(String::LANG_MAP1).georgianize(String::LANG_MAP2)
      q.text = text
      d.save
      d.reload


      # see if actually saved
      q = d.questions[index-1]
      puts "--- #{q.text_translations['en']}"
      puts "--- #{row[1]}"
      if (q.text_translations['en'] == row[1])
        puts "--> EN GOOD!"
      else
        puts "--> **** en not match"
      end

      puts "--- #{q.text_translations['ka']}"
      puts "--- #{row[2]}"
      puts "--- #{text}"
      if (q.text_translations['ka'] == text)
        puts "--> KA GOOD!"
      else
        puts "--> @@@@ ka not match"
      end
    end


    I18n.locale = :en
  end

end