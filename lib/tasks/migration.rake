namespace :migration do
  desc "update shapeset records to use the localization fields"
  task :shapeset_localization => :environment do
    require "./db/migrate/shapeset_localization.rb"
  end
end