$(function() {

    // get all languages for select datasets and add them to languages select field
    function update_dataset_languages(){
      var langs = $.unique($('table#time_series_datasets select option:selected').map(function(){
        return $(this).data('languages');
      }).get().join().split(','));
      $('select#time_series_languages').select2('val', langs);
      $('select#time_series_languages').trigger('change');
    }


    // disable option if it is selected in another list
    function disable_selected_values(){
      // first make all options enabled
      $('table#time_series_datasets select option').prop('disabled', false);

      // now disable selected options
      $('table#time_series_datasets select').each(function(){
        $('table#time_series_datasets select option[value="' + $(this).val() + '"]:not(:selected)').prop('disabled', true);
      });
    }

    $('table#time_series_datasets').on('cocoon:after-insert', function(e,to_add) {
       // disable items in list that are already selected
      disable_selected_values();
      $('form.tabbed-translation-form select.selectpicker-dataset:last').select2({width:'element', allowClear:true});
    });
    $('table#time_series_datasets').on('cocoon:after-remove', function(e,to_delete) {
       // enable items in list that was just deleted
      disable_selected_values();
      update_dataset_languages();
    });

    // when a dataset is selcted, make sure it is disabled in all other lists
    // and make sure its languages are included in the list
    $('table#time_series_datasets').on('change', 'select', function(){
      disable_selected_values();
      update_dataset_languages()
    });

    // diable selected items when page loads
    $('table#time_series_datasets select').each(function(){
      disable_selected_values();
    });

    // fancy select box
    $('form.tabbed-translation-form select.selectpicker-dataset').select2({width:'element', allowClear:true});

});