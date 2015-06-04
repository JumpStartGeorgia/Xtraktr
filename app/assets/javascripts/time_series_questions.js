var datatable;
var timer_calls = 0;
var dataset_answers = {};
var datasets_with_question_count = 0;

// get the answers for dataset and question
function get_question_answers(dataset_id, question_code, callback){
  $.ajax({
    method: "POST",
    url: gon.dataset_question_answers_path.replace('%5Bdataset_id%5D', dataset_id),
    data: {
      question_code: question_code
    }
  })
  .done(function(answers){
    callback(answers);
  });
}

function build_select_lists(dataset_id, answers, is_page_load, tr_to_update){
  if (is_page_load == undefined){
    is_page_load = false;    
  }

  console.log('==================');
  console.log('build_select list !');
  console.log('dataset id = ' + dataset_id);
  console.log(answers) 

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
}

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

  // update the answers for this dataset
  get_question_answers(dataset_id, $(ths_select).val(), function(answers){
    build_select_lists(dataset_id, answers, is_page_load, tr_to_update);
  });
}

// build the answers 
function build_answers(dataset_answers){
  console.log('build answers!');
  if ( Object.keys(dataset_answers).length > 0 ){
    // use answers from first dataset as basis for creating answers
    var datasets = Object.keys(dataset_answers);
    console.log(datasets);
    // get list of answer values
    var answer_values = $.map(dataset_answers[datasets[0]], function(answer, i){
      return answer.value;
    });

    // add each of these answers
    var tr;
    var answer;
    $(answer_values).each(function(i){
console.log('-------------');
console.log('-- index = ' + i);
      answer = dataset_answers[datasets[0]][i];
      tr = $('table#time-series-dataset-answers tfoot a.add_fields').data('association-insertion-template');

      // add index
      tr = tr.replace(/new_answers/g, i);

      ///////////////////////////////////////////////////
      // create the rows for the default language table

      // add row to table
      $('table#time-series-dataset-answers:first tbody').append(tr)

      // cell 1 - text
      $('table#time-series-dataset-answers:first tbody tr:last').find('td:nth-child(1) input').val(answer.text);

      // cell 2 - value
      $('table#time-series-dataset-answers:first tbody tr:last').find('td:nth-child(2) input').val(answer.value);

      // cell 3 - sort
      $('table#time-series-dataset-answers:first tbody tr:last').find('td:nth-child(3) input').val(i+1);

      // cell 4 - can exclude


      ///////////////////////////////////////////////////
      // create the rows for the other language tables
    });

    
    ///////////////////////////////////////////////////
    // populate the select lists
    console.log(datasets);
    for(var i=0;i<datasets.length;i++){
      build_select_lists(datasets[i], dataset_answers[datasets[i]]);
    }
  }

}

// once all ajax calls are completed for getting the answers, build them
function check_for_all_answers(){
  console.log('build check_for_all_answers!');
  console.log('dataset ans length = ' + Object.keys(dataset_answers).length + '; count length = ' + datasets_with_question_count);
  timer_calls += 1;
  if ( Object.keys(dataset_answers).length == datasets_with_question_count ){
    console.log('done!');
    build_answers(dataset_answers);
  }
  else if (timer_calls < 10){
    console.log('not yet ;(');
    window.setTimeout("check_for_all_answers();",500);
  }
}

// auto create answers for the selected dataset questions
// - can only do this if no answers already exist
function auto_create_answers(){
  // reset variables
  dataset_answers = {};
  datasets_with_question_count = 0;

  if ($('table#time-series-dataset-answers tbody tr').length == 0){
    // get answers for each dataset
    $('form select.dataset-question').each(function(){
      if ($(this).val() != ''){
        datasets_with_question_count += 1;
        var dataset_id = $(this).closest('tr').find('td:first input[type="hidden"]').val();
        get_question_answers(dataset_id, $(this).val(), function(answers){
          console.log('got answers for dataset!');
          dataset_answers[dataset_id] = answers;
        });
      }
    });

    // when the dataset_answers length = the question count, build the answers
    check_for_all_answers();
  }
}



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



  if (gon.dataset_question_answers_path){
    // when question changes, update the list of answers if there are rows in the table
    $('form').on('change', 'select.dataset-question', function(){
      if ($('table#time-series-dataset-answers tbody tr').length > 0){
        update_question_answers(this);
      }else{
        $('a#auto-create-answers').css('display','none').removeClass('hide').fadeIn();
      }
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

    // remove the row in all other tables too
    $('table#time-series-dataset-answers').on('cocoon:after-remove', function(e,to_delete) {
      console.log('delete row!');
    });


    // when original code is entered, update the hidden code field
    $('form input#time_series_question_original_code').change(function(){
      $('form input#time_series_question_code').val($(this).val().toLowerCase().replace(/\./g, "|"))
    });


    // save text for selected item
    $('table#time-series-dataset-answers').on('change', 'select.selectpicker', function(){
      $(this).closest('td').find('input.dataset_question_answer_text').val($(this).find('option:selected').text());
    });

    // turn on fancy select
    $('form select.selectpicker').select2({width:'element', allowClear:true});

    // auto create answers
    $('a#auto-create-answers').click(function(){
      auto_create_answers();

      setTimeout(function(){ 
        $('a#auto-create-answers').fadeOut(function(){
          $('a#delete-all-answers').css('display','none').removeClass('hide').fadeIn();
        });
      }, 1000);
    });

    // delete all answers
    $('a#delete-all-answers').click(function(){

      var answer=confirm($(this).data('confirm-text'));
      if(answer){
        setTimeout(function(){ 
          $('a#delete-all-answers').fadeOut(function(){
            $('a#auto-create-answers').css('display','none').removeClass('hide').fadeIn();
          });
        }, 1000);

        $('table#time-series-dataset-answers tbody').empty();

      }
      else{
       e.preventDefault();      
      }

    });
  }

});