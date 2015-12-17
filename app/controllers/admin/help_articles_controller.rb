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

  def edit
    @help_article = HelpArticle.find(params[:id])

    set_tabbed_translation_form_settings

    respond_to do |format|
      format.html
    end
  end

  def create
    @help_article = HelpArticle.new(params[:help_article])

    respond_to do |format|
      if @help_article.save
        format.html do
          redirect_to admin_help_articles_path,
                      flash: {
                        success: t('app.msgs.success_created',
                                   obj: t('mongoid.models.help_article.one'))
                      }
        end
      else
        set_tabbed_translation_form_settings

        format.html { render action: 'new' }
      end
    end
  end

  def destroy
    @help_article = HelpArticle.find(params[:id])
    @help_article.destroy

    respond_to do |format|
      format.html do
        redirect_to admin_help_articles_path,
                    flash: {
                      success:  t('app.msgs.success_deleted',
                                  obj: t('mongoid.models.help_article.one'))
                    }
      end
    end
  end
end
