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

    # update help_category_mappers
    params[:help_article][:help_category_ids].delete('')
    cat_ids = @help_article.help_category_mappers.help_category_ids.map{|x| x.to_s}
    mappers_to_delete = []
    if params[:help_article][:help_category_ids].present?
      # if mapper help_category is not in list, mark for deletion
      @help_article.help_category_mappers.each do |mapper|
        if !params[:help_article][:help_category_ids].include?(mapper.help_category_id.to_s)
          mappers_to_delete << mapper.id
        end
      end
      # if cateogry id not in mapper, add id
      params[:help_article][:help_category_ids].each do |help_category_id|
        if !cat_ids.include?(help_category_id)
          @help_article.help_category_mappers.build(help_category_id: help_category_id)
        end
      end
    else
      # no categories so make sure mapper is nil
      @help_article.help_category_mappers.each do |mapper|
        mappers_to_delete << mapper.id
      end
    end

    # if any mappers are marked as destroy, destroy them
    HelpCategoryMapper.in(id: mappers_to_delete).destroy_all

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
