class ApiController < ApplicationController

  def index
    @page_content = PageContent.by_name('api')
    @api_versions = ApiVersion.sorted

    @css.push('api.css')
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

end
