class Admin::HelpArticlesController < ApplicationController
  def index
    @help_articles = HelpArticle.all

    respond_to do |format|
      format.html
    end
  end

  def new
    @help_article = HelpArticle.new

    set_tabbed_translation_form_settings

    respond_to do |format|
      format.html
    end
  end
end
