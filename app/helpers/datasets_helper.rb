module DatasetsHelper

  def format_dataset_public_status(is_public)
    if is_public == true
      return "<div class='dataset-public-status dataset-public'>#{t('formtastic.yes')}</div>".html_safe
    else
      return "<div class='dataset-public-status dataset-not-public'>#{t('formtastic.no')}</div>".html_safe
    end
  end
end
