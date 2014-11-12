module DatasetsHelper

  def format_dataset_public_status(is_public)
    if is_public == true
      return "<div class='dataset-public-status dataset-public'>#{t('dataset_status.public')}</div>".html_safe
    else
      return "<div class='dataset-public-status dataset-not-public'>#{t('dataset_status.private')}</div>".html_safe
    end
  end
end
