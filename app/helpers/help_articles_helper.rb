module HelpArticlesHelper
  def display_truncated_content(content)
    truncate(
      strip_tags(content),
      length: 300
    ).html_safe
  end
end