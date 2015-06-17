class HighlightsController < ApplicationController
  before_filter :authenticate_user!, only: [:edit_description]
  before_filter only: [:edit_description] do |controller_instance|
    controller_instance.send(:valid_role?, @data_editor_role)
  end


  def get_description
    desc = nil
    highlight = Highlight.find_by(embed_id: params[:embed_id])    
    desc = highlight.description if highlight.present?

    respond_to do |format|
      format.json { 
        render json: {description: desc}
      }
    end
  end

  def edit_description
    @highlight = Highlight.find_by(embed_id: params[:embed_id])    


    respond_to do |format|
      format.json { 
        if @highlight.nil?
          render json: { success: false, message: I18n.t('app.msgs.error_while_save') } 
        elsif request.post?
          success = @highlight.update_attributes(params[:highlight])
          render json: { success: success, message: I18n.t('app.msgs.description_saved') } 
        else
          @languages = Language.sorted
          render json: { form: (render_to_string "highlights/_form", formats: 'html', :layout => false) } 
        end
      }
    end

  end

end