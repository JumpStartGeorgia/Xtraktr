namespace :download_files do

  ##########################################################
  desc "mark all datasets as needing to have their download files re-created (cron job will actually do the re-creation)"
  task :recreate => :environment do |t, args|
    Dataset.all.each do |d|
      puts "setting flag for: #{d.title}"
      d.reset_download_files = true
      d.save
    end
  end
end