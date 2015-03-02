module DatasetsHelper

  def format_dataset_public_status(is_public)
    if is_public == true
      return "<div class='publish-status public'>#{t('publish_status.public')}</div>".html_safe
    else
      return "<div class='publish-status not-public'>#{t('publish_status.private')}</div>".html_safe
    end
  end

end
