class Admin::HelpArticlesController < ApplicationController
  def index
    @help_articles = HelpArticle.sorted

    respond_to do |format|
      format.html
    end
  end

  def show
    @help_article = HelpArticle.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def new
    @help_article = HelpArticle.new

    prepare_form

    respond_to do |format|
      format.html
    end
  end

  def edit
    @help_article = HelpArticle.find(params[:id])

    prepare_form

    respond_to do |format|
      format.html
    end
  end

  def create
    @help_article = HelpArticle.new(params[:help_article])

    # if there are help_category_ids, create mapper objects with them
    params[:help_article][:help_category_ids].delete('')
    params[:help_article][:help_category_ids].each do |help_category_id|
      @help_article.help_category_mappers.build(
        help_category_id: help_category_id
      )
    end

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
        prepare_form

        format.html { render action: 'new' }
      end
    end
  end

  def update
    @help_article = HelpArticle.find(params[:id])

    respond_to do |format|
      if @help_article.update_attributes(params[:help_article])
        format.html do
          redirect_to admin_help_articles_path,
                      flash: {
                        success: t('app.msgs.success_updated',
                                   obj: t('mongoid.models.help_article.one'))
                      }
        end
      else
        prepare_form

        format.html { render action: 'edit' }
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

  private

  def initiate_form_js
    @js.push('help_articles.js')
  end

  def prepare_form
    initiate_form_js
    set_tabbed_translation_form_settings
  end
end
