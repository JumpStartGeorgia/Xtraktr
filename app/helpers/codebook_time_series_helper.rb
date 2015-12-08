module CodebookTimeSeriesHelper

  # generate the options for the codebook group jumpto select field
  def generate_codebook_time_series_group_options(groups)
    html_options = ''

    groups.each do |group|
      html_options << generate_codebook_time_series_group_option(group)
      group.arranged_items.select{|x| x.class == TimeSeriesGroup}.each do |subgroup|
        html_options << generate_codebook_time_series_group_option(subgroup)
      end
    end

    return html_options.html_safe
  end


  # generate the ul list of codebook groups and questions
def generate_codebook_time_series_list(items)
    html = '<ul class="list-unstyled">'

    items.each do |item|

      if item.class == TimeSeriesGroup
        # add group
        html << generate_codebook_time_series_group_item(item)

      elsif item.class == TimeSeriesQuestion
        # add question
        html << generate_codebook_time_series_question_item(item)
      end

    end

    html << '</ul>'

    return html.html_safe
  end

private

  # create option for codebook group jumpto
  def generate_codebook_time_series_group_option(group)
    cls = group.parent_id.present? ? 'subgroup' : 'group'
    content = 'data-content=\'<span>' + group.title + '</span><span class="right-icons">'
    desc = group.description.present? ? group.description : I18n.t('app.msgs.jumpto_group')
    if group.parent_id.present?
      content << subgroup_icon(desc)
    else
      content << group_icon(desc)
    end
    content << '</span>\''

    return "<option value='#{group.id}' class='#{cls}' #{content}>#{group.title}</option>"
  end


  # create question for codebook
  # - options: group, subgroup
  def generate_codebook_time_series_question_item(question, options={})

    return render partial: 'shared/codebook_time_series_question_item',
                  locals: {question: question, current_group: options[:group], current_subgroup: options[:subgroup]}
  end


  # create group for codebook
  def generate_codebook_time_series_group_item(group)
    html = ''
    cls = 'group-item'
    cls2 = ''
    cls3 = 'grouped-items'
    if group.parent_id.present?
      cls << ' subgroup'
      cls2 = ' subgroup'
      cls3 = 'subgrouped-items'
    end
    html << "<li class='#{cls}' data-id='#{group.id}'>"
    html << "<div class='question-group #{cls2}'>"
    html << "<span class='group-title'>#{group.title}</span>"
      if group.description.present?
        html << "<span class='group-description'>#{group.description}</span>"
      end
    html << '</div>'
    html << "<ul class='list-unstyled #{cls3}'>"

    options = {}
    options[:group] = group.parent_id.present? ? group.parent : group
    options[:subgroup] = group.parent_id.present? ? group : nil

    group.arranged_items.each do |item|

      if item.class == TimeSeriesGroup
        html << generate_codebook_time_series_group_item(item)
      elsif item.class == TimeSeriesQuestion
        html << generate_codebook_time_series_question_item(item, options)
      end

    end

    html << '</ul>'
    html << '</li>'

    return html
  end
end
