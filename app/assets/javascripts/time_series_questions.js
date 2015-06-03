var datatable;
$(document).ready(function(){

  // datatable for time series questions index page
  datatable = $('#time-series-questions').dataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "columnDefs": [
      { orderable: false, targets: [0,-1] }
    ],
    "order": [[1, 'asc']],
    "language": {
      "url": gon.datatable_i18n_url,
      "searchPlaceholder": gon.datatable_search
    },
    "pagingType": "full_numbers"
  });


  // when question changes in form, get the answers for this question 
  // - get answers for question and add to table of answers
  // - if tr_to_update provided, only update the select in that tr, else update all trs
  function update_question_answers(ths_select, is_page_load, tr_to_update){
    if (is_page_load == undefined){
      is_page_load = false;    
    }

    var dataset_id = $(ths_select).closest('tr').find('td:first input[type="hidden"]').val();

    // set the title hidden field
    $(ths_select).closest('td').find('input.dataset_question_text').val($(ths_select).find('option:selected').text().split(' - ')[1]);

    $.ajax({
      method: "POST",
      url: gon.dataset_question_answers_path.replace('%5Bdataset_id%5D', dataset_id),
      data: {
        question_code: $(ths_select).val()
      }
    })
    .done(function(answers){
      // update the answers for this dataset

      // build the options
      var options = "";
      $(answers).each(function(){
        options += "<option value='" + this.value + "'>" + this.text + "</option>";
      });
   
      // add the options to each answer select input for this dataset
      var tds;
      if (tr_to_update == undefined){
        tds = $('td.dataset-question-answer[data-dataset-id="' + dataset_id + '"]');
      }else{
        tds = $(tr_to_update).find('td.dataset-question-answer[data-dataset-id="' + dataset_id + '"]');
      }
      $(tds).each(function(){
        var select = $(this).find('select');

        // remove the existing options
        $(select).empty();
        var original_value = $(select).data('original-value');

        if (answers.length > 0){
          // add options
          $(select).append(options);
          if (is_page_load && original_value){
            // set the value using the data attribute of the select
            $(select).val(original_value);
          }else{
            // if one of these answers has the time series answer value, select it
            $(select).val($(this).closest('tr').find('td:nth-child(2) input').val());
          }
        }

        // apply selectpicker
        $(select).select2({width:'element', allowClear:true});


      });

    });
  }


  if (gon.dataset_question_answers_path){
    // when question changes, update the list of answers
    $('form select.dataset-question').change(function(){
      update_question_answers(this);
    });

    // when page loads, get the list of answers for each question
    if ($('table#time-series-dataset-answers tbody tr').length > 0){
      $('form select.dataset-question').each(function(){
        if ($(this).val() != ''){
          update_question_answers(this, true);
        }
      });
    }

    // add select lists for the new row
    $('table#time-series-dataset-answers').on('cocoon:before-insert', function(e,to_add) {
      $('form select.dataset-question').each(function(){
        update_question_answers(this, false, to_add);
      });
    });

    // when original code is entered, update the hidden code field
    $('form input#time_series_question_original_code').change(function(){
      $('form input#time_series_question_code').val($(this).val().toLowerCase().replace(/\./g, "|"))
    });


    // save text for selected item
    $('table#time-series-dataset-answers select.selectpicker').change(function(){
      $(this).closest('td').find('input.dataset_question_answer_text').val($(this).find('option:selected').text());
    });

    // turn on fancy select
    $('form select.selectpicker').select2({width:'element', allowClear:true});


  }

});