# download files in txt format with utf-8 characters are not readable on windows for it opens in wordpad by default
# so change file extension to doc

require 'fileutils'

# first, just find all txt files and change to doc
Dir.glob("#{Rails.root}/public/system/datasets/**/data_download/**/*.txt").each do |f|
  FileUtils.mv f, "#{File.dirname(f)}/#{File.basename(f,'.*')}.doc"
end

# zip files need to be re-created so mark all datasets as needing to be recreted
Dataset.update_all(reset_download_files: true)
