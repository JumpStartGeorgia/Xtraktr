class ApiController < ApplicationController

  def index
    @page_content = PageContent.by_name('api')
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

end
