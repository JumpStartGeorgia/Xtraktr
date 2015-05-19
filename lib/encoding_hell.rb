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

    # go through each row and try saving to see which works and which does not
    # (1..rows.length-1).each do |index|
    (1..10).each do |index|
      puts "------------------------"
      row = rows[index]

      puts "- index = #{index}; question = #{row[1]}"

      puts '-- en = ' + row[1]
      puts '-- ka = ' + row[2]

      # set the text
      I18n.locale = :en
      q = d.questions[index-1]
      q.text = d.clean_text(row[1])
      d.save
      d.reload

      I18n.locale = :ka
      q = d.questions[index-1]
      q.text = d.clean_text(row[2])
      d.save
      d.reload


      # see if actually saved
      q = d.questions[index-1]
      if (q.text_translations['en'] == row[1])
        puts "--> EN GOOD!"
      else
        puts "--> **** en not match"
      end
      if (q.text_translations['ka'] == row[2])
        puts "--> KA GOOD!"
      else
        puts "--> @@@@ ka not match"
      end

    end


    I18n.locale = :en
  end

end