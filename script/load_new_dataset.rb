#### youth
d = Dataset.find('youth')
# delete all questions and data items
d.questions.destroy_all
d.data_items.destroy_all

# set new file and file extension
#f = "/home/jason/Projects/datasets/unicef datsets/Youth survey/data/Stata/Youth with age group.dta"
f = "/home/jason/Projects/datasets/unicef datsets/Youth survey/data/SPSS/All.sav"
d.datafile = File.open(f)
d.file_extension = 'dta'
d.save
d.reload

# process file
d.process_data_file

# save
d.save

##############
#### violence
d = Dataset.find('violence-against-children')
# delete all questions and data items
d.questions.destroy_all
d.data_items.destroy_all

# set new file and file extension
#f = "/home/jason/Projects/datasets/unicef\ datsets/Violence\ against\ children\ in\ Georgia/data/Violence\ with\ created\ variables\ for\ data\ platform.dta"
f = "/home/jason/Projects/datasets/unicef\ datsets/Violence\ against\ children\ in\ Georgia/data/Unicef_domestic violence_database.SAV"
d.datafile = File.open(f)
d.file_extension = 'dta'
d.save
d.reload

# process file
d.process_data_file

# save
d.save
