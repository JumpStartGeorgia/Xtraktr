module GroupsHelper

  # create options for select list for groups and their sub-groups
  # top level groups have class of top-level-group
  # sub groups have class of sub-groups
  def options_for_groups(groups, parent_id=nil, include_subgroups=false)
    options = ''

    if groups.present?
      groups.each do |top_level_group|
        selected = parent_id == top_level_group.id ? 'selected=\'selected\'' : ''
        options << '<option class=\'top-level-group\' value=\'' + top_level_group.id + '\' ' + selected + '>' + top_level_group.title + '</option>'
        
        if include_subgroups && groups.sub_groups.present?
          # found sub groups
          groups.sub_groups.each do |sub_group|
            selected = parent_id == sub_group.id ? 'selected=\'selected\'' : ''
            options << '<option class=\'sub-group\' value=\'' + sub_group.id + '\' ' + selected + '>' + sub_group.title + '</option>'
          end
        end
      end
    end

    return options.html_safe
  end

end
