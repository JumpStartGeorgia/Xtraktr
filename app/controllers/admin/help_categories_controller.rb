class Admin::HelpCategoriesController < ApplicationController
  before_filter :set_help_category, only: [:edit, :update, :destroy]

  respond_to :html

  def index
    @help_categories = HelpCategory.all
    respond_with(:admin, @help_categories)
  end

  def new
    @help_category = HelpCategory.new
    respond_with(:admin, @help_category)
  end

  def edit
  end

  def create
    @help_category = HelpCategory.new(params[:help_category])
    flash[:notice] = 'HelpCategory was successfully created.' if @help_category.save
    respond_with(:admin, @help_category)
  end

  def update
    flash[:notice] = 'HelpCategory was successfully updated.' if @help_category.update_attributes(params[:help_category])
    respond_with(:admin, @help_category)
  end

  def destroy
    @help_category.destroy
    respond_with(:admin, @help_category)
  end

  private
    def set_help_category
      @help_category = HelpCategory.find(params[:id])
    end
end
