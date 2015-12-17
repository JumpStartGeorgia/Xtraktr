class Admin::HelpArticlesController < ApplicationController
  def index
    @help_articles = HelpArticle.all

    respond_to do |format|
      format.html
    end
  end
end
