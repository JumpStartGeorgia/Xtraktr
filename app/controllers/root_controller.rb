class RootController < ApplicationController
  def index
    @datasets = Dataset.meta_only.is_public.recent.sorted.limit(6)
    @time_series = TimeSeries.meta_only.is_public.recent.sorted.limit(3)

    @categories = Category.sorted
    @highlights = Highlight.for_home_page
    gon.highlight_ids = @highlights.map{|x| x.id} if @highlights.present?
    gon.highlight_show_title = true
    gon.highlight_show_links = false
    load_highlight_assets(@highlights.map{|x| x.embed_id}) if @highlights.present?

    @css.push('root.css', 'highlights.css', 'boxic.css')
    @js.push('highlights.js')
    data = { test: 'test1' }
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: data }
    end
  end

  def instructions
    @page_content = PageContent.by_name('instructions')
    @css.push('root.css')
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def contact
    @page_content = PageContent.by_name('contact')
    @css.push('root.css')

    @message = Message.new
    if request.post?
      @message = Message.new(params[:message])
      if @message.save
        # send message
        ContactMailer.new_message(@message).deliver
        flash[:success] = I18n.t("app.msgs.message_sent")
        # reset the message object since msg was sent
        @message = Message.new
      end
    end

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def about
    @page_content = PageContent.by_name('about')
    @css.push('root.css', 'tabs.css')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def highlights
    @highlights = Highlight.public_highlights
    gon.highlight_ids = @highlights.map{|x| x.id} if @highlights.present?
    gon.highlight_show_title = true
    gon.highlight_show_links = false
    load_highlight_assets(@highlights.map{|x| x.embed_id}) if @highlights.present?

    @css.push('highlights.css', 'boxic.css')
    @js.push('highlights.js')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def owner_dashboard
    @klass=' white'
    @klass_footer=''

    if @owner.blank?
      redirect_to root_path, :notice => t('app.msgs.does_not_exist')
    else
      @datasets = Dataset.meta_only.is_public.sorted_public_at.by_owner(@owner.id)
      @time_series = TimeSeries.meta_only.is_public.sorted_public_at.by_owner(@owner.id)
      @show_title = false

      @css.push("list.css", "dashboard.css", 'tabs.css')


      respond_to do |format|
        format.html # index.html.erb
      end
    end
  end


  def explore_data
    @datasets = Dataset.meta_only.is_public

    # add search
    if params[:q].present?
      @datasets = @datasets.search(params[:q])
    end
    # add sort
    if params[:sort].present?
      case params[:sort].downcase
        when 'publish'
          @datasets = @datasets.sorted_public_at
        when 'release'
          @datasets = @datasets.sorted_released_at
        else #when 'title'
          @datasets = @datasets.sorted_title
      end
    else
      @datasets = @datasets.sorted_title
    end    
    # add category
    @datasets = @datasets.categorize(params[:category]) if params[:category].present? 
    @datasets = @datasets.with_country(params[:country]) if params[:country].present?
    @datasets = @datasets.with_donor(params[:donor]) if params[:donor].present?
    @datasets = @datasets.with_owner(params[:owner]) if params[:owner].present?

    @datasets = Kaminari.paginate_array(@datasets).page(params[:page]).per(per_page)

    @show_title = false
    if !request.xhr?
      @categories = Category.sorted.in_datasets
      @countries = Country.not_excluded.sorted.in_datasets
      @owners = User.in_datasets
      @donors = Dataset.donors
    end 

    @css.push('list.css')
    @js.push('list.js')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: { d: (render_to_string "root/_explore_data_datasets", formats: 'html', :layout => false) } }
    end
  end

  def explore_data_dashboard
    @klass=' white'
    @klass_footer=''
    @dataset = Dataset.is_public.by_id_for_owner(params[:id], @owner.id) if @owner.present?

    if @dataset.blank?
      redirect_to explore_data_path, :notice => t('app.msgs.does_not_exist')
    else
      # if the language parameter exists and it is valid, use it instead of the default current_locale
      if params[:language].present? && @dataset.languages.include?(params[:language])
        @dataset.current_locale = params[:language]
      end

      @highlights = Highlight.by_dataset(@dataset.id)
      gon.highlight_ids = @highlights.map{|x| x.id}.shuffle if @highlights.present?
      gon.highlight_show_title = false
      gon.highlight_show_links = false
      load_highlight_assets(@highlights.map{|x| x.embed_id}, @dataset.current_locale) if @highlights.present?

      @show_title = false

      @css.push('bootstrap-select.min.css', "list.css", "dashboard.css", 'highlights.css', 'boxic.css', 'tabs.css', 'explore.css')
      @js.push('bootstrap-select.min.js', "live_search.js", 'highlights.js', 'explore.js')

      respond_to do |format|
        format.html # index.html.erb
      end
    end
  end

  def explore_data_show
    @dataset = Dataset.is_public.by_id_for_owner(params[:id], @owner.id) if @owner.present?

    if @dataset.blank?
      redirect_to explore_data_path, :notice => t('app.msgs.does_not_exist')
    else
      @show_title = false
      @is_admin = false
      @dataset_url = explore_data_show_path(@dataset.owner, @dataset)
      gon.chart_type_bar = t('explore_data.chart_type_bar')
      gon.chart_type_pie = t('explore_data.chart_type_pie')
      
      # gon.embed_chart = "<div class='embed-chart-modal'>
      #                     <div class='header'>#{t('helpers.links.embed_chart')}</div>
      #                     <div class='figure'></div>
      #                     <div class='text'>#{t('helpers.links.embed_chart_prompt')}</div>
      #                     <div class='box'>
      #                       <div class='dimensions'>
      #                         <div class='wide'><input type='number' value='500'><span>#{t('helpers.links.embed_chart_wide')}</span></div>
      #                         <div class='high'><input type='number' value='310'><span>#{t('helpers.links.embed_chart_high')}</span></div>
      #                       </div>
      #                       <textarea rows='7'></textarea>
      #                     </div>
      #                     <div class='closeup' onclick='js_modal_off();'></div>
      #                   </div>"
      # gon.embed_chart_url = "<iframe src='{path}' width='{wide}' height='{high}' frameborder='0'></iframe>"
      # this method is in application_controller
      # and gets all of the required information
      # and responds appropriately to html or js
      explore_data_generator(@dataset)
    end
  end



  def explore_time_series
    @time_series = TimeSeries.meta_only.is_public

    # add search
    if params[:q].present?
      @time_series = @time_series.search(params[:q])
    end
    # add sort
    if params[:sort].present?
      case params[:sort].downcase
        when 'publish'
          @time_series = @time_series.sorted_public_at
        else #when 'title'
          @time_series = @time_series.sorted_title
      end
    else
      @time_series = @time_series.sorted_title
    end
    
    @time_series = @time_series.categorize(params[:category]) if params[:category].present?
    @time_series = @time_series.with_country(params[:country]) if params[:country].present?
    @time_series = @time_series.with_owner(params[:owner]) if params[:owner].present?

    @time_series = Kaminari.paginate_array(@time_series).page(params[:page]).per(per_page)

    @show_title = false
    if !request.xhr?
      @categories = Category.sorted.in_time_series
      @countries = Country.not_excluded.sorted.in_time_series
      @owners = User.in_time_series
    end

    @css.push('list.css')
    @js.push('list.js')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: { d: (render_to_string "root/_explore_data_time_series", formats: 'html', :layout => false) } }
    end
  end

  def explore_time_series_dashboard
    @klass=' white'
    @klass_footer=''
    @time_series = TimeSeries.is_public.by_id_for_owner(params[:id], @owner.id) if @owner.present?

    if @time_series.blank?
      redirect_to explore_time_path, :notice => t('app.msgs.does_not_exist')
    else

      # if the language parameter exists and it is valid, use it instead of the default current_locale
      if params[:language].present? && @time_series.languages.include?(params[:language])
        @time_series.current_locale = params[:language]
      end

      @datasets = Dataset.is_public.in(id: @time_series.datasets.dataset_ids)

      @highlights = Highlight.by_time_series(@time_series.id)
      gon.highlight_ids = @highlights.map{|x| x.id}.shuffle if @highlights.present?
      gon.highlight_show_title = false
      gon.highlight_show_links = false
      load_highlight_assets(@highlights.map{|x| x.embed_id}, @time_series.current_locale) if @highlights.present?

      @show_title = false

      @css.push('bootstrap-select.min.css', "list.css", "dashboard.css", 'highlights.css', 'boxic.css', 'tabs.css', 'explore.css')
      @js.push('bootstrap-select.min.js', "live_search.js", 'highlights.js', 'explore.js')

      respond_to do |format|
        format.html # index.html.erb
      end
    end
  end


  def explore_time_series_show
    @time_series = TimeSeries.is_public.by_id_for_owner(params[:id], @owner.id) if @owner.present?

    if @time_series.blank?
      redirect_to explore_time_path, :notice => t('app.msgs.does_not_exist')
    else
      @show_title = false
      @is_admin = false
      @time_series_url = explore_time_series_show_path(@time_series.owner, @time_series)
      # gon.embed_chart = "<div class='embed-chart-modal'>
      #                     <div class='header'>#{t('helpers.links.embed_chart')}</div>
      #                     <div class='figure'></div>
      #                     <div class='text'>#{t('helpers.links.embed_chart_prompt')}</div>
      #                     <div class='box'>
      #                       <div class='dimensions'>
      #                         <div class='wide'><input type='number' value='500'><span>#{t('helpers.links.embed_chart_wide')}</span></div>
      #                         <div class='high'><input type='number' value='310'><span>#{t('helpers.links.embed_chart_high')}</span></div>
      #                       </div>
      #                       <textarea rows='7'></textarea>
      #                     </div>
      #                     <div class='closeup' onclick='js_modal_off();'></div>
      #                   </div>"
      # gon.embed_chart_url = "<iframe src='{path}' width='{wide}' height='{high}' frameborder='0'></iframe>"
      # this method is in application_controller
      # and gets all of the required information
      # and responds appropriately to html or js
      explore_time_series_generator(@time_series)
    end
  end


  def private_share
    @dataset = Dataset.by_private_key(params[:id])

    if @dataset.blank?
      redirect_to root_path, :notice => t('app.msgs.does_not_exist')
    elsif @dataset.public?
      redirect_to explore_data_show_path(@dataset.owner, @dataset)
    else
      @is_admin = false
      @dataset_url = private_share_path(@dataset.private_share_key)
      gon.explore_data = true
      gon.api_dataset_analysis_path = api_v2_dataset_analysis_path

      # this method is in application_controller
      # and gets all of the required information
      # and responds appropriately to html or js
      explore_data_generator(@dataset)
    end
  end

  def download_request
    sign_in = user_signed_in?
    data = { agreement: sign_in }
    @dataset_id = params[:id]
    @dataset_type = params[:type]
    @dataset_locale = params[:lang]
    @download_type = params[:download_type]
    if sign_in 
      if current_user.valid? 
        current_user.agreement(@dataset_id, @dataset_type, @dataset_locale, @download_type)
        mapper = FileMapper.create({ dataset_id: @dataset_id, dataset_type: @dataset_type, dataset_locale: @dataset_locale, download_type: @download_type })
        data[:url] = "/#{I18n.locale}/download/#{mapper.key}"
      else 
        @mod = Agreement.new({ dataset_id: @dataset_id, dataset_type: @dataset_type, dataset_locale: @dataset_locale, download_type: @download_type  })
        data[:agreement] = false
        @user = current_user
        @flags = [false, false, current_user.provider.blank?, true, false]
        data[:form] = render_to_string "settings/_settings", :layout => false
      end
    else
      @flags = [true, true, true, true, true]
      @mod = Agreement.new({ dataset_id: @dataset_id, dataset_type: @dataset_type, dataset_locale: @dataset_locale, download_type: @download_type  })
      data[:form] = render_to_string "devise/registrations/new", :layout => false, :locals => { explanation: true }
    end
    respond_to do |format|
      format.json { render json: data }
    end
  end
  def download
    begin
      mapper = FileMapper.find_by(key: params[:id])
      dat = Dataset.find(mapper.dataset_id)
      dat.current_locale = mapper.dataset_locale
      file = dat.urls[mapper.dataset_type][mapper.dataset_locale]
      mapper.destroy
      send_file  Rails.public_path + file,  :filename => clean_filename(dat.title + "--"+ mapper.dataset_type.upcase +  "--" + I18n.l(Time.now,format: :file)) +  ".zip",
       :type=>"application/zip", :x_sendfile=>true

    rescue
      redirect_to (session[:previous_urls].last || request.env['omniauth.origin'] || root_path(:locale => I18n.locale))
      #render file: "#{Rails.root}/public/404.html", layout: false, status: 404
    end
  end


  # generate the html code and js data for the passed in highlight ids
  def generate_highlights
    # get the highlights
    highlights = Highlight.in(id: params[:ids].split(','))
    data = {}

    if highlights.present?
      @highlight_data = []
      highlights.each do |highlight|
        @highlight_data << {visual_type_name: highlight.visual_type_name, data: get_highlight_data(highlight.embed_id, highlight.id, params[:use_admin_link])}
      end

      if @highlight_data.map{|x| x[:data]}.flatten.map{|x| x[:error]}.index{|x| x == true}.nil?

        # save the html data
        data[:html] = render_to_string "root/generate_highlights", formats: [:html], layout: false

        # save the js data
        data[:js] = {}
        @highlight_data.each do |highlight|
          data[:js][highlight[:data][:highlight_id].to_s] = highlight[:data][:js]
        end

      end
    end

    respond_to do |format|
      format.json { render json: data }
    end
  end

end
