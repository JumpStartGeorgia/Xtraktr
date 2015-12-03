/*global  $, gon*/
var datatable,
  timer_calls = 0,
  dataset_answers = {},
  datasets_with_question_count = 0;

// get the answers for dataset and question
function get_question_answers (dataset_id, question_code, callback){
  $.ajax({
    method: "POST",
    url: gon.dataset_question_answers_path.replace("%5Bdataset_id%5D", dataset_id),
    data: {
      question_code: question_code
    }
  })
  .done(function (answers){
    callback(answers);
  });
}

function build_select_lists (dataset_id, answers, is_page_load, tr_to_update){
  if (is_page_load == undefined){
    is_page_load = false;
  }

  // build the options
  var options = "<option value=''></option>";
  $(answers).each(function (){
    options += "<option value='" + this.value + "'>" + this.text + "</option>";
  });

  // add the options to each answer select input for this dataset
  var tds;
  if (tr_to_update == undefined){
    tds = $("td.dataset-question-answer[data-dataset-id='" + dataset_id + "']");
  }else{
    tds = $(tr_to_update).find("td.dataset-question-answer[data-dataset-id='" + dataset_id + "']");
  }
  $(tds).each(function (){
    var select = $(this).find("select");
    var original_value = $(select).data("original-value");
    var hidden_text = $(this).find("input.dataset_question_answer_text");

    // remove the existing options
    $(select).empty();
    $(hidden_text).val("");

    if (answers.length > 0){
      // add options
      $(select).append(options);
      if (is_page_load && original_value != undefined){
        // set the value using the data attribute of the select
        $(select).val(original_value);
      }else{
        // if one of these answers has the time series answer value, select it
        $(select).val($(this).closest("tr").find("td:nth-child(2) input").val());
      }
      $(hidden_text).val($(select).find("option:selected").text());
    }

    // apply selectpicker
    $(select).select2({width: "element", allowClear: true});


  });
}

// when question changes in form, get the answers for this question
// - get answers for question and add to table of answers
// - if tr_to_update provided, only update the select in that tr, else update all trs
function update_question_answers (ths_select, is_page_load, tr_to_update){
  if (is_page_load == undefined){
    is_page_load = false;
  }

  var dataset_id = $(ths_select).closest("tr").find("td:first input[type='hidden']").val();

  // set the title hidden field
  $(ths_select).closest("td").find("input.dataset_question_text").val($(ths_select).find("option:selected").text().split(" - ")[1]);

  // update the answers for this dataset
  get_question_answers(dataset_id, $(ths_select).val(), function (answers){
    build_select_lists(dataset_id, answers, is_page_load, tr_to_update);
  });
}

// build the answers
function build_answers (dataset_answers){
  if ( Object.keys(dataset_answers).length > 0 ){
    // use answers from first dataset as basis for creating answers
    var datasets = Object.keys(dataset_answers);
    // get list of answer values
    var answer_values = $.map(dataset_answers[datasets[0]], function (answer, i){
      return answer.value;
    });

    // add each of these answers
    var tr;
    var answer;
    $(answer_values).each(function (i){
      answer = dataset_answers[datasets[0]][i];

      tr = $("table#time-series-dataset-answers tfoot a.add_fields").data("association-insertion-template");

      // add index
      tr = tr.replace(/new_answers/g, i);

      ///////////////////////////////////////////////////
      // create the rows for the default language table

      // add row to table
      var tbody = $("table#time-series-dataset-answers:first tbody");
      tbody.append(tr);

      tbody.find("tr:last").find("td:nth-child(1) input").val(answer.text); // cell 1 - text
      tbody.find("tr:last").find("td:nth-child(2) input").val(answer.value); // cell 2 - value
      tbody.find("tr:last").find("td:nth-child(3) input").val(i+1); // cell 3 - sort

      // cell 4 - can exclude

      ///////////////////////////////////////////////////
      // create the rows for the other language tables
      create_answer_other_languages(tr, answer.text_translations, answer.text);
    });

    ///////////////////////////////////////////////////
    // populate the select lists
    for(var i=0;i<datasets.length;i++){
      build_select_lists(datasets[i], dataset_answers[datasets[i]]);
    }
  }

}

// once all ajax calls are completed for getting the answers, build them
function check_for_all_answers (){
  timer_calls += 1;
  if ( Object.keys(dataset_answers).length == datasets_with_question_count ){
    build_answers(dataset_answers);
  }
  else if (timer_calls < 10){
    window.setTimeout("check_for_all_answers();", 500);
  }
}

// auto create answers for the selected dataset questions
// - can only do this if no answers already exist
function auto_create_answers (){
  // reset variables
  dataset_answers = {};
  datasets_with_question_count = 0;

  if ($("table#time-series-dataset-answers tbody tr").length == 0){
    // get answers for each dataset
    $("form select.dataset-question").each(function (){
      if ($(this).val() != ""){
        datasets_with_question_count += 1;
        var dataset_id = $(this).closest("tr").find("td:first input[type='hidden']").val();
        get_question_answers(dataset_id, $(this).val(), function (answers){
          dataset_answers[dataset_id] = answers;
        });
      }
    });

    // when the dataset_answers length = the question count, build the answers
    check_for_all_answers();
  }
}

// add new answer to all other languages
function create_answer_other_languages (inserted_row, input_text_translations, default_text){
  var content = $(inserted_row).find("td:last");
  var default_locale = $(".tab-content .tab-pane:first").data("locale");
  var row = "<tr><td>";
  row += $(content).find(".new-answer-input").html();
  row += "</td><td>";
  if (default_text != undefined){
    row += default_text;
  }else{
    row += $(content).find(".new-answer-default-text").html();
  }
  row += "</td></tr>";

  // add this new row to all languages
  for (var i=1; i < $(".tab-content .tab-pane").length; i++){
    var tab_pane = $(".tab-content .tab-pane")[i];
    var new_locale = $(tab_pane).data("locale");

    // if the input_text translations is provided and translations exist for this locale, use it
    if (input_text_translations != undefined && input_text_translations[new_locale] != undefined){
      row = row.replace("value=''", "value='" + input_text_translations[new_locale] + "'");
    }

    // add the row
    $(tab_pane).find("table#time-series-dataset-answers tbody")
      .append(row.replace(new RegExp("_" + default_locale, "g"), "_" + new_locale).replace(new RegExp('\\[' + default_locale + '\\]', 'g'), '[' + new_locale + ']'));

  }

  // now delete the content placeholder so form submital is not effected
  $(".tab-content .tab-pane:first table#time-series-dataset-answers tbody tr:last td:last").remove();  
}


$(document).ready(function (){

  // datatable for time series questions index page
  datatable = $("#time-series-questions").dataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "columnDefs": [
      { orderable: false, targets: [0, -1] }
    ],
    "sorting": [],
    // "order": [[1, 'asc']],
    "language": {
      "url": gon.datatable_i18n_url,
      "searchPlaceholder": gon.datatable_search
    },
    "pagingType": "full_numbers"
  });



  if (gon.dataset_question_answers_path){
    // when question changes, update the list of answers if there are rows in the table
    $("form").on("change", "select.dataset-question", function (){
      if ($("table#time-series-dataset-answers tbody tr").length > 0){
        update_question_answers(this);
      }else{
        $("a#auto-create-answers").css("display", "none").removeClass("hide").fadeIn();
      }
    });

    // when page loads, get the list of answers for each question
    if ($("table#time-series-dataset-answers tbody tr").length > 0){
      $("form select.dataset-question").each(function (){
        if ($(this).val() != ""){
          update_question_answers(this, true);
        }
      });
    }

    // add select lists for the new row
    $("table#time-series-dataset-answers").on("cocoon:before-insert", function (e, to_add) {
      $("form select.dataset-question").each(function (){
        update_question_answers(this, false, to_add);
      });
    });

    // when a new answer is added, add row for each of the other languages
    $("table#time-series-dataset-answers").on("cocoon:after-insert", function (e, inserted_item) {
      create_answer_other_languages(inserted_item);
    });


    // remove the row in all other tables too
    $("table#time-series-dataset-answers").on("cocoon:before-remove", function (e, to_delete) {
      // get index of this row so know which rows in other tables to delete
      var row_index = $(".tab-content .tab-pane:first table#time-series-dataset-answers tbody").children("tr").index(to_delete);

      for (var i=1; i < $(".tab-content .tab-pane").length; i++){
        // delete the row
        var row = $($(".tab-content .tab-pane")[i]).find("table#time-series-dataset-answers tbody tr")[row_index];
        if (row != undefined){
          $(row).remove();
        }
      }
    });

    // when text of answer changes in default language, update the other languages default text table cell
    $("table#time-series-dataset-answers:first tbody").on("change", "tr td:first-of-type input", function (){
      var text = $(this).val();
      var row_index = $(this).closest("tbody").children("tr").index($(this).closest("tr"));

      // for the other languages, update the 'default text' table cell at row_index
      for (var i=1; i < $(".tab-content .tab-pane").length; i++){
        $($($(".tab-content .tab-pane")[i]).find("table#time-series-dataset-answers tbody tr")[row_index]).find("td:last-of-type").html(text);
      }
    });


    // when original code is entered, update the hidden code field
    $("form input#time_series_question_original_code").change(function (){
      $("form input#time_series_question_code").val($(this).val().toLowerCase().replace(/\./g, "|"));
    });


    // save text for selected item
    $("table#time-series-dataset-answers").on("change", "select.selectpicker", function (){
      $(this).closest("td").find("input.dataset_question_answer_text").val($(this).find("option:selected").text());
    });

    // turn on fancy select
    $("form select.selectpicker").select2({width:"element", allowClear:true});

    // auto create answers
    $("a#auto-create-answers").click(function (){
      auto_create_answers();

      setTimeout(function (){
        $("a#auto-create-answers").fadeOut(function (){
          $("a#delete-all-answers").css("display", "none").removeClass("hide").fadeIn();
        });
      }, 1000);
    });

    // delete all answers
    $("a#delete-all-answers").click(function (e){

      var answer=confirm($(this).data("confirm-text"));
      if(answer){
        setTimeout(function () {
          $("a#delete-all-answers").fadeOut(function (){
            $("a#auto-create-answers").css("display", "none").removeClass("hide").fadeIn();
          });
        }, 1000);

        $("table#time-series-dataset-answers tbody").empty();

      }
      else {
        e.preventDefault();
      }

    });
  }


});