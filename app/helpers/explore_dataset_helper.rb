module ExploreDatasetHelper

  # generate the options for the explore data drop down list
  def generate_explore_dataset_options(items, dataset, options={})
    skip_content = options[:skip_content].nil? ? false : options[:skip_content]
    selected_code = options[:selected_code].nil? ? nil : options[:selected_code]
    disabled_code = options[:disabled_code].nil? ? nil : options[:disabled_code]
    disabled_code2 = options[:disabled_code2].nil? ? nil : options[:disabled_code2]
    group_type = options[:group_type].nil? ? nil : options[:group_type]
    only_categorical = options[:only_categorical].nil? ? false : options[:only_categorical]

    html = ''

    items.each do |item|

      if item.class == Group
        # add group
        html << generate_explore_dataset_group_option(item)

        # if have items, add them
        options[:group_type] = group_type.present? ? 'subgroup' : 'group'
        html << generate_explore_dataset_options(item.arranged_items, dataset, options)

      elsif item.class == Question
        # add question
        if item.is_analysable? && !(only_categorical && item.data_type != Question::DATA_TYPE_VALUES[:categorical])
          html << generate_explore_dataset_question_option(item, dataset, skip_content, selected_code, disabled_code, disabled_code2, group_type)
        end
      end
    end

    return html.html_safe
  end


  # determine if any of the selected questions have can_exclude answers
  def selected_dataset_question_has_can_exclude?(questions, select_values=[])
    has_can_exclude = false

    if select_values.present?
      x = questions.select{|x| select_values.include?(x.code)}.map{|x| x.has_can_exclude_answers}
      has_can_exclude = x.present? && x.include?(true)
    end

    return has_can_exclude
  end

private
  def generate_explore_dataset_group_option(group)
    html = ''
    content = ''
    cls = group.parent_id.present? ? 'subgroup' : 'group'
    g_text = group.title

    # if the question is mappable or is excluded, show the icons for this
    content = 'data-content=\'<span>' + g_text + '</span><span class="right-icons">'

    if group.parent_id.present?
      content << subgroup_icon(I18n.t('app.msgs.is_subgroup'))
    else
      content << group_icon(I18n.t('app.msgs.is_group'))
    end

    content << '</span>\''

    html << "<option class='#{cls}' disabled='disabled' #{content.html_safe}>#{g_text}</option>"

    return html
  end

  def generate_explore_dataset_question_option(question, dataset, skip_content, selected_code, disabled_code, disabled_code2, group_type=nil)
    html = ''
    q_text = h question.code_with_text
    selected = selected_code.present? && selected_code == question.code ? 'selected=selected ' : ''
    disabled = (disabled_code.present? && disabled_code == question.code) || (disabled_code2.present? && disabled_code2 == question.code) ? 'data-disabled=disabled ' : ''
    can_exclude = question.has_can_exclude_answers? ? 'data-can-exclude=true ' : ''
    cls = group_type == 'group' ? 'grouped' : group_type == 'subgroup' ? 'grouped subgrouped' : ''

    weights = ''
    if dataset.is_weighted? == true
      w = dataset.weights.for_question(question.code)
      if w.present?
        weights = 'data-weights=\'["'
        weights << w.map{|x| x.code}.join('","')
        weights << '"]\''
      end
    end
    # if the question is mappable or is excluded, show the icons for this
    content = ''
    if !skip_content || question.has_type? #&& (question.is_mappable? || question.exclude?)
      content << 'data-content=\'<span class="outer-layer"><span class="inner-layer"><span>' + q_text + '</span><span class="right-icons">'
      if question.has_type?
        content << question_data_type_icon(question.data_type)
      end

      if question.is_mappable?
        content << mappable_question_icon
      end

      if question.exclude?
        content << exclude_question_icon
      end

      content << '</span></span></span>\''

    end
    html << "<option class='#{cls}' value='#{question.code}' title='#{q_text}' #{selected} #{disabled} #{content.html_safe} #{can_exclude} #{weights} data-type='#{question.data_type}'>#{q_text}</option>"

    return html
  end

end
