module HelpArticlesHelper
  def display_truncated_content(content)
    truncate(
      strip_tags(content),
      length: 300
    ).html_safe
  end
  
  def create_help_article_detail(label, value)
    <<-Detail
      <span class='help-article-detail-label'>
        #{label}:
      </span> 
      <span class='help-article-detail-value'>
        #{value}
      </span>
    Detail
  end
end