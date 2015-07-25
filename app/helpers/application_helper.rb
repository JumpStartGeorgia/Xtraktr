module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title.html_safe }
  end

  def subnav_left(text)
    content_for(:subnav_left) { text.html_safe }
  end

	def flash_translation(level)
    case level
    when :info then "alert-warning"
    when :notice then "alert-info"
    when :success then "alert-success"
    when :error then "alert-danger"
    when :alert then "alert-danger"
    end
  end

  def notification_translation(state)
    ['success', 'error', 'info'].index(state.to_s).present? ? state : 'info'
  end

	# from http://www.kensodev.com/2012/03/06/better-simple_format-for-rails-3-x-projects/
	# same as simple_format except it does not wrap all text in p tags
	def simple_format_no_tags(text, html_options = {}, options = {})
		text = '' if text.nil?
		text = smart_truncate(text, options[:truncate]) if options[:truncate].present?
		text = sanitize(text) unless options[:sanitize] == false
		text = text.to_str
		text.gsub!(/\r\n?/, "\n")                    # \r\n and \r -> \n
#		text.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') # 1 newline   -> br
		text.html_safe
	end

  def current_url
    "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
  end
  
	def full_url(path)
		"#{request.protocol}#{request.host_with_port}#{path}"
	end

	# put the default locale first and then sort the remaining locales
	def locales_sorted
    x = I18n.available_locales.dup
    
    # sort
    x.sort!{|x,y| x <=> y}

    # move default locale to first position
    default = x.index{|x| x == I18n.default_locale}
    if default.present? && default > 0
      x.unshift(x[default])
      x.delete_at(default+1)
    end

    return x
	end

  def format_languages(object)
    object.language_objects.map{|x| x.name}.join('<br /> ').html_safe
  end

  # apply the strip_tags helper and also convert nbsp to a ' '
  def strip_tags_nbsp(text)
    if text.present?
      strip_tags(text.gsub('&nbsp;', ' '))
    end
  end


  def format_public_status(is_public, small=false)
    css_small = small == true ? 'small-status' : ''
    if is_public == true
      return "<div class='publish-status public #{css_small}'>#{t('publish_status.public')}</div>".html_safe
    else
      return "<div class='publish-status not-public #{css_small}'>#{t('publish_status.private')}</div>".html_safe
    end
  end


  def format_boolean_flag(flag, small=false)
    css_small = small == true ? 'small-status' : ''
    if flag == true
      return "<div class='publish-status public #{css_small}'>#{t('formtastic.yes')}</div>".html_safe
    end
  end


  def link_to_sidebar path, name, klass='img '
    current = current_page?(path) || (path != root_path && request.path.index(path))
    link_to path, class: (current ? ' active' : '') do
      tt = t('app.menu.' + name)
      ('<div alt="' + tt + '" class="'+klass+'side-menu-' + name + '"></div>
      <span>' + tt + '</span>').html_safe      
    end
  end

  #devise mappings
  def resource_name
    :user
  end
 
  def resource
    @resource ||= User.new
  end
 
  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
  #devise mappings end
  

  def exclude_question_icon
    '<img src="/assets/svg/lock.svg" title="' + I18n.t('app.common.private_question') + '" />'
  end

  def exclude_answer_icon
    '<img src="/assets/svg/lock.svg" title="' + I18n.t('app.common.private_answer') + '" />'
  end

  def mappable_question_icon
    '<img src="/assets/svg/map.svg" title="' + I18n.t('app.common.mappable_question') + '" />'
  end

  def group_icon(description=nil)
    # title = description.present? ? "title=\'#{description}\'" : ''
    '<img src="/assets/svg/group.svg" title="' + (description.present? ? description.strip : '') + '" />'
  end

  def subgroup_icon(description=nil)
    # title = description.present? ? "title=\'#{description}\'" : ''
    '<img src="/assets/svg/subgroup.svg" title="' + (description.present? ? description.strip : '') + '" />'
  end


end