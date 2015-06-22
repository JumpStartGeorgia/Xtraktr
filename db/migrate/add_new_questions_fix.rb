# the data for the answers added in 'add_new_questions' rake task added data as numbers, but should have been strings
# this rake tasks converst them all to strings

d = Dataset.find('youth')
di = d.data_items.with_code('res_age_group')
di.data = di.data.map{|x| x.to_s}
di.save


d = Dataset.find('violence-against-children')
di = d.data_items.with_code('a_aggr')
di.data = di.data.map{|x| x.to_s}
di.save

di = d.data_items.with_code('b_aggr')
di.data = di.data.map{|x| x.to_s}
di.save

di = d.data_items.with_code('c_aggr')
di.data = di.data.map{|x| x.to_s}
di.save

di = d.data_items.with_code('d_aggr')
di.data = di.data.map{|x| x.to_s}
di.save
