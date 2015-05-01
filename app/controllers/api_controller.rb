class ApiController < ApplicationController

  def index
   @show_subnav_navbar = true
   @page_content = PageContent.by_name('api')
   @api_versions = ApiVersion.is_public.sorted

   @css.push('api.css')
   @show_title = false

   respond_to do |format|
   format.html # index.html.erb
   end
  end

end
