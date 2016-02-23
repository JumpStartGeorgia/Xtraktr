class HelpArticlesController < ApplicationController
  def show
    @help_article = HelpArticle.find(params[:id])
  end
end