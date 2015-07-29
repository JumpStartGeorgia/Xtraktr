# add sort order to groups and questions that do not have it
# use the index position + 1 as the sort order

Dataset.each do |d|
  puts "updating sort order for #{d.title}"

  # first add sort order to main groups, then go through each subgroup
  group_length = d.groups.main_groups.length
  d.groups.main_groups.each_with_index do |g, i|
    puts "- group #{g.title}"
    g.sort_order = i+1 if g.sort_order == 0
    # if group has subgroups add sort order to those too
    g.arranged_items(include_groups: true).each_with_index do |subgroup, isg|
      puts "-- subgroup #{subgroup.title}"
      subgroup.sort_order = isg+1 if subgroup.sort_order == 0
    end
  end

  # if there are groups, start the question index after the group indexes
  d.questions.each_with_index do |q, i|
    q.sort_order = i+1+group_length if q.sort_order.nil?
  end

  d.save
end