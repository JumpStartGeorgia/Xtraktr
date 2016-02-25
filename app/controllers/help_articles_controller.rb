class HelpArticlesController < ApplicationController
  def show
    @css.push('help_article.css')
    @help_article = HelpArticle.find(params[:id])
  end
end