class Admin::HelpCategoriesController < ApplicationController
  before_filter :set_help_category, only: [:edit, :update, :destroy]

  respond_to :html

  def index
    @help_categories = HelpCategory.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def new
    @help_category = HelpCategory.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def edit
  end

  def create
    @help_category = HelpCategory.new(params[:help_category])

    respond_to do |format|
      if @help_category.save
        format.html do
          redirect_to admin_help_categories_path,
                      flash: {
                        success: t('app.msgs.success_created',
                                   obj: t('mongoid.models.help_category.one'))
                      }
        end
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    @help_category = HelpCategory.find(params[:id])

    respond_to do |format|
      if @help_category.update_attributes(params[:help_category])
        format.html do
          redirect_to admin_help_categories_path,
                      flash: {
                        success: t('app.msgs.success_updated',
                                   obj: t('mongoid.models.help_category.one'))
                      }
        end
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @help_category = HelpCategory.find(params[:id])
    @help_category.destroy

    respond_to do |format|
      format.html do
        redirect_to admin_help_categories_path,
                    flash: {
                      success:  t('app.msgs.success_deleted',
                                  obj: t('mongoid.models.help_category.one'))
                    }
      end
    end
  end

  private
    def set_help_category
      @help_category = HelpCategory.find(params[:id])
    end
end
