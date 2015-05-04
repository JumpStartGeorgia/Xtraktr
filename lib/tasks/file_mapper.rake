# scraper.rake
# encoding: UTF-8


class FileMapperTask
  def self.clean!
    puts "FileMapper table was cleaned"
    FileMapper.destroy_all(:created_at.lt => Time.zone.now.ago(180))
  end
end

namespace :filemapper do
  desc "Remove all records that are older than 3 minutes"
  task :clean => :environment do
    FileMapperTask.clean!
  end
end