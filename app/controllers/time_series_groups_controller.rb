class TimeSeriesGroupsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @data_editor_role)
  end

  # GET /groups
  # GET /groups.json
  def index
   @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @items = @time_series.arranged_items(include_questions: true, include_groups: true, include_subgroups: true)

      add_common_options(false)

      respond_to do |format|
        format.html
        format.js { render json: @items}
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_index_path(:locale => I18n.locale)
      return
    end
  end

  # # GET /groups/1
  # # GET /groups/1.json
  # def show
  #   @group = Group.find(params[:id])

  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.json { render json: @group }
  #   end
  # end

  # GET /groups/new
  # GET /groups/new.json
  def new
   @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @group = @time_series.groups.new

      add_common_options

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @group }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_index_path(:locale => I18n.locale)
      return
    end
  end

  # GET /groups/1/edit
  def edit
   @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @group = @time_series.groups.find(params[:id])

      add_common_options

    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_index_path(:locale => I18n.locale)
      return
    end
  end

  # POST /groups
  # POST /groups.json
  def create
   @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @group = @time_series.groups.new(params[:time_series_group])

      # check if group is valid
      # - if not, stop
      if @group.valid?
        # assign the group ids to the questions
        if params[:time_series].present? && params[:time_series][:time_series_questions_attributes].present?
          selected_ids = params[:time_series][:time_series_questions_attributes].select{|k,v| v[:selected] == 'true'}.map{|k,v| v[:id]}
          not_selected_ids = params[:time_series][:time_series_questions_attributes].select{|k,v| v[:selected] != 'true'}.map{|k,v| v[:id]}
        end
        # have to have subgroups or questions in order to be saved
        if (selected_ids.present? && selected_ids.length > 0) ||
            (not_selected_ids.present? && not_selected_ids.length > 0) ||
            @group.subgroups.length > 0
          if (selected_ids.present? && selected_ids.length > 0)
            @time_series.questions.assign_group(selected_ids, @group.id)
          end
          if (not_selected_ids.present? && not_selected_ids.length > 0)
            @time_series.questions.assign_group(not_selected_ids, @group.parent_id.present? ? @group.parent_id : nil)
          end

          respond_to do |format|
            if @time_series.save
              format.html { redirect_to time_series_time_series_groups_path, flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.group'))} }
              format.json { render json: @group, status: :created, location: @group }
            else
              logger.debug "!!!!!!!!!!! error = #{@time_series.errors.messages.inspect}"
              add_common_options

              format.html { render action: "new" }
              format.json { render json: @group.errors, status: :unprocessable_entity }
            end
          end
        else
          @group.add_missing_questions_error

          respond_to do |format|
            add_common_options

            format.html { render action: "new" }
            format.json { render json: @group.errors, status: :unprocessable_entity }
          end
        end
      else
        respond_to do |format|
          add_common_options

          format.html { render action: "new" }
          format.json { render json: @group.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_index_path(:locale => I18n.locale)
      return
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
   @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @group = @time_series.groups.find(params[:id])
      @group.assign_attributes(params[:time_series_group])

      # check if group is valid
      # - if not, stop
      if @group.valid?
        # assign the group ids to the questions
        if params[:time_series].present? && params[:time_series][:time_series_questions_attributes].present?
          selected_ids = params[:time_series][:time_series_questions_attributes].select{|k,v| v[:selected] == 'true'}.map{|k,v| v[:id]}
          not_selected_ids = params[:time_series][:time_series_questions_attributes].select{|k,v| v[:selected] != 'true'}.map{|k,v| v[:id]}
        end

        # have to have subgroups or questions in order to be saved
        if (selected_ids.present? && selected_ids.length > 0) ||
            (not_selected_ids.present? && not_selected_ids.length > 0) ||
            @group.subgroups.length > 0
          if (selected_ids.present? && selected_ids.length > 0)
            @time_series.questions.assign_group(selected_ids, @group.id)
          end
          if (not_selected_ids.present? && not_selected_ids.length > 0)
            @time_series.questions.assign_group(not_selected_ids, @group.parent_id.present? ? @group.parent_id : nil)
          end
          respond_to do |format|
            if @time_series.save
              format.html { redirect_to time_series_time_series_groups_path, flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.group'))} }
              format.json { head :no_content }
            else
              add_common_options

              format.html { render action: "edit" }
              format.json { render json: @group.errors, status: :unprocessable_entity }
            end
          end
        else
          @group.add_missing_questions_error

          respond_to do |format|
            add_common_options

            format.html { render action: "new" }
            format.json { render json: @group.errors, status: :unprocessable_entity }
          end
        end
      else
        respond_to do |format|
          add_common_options

          format.html { render action: "edit" }
          format.json { render json: @group.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_index_path(:locale => I18n.locale)
      return
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
   @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @group = @time_series.groups.find(params[:id])
      @group.destroy

      respond_to do |format|
        format.html { redirect_to time_series_time_series_groups_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.group'))} }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_index_path(:locale => I18n.locale)
      return
    end
  end

  # get the questions that can be assigned to this group and that are currently assigned to this group
  def group_questions
    if params[:time_series_id].present?
      time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

      if time_series.present?
        # if group id was provided, look for questions assigned to the group
        # else get questions that do not have groups assigned yet
        questions = if params[:group_id].present?
          time_series.questions.assigned_to_group_meta_only(params[:group_id])
        else
          time_series.questions.not_assigned_group_meta_only
        end

        # get questions already assigned to the group
        assigned_questions = time_series.questions.assigned_to_group_meta_only(params[:id])

        # combine the two sets of questions with the selected questions first
        items = sort_objects_with_sort_order(assigned_questions).map{|x| x.json_for_groups(true)} + sort_objects_with_sort_order(questions).map{|x| x.json_for_groups}

        respond_to do |format|
          format.json { render json: items }
        end
        return
      end
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end

private
  def add_common_options(for_form=true)
    @css.push("groups.css")
    @js.push("time_series_groups.js")

    if for_form
      @css.push('tabbed_translation_form.css', 'select2.css')
      @js.push('select2/select2.min.js')

      @languages = Language.sorted

      # get list of current main groups
      @main_groups = @time_series.groups.main_groups(@group.id)

      gon.insert_description_text = t('app.msgs.insert_description_text')
      gon.group_questions_path = group_questions_time_series_time_series_group_path(@time_series.id, @group.id)
    end

    add_time_series_nav_options
    set_gon_datatables

  end

end
