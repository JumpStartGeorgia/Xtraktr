var datatables, i, j, json_data;




// show or hide the can exclude checkbox
function set_can_exclude_visibility(){
  if ($('select#question_code option:selected').data('can-exclude') == true ||
      $('select#filtered_by_code option:selected').data('can-exclude') == true){

    $('div#can-exclude-container').css('visibility', 'visible');
  }else{
    $('div#can-exclude-container').css('visibility', 'hidden');
  }
}


// build time series line chart for each chart item in json
function build_time_series_charts(json){
  if (json.chart){
    // determine chart height
    var chart_height = time_series_chart_height(json);

    // remove all existing charts
    $('#container-chart').empty();
    // remove all existing chart links
    $('#jumpto select').empty();
    var jumpto_text = '';

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart
        build_time_series_chart(json.chart[i].filter_results, chart_height);

        // add jumpto link
        jumpto_text += '<option data-href="#chart-' + (i+1) + '">' + json.filtered_by.text + ' = ' + json.chart[i].filter_answer_text + '</option>';
      }

      // show jumpto links
      $('#jumpto select').append(jumpto_text);
      $('#jumpto select').val($('#jumpto select option:first').attr('value'));
      $('#jumpto select').selectpicker('refresh');
      $('#jumpto select').selectpicker('render');
      $('#jumpto').show();

    }else{
      // no filters
      build_time_series_chart(json.chart, chart_height);
  
      // hide jumpto
      $('#jumpto').hide();
    }
  }

}



////////////////////////////////////////////////
// build data table
function build_datatable(json){
  // set the title
  $('#container-table h3').html(json.results.title.html + json.results.subtitle.html);

  // if the datatable alread exists, kill it
  if (datatables != undefined && datatables.length > 0){
    for (var i=0;i<datatables.length;i++){
      datatables[i].fnDestroy();
    }
  }


  // build the table
  var table = '';

  // test if the filter is being used and build the table accordingly
  if (json.filtered_by == undefined){
    // build head
    table += "<thead>";
    // 2 headers of:
    //                dataset label
    // question   count percent count percent .....
    table += "<tr class='th-center'>";
    table += "<th class='var1-col-red'>" + gon.table_questions_header + "</th>";

    var ln = json.datasets.length;
    for(i=0; i<ln;i++){
      table += "<th colspan='2' class='code-highlight color"+(ln-i%13)+"'>";
      table += json.datasets[i].label;
      table += "</th>"
    }
    table += "</tr>";
    table += "<tr>";
    table += "<th class='var1-col code-highlight'>";
    table += json.question.original_code;
    table += "</th>";
    for(i=0; i<json.datasets.length;i++){
      table += "<th>";
      table += $('#container-table table').data('count');
      table += "</th>"
      table += "<th>";
      table += $('#container-table table').data('percent');
      table += "</th>"
    }
    table += "</tr>";
    table += "</thead>";

    // build body
    table += "<tbody>";
    // cells per row: row answer, count/percent for each col
    for(i=0; i<json.results.analysis.length; i++){
      table += "<tr>";
      table += "<td class='var1-col' data-order='" + json.question.answers[i].sort_order + "'>";
      table += json.results.analysis[i].answer_text;
      table += "</td>";
      for(j=0; j<json.results.analysis[i].dataset_results.length; j++){
        table += "<td data-order='" + json.results.analysis[i].dataset_results[j].count + "'>";
        table += Highcharts.numberFormat(json.results.analysis[i].dataset_results[j].count,0);
        table += "</td>";
        table += "<td>";
        table += json.results.analysis[i].dataset_results[j].percent.toFixed(2);
        table += "%</td>";
      }
    }

    table += "</tbody>";

  }else{

    // build head
    table += "<thead>";
    // 2 headers of:
    //                dataset label
    // filter   question   count percent count percent .....
    table += "<tr class='th-center'>";
    table += "<th class='var1-col-red' colspan='2'>" + gon.table_questions_header + "</th>";
    var ln = json.datasets.length;
    for(i=0; i<ln;i++){
      table += "<th colspan='2' class='code-highlight color"+(ln-i%13)+"'>";
      table += json.datasets[i].label;
      table += "</th>"
    }
    table += "</tr>";

    table += "<tr>";
    table += "<th class='var1-col code-highlight'>";
    table += json.filtered_by.original_code;
    table += "</th>";
    table += "<th class='var1-col code-highlight'>";
    table += json.question.original_code;
    table += "</th>";
    for(i=0; i<json.datasets.length;i++){
      table += "<th>";
      table += $('#container-table table').data('count');
      table += "</th>"
      table += "<th>";
      table += $('#container-table table').data('percent');
      table += "</th>"
    }
    table += "</tr>";
    table += "</thead>";

    // build body
    table += "<tbody>";
    // for each filter, show each question and the count/percents for each dataset
    for(h=0; h<json.results.filter_analysis.length; h++){

      for(i=0; i<json.results.filter_analysis[h].filter_results.analysis.length; i++){
        table += "<tr>";
        table += "<td class='var1-col' data-order='" + json.filtered_by.answers[h].sort_order + "'>";
        table += json.results.filter_analysis[h].filter_answer_text;
        table += "</td>";
        table += "<td class='var1-col' data-order='" + json.question.answers[i].sort_order + "'>";
        table += json.results.filter_analysis[h].filter_results.analysis[i].answer_text;
        table += "</td>";
        for(j=0; j<json.results.filter_analysis[h].filter_results.analysis[i].dataset_results.length; j++){
          table += "<td data-order='" + json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j].count + "'>";
          table += Highcharts.numberFormat(json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j].count,0);
          table += "</td>";
          table += "<td>";
          table += json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j].percent.toFixed(2);
          table += "%</td>";
        }
        table += "</tr>";
      }
    }
    table += "</tbody>";
  }


  // add the table to the page
  $('#container-table table').html(table);

  //initalize the datatable
  datatables = [];
  $('#container-table table').each(function(){
    datatables.push($(this).dataTable({
      "dom": '<"top"fl>t<"bottom"p><"clear">',
      "language": {
        "url": gon.datatable_i18n_url,
        "searchPlaceholder": gon.datatable_search
      },
      "pagingType": "full_numbers",
      "tableTools": {
        "sSwfPath": "/assets/dataTables/extras/swf/copy_csv_xls.swf",
        "aButtons": [
          {
            "sExtends": "copy",
            "sButtonText": gon.datatable_copy_title,
            "sToolTip": gon.datatable_copy_tooltip
          },
          {
            "sExtends": "csv",
            "sButtonText": gon.datatable_csv_title,
            "sToolTip": gon.datatable_csv_tooltip
          },
          {
            "sExtends": "xls",
            "sButtonText": gon.datatable_xls_title,
            "sToolTip": gon.datatable_xls_tooltip
          }
        ]        
      }
    }))
  });    

}

////////////////////////////////////////////////
// build details (question and possible answers)
function build_details(json){
  // clear out existing content and hide
  $('#tab-details .details-item .name-variable, #tab-details .details-item .notes, #tab-details .details-item .list-answers').empty();
  $('#tab-details .details-item').hide();

  // add questions
  if (json.question && json.question.text && json.question.answers){
    $('#tab-details #details-question-code .name-variable').html(json.question.text);    
    $('#tab-details #details-question-code .name-code').html(json.question.original_code);    
    if (json.question.notes){
      $('#tab-details #details-question-code .notes').html(json.question.notes);    
      $('#tab-details #details-question-code .details-notes').show();
    }else{
      $('#tab-details #details-question-code .details-notes').hide();
    }
    for(var i=0;i<json.question.answers.length;i++){
      $('#tab-details #details-question-code .list-answers').append('<li>' + json.question.answers[i].text + '</li>');
    }
    $('#tab-details #details-question-code').show();
  }

  // add filters
  if (json.filtered_by && json.filtered_by.text && json.filtered_by.answers){
    $('#tab-details #details-filtered-by-code .name-variable').html(json.filtered_by.text);    
    $('#tab-details #details-filtered-by-code .name-code').html(json.filtered_by.original_code);    
    if (json.filtered_by.notes){
      $('#tab-details #details-filtered-by-code .notes').html(json.filtered_by.notes);    
      $('#tab-details #details-filtered-by-code .details-notes').show();
    }else{
      $('#tab-details #details-filtered-by-code .details-notes').hide();
    }
    for(var i=0;i<json.filtered_by.answers.length;i++){
      $('#tab-details #details-filtered-by-code .list-answers').append('<li>' + json.filtered_by.answers[i].text + '</li>');
    }
    $('#tab-details #details-filtered-by-code').show();
  }

}


////////////////////////////////////////////////
// build the visualizations for the explore data page
function build_explore_time_series_page(json){

  build_time_series_charts(json);
  build_datatable(json);
  build_details(json);
  build_page_title(json);

  // if no visible tab is marked as active, mark the first active one
  if ($('#explore-tabs li.active:visible').length == 0){
    // turn on tab and its content
    $('#explore-tabs li:visible:first a').trigger('click'); 
  }
}

////////////////////////////////////////////////
// get data and load page
function get_explore_time_series(is_back_button){

  if (is_back_button == undefined){
    is_back_button = false;
  }

  // build querystring for url and ajax call
  var ajax_data = {};
  var url_querystring = [];
  // add options
  ajax_data.time_series_id = gon.time_series_id;
  ajax_data.access_token = gon.app_api_key;
  ajax_data.with_title = true;
  ajax_data.with_chart_data = true;

  params = queryStringToJSON(window.location.href);

  if (is_back_button && params != undefined){
    // add each param that was in the url
    $.map(params, function(v, k){
      ajax_data[k] = v;
      url_querystring.push(l + '=' + v);
    });

  } else{

    // question code
    if ($('select#question_code').val() != null && $('select#question_code').val() != ''){
      ajax_data.question_code = $('select#question_code').val();
      url_querystring.push('question_code=' + ajax_data.question_code);
    }

    // filtered by
    if ($('select#filtered_by_code').val() != null && $('select#filtered_by_code').val() != ''){
      ajax_data.filtered_by_code = $('select#filtered_by_code').val();
      url_querystring.push('filtered_by_code=' + ajax_data.filtered_by_code);
    }

    // can exclude
    if ($('input#can_exclude').is(':checked')){
      ajax_data.can_exclude = true;
      url_querystring.push('can_exclude=' + ajax_data.can_exclude);
    }

    // add language param from url query string, if it exists
    if (params.language != undefined){
      ajax_data.language = params.language;
      url_querystring.push('language=' + ajax_data.language);
    }

    // private pages require user id
    if (gon.private_user != undefined){
      ajax_data.private_user_id = gon.private_user;
    }
  }

  // call ajax
  $.ajax({
    type: "GET",
    url: gon.api_time_series_analysis_path,
    data: ajax_data,
    dataType: 'json'
  })
  .error(function( jqXHR, textStatus, errorThrown ) {
    //console.log( "Request failed: " + textStatus  + ". Error thrown: " + errorThrown);
  })
  .success(function( json ) {
    json_data = json;

    if (json.errors){
      $('#jumpto-loader').fadeOut('slow');      
      $('#explore-data-loader').fadeOut('slow', function(){
        $('#explore-error').fadeIn('slow').delay(3000).fadeOut('slow');
      });
    }else{
      // update content
      build_explore_time_series_page(json);

      // update url
      var new_url = [location.protocol, '//', location.host, location.pathname, '?', url_querystring.join('&')].join('');

      // change the browser URL to the given link location
      if (!is_back_button && new_url != window.location.href){
        window.history.pushState({path:new_url}, $('title').html(), new_url);
      }

      $('#explore-data-loader').fadeOut('slow');
      $('#jumpto-loader').fadeOut('slow');      
    }


  });
}

////////////////////////////////////////////////
// reset the filter forms and select a random variable for the row
function reset_filter_form(){

  //    $('select#question_code').val('');
  $('select#filtered_by_code').val('');
  $('input#can_exclude').removeAttr('checked');

  // reload the lists
  //    $('select#question_code').selectpicker('refresh');
  $('select#filtered_by_code').selectpicker('refresh');

}

////////////////////////////////////////////////
////////////////////////////////////////////////

$(document).ready(function() {
  // set languaage text
  Highcharts.setOptions({
    chart: { spacingRight: 30 },
    lang: {
      contextButtonTitle: gon.highcharts_context_title
    },
    colors: ['#00adee', '#e88d42', '#9674a9', '#f3d952', '#6fa187', '#b2a440', '#d95d6a', '#737d91', '#d694e0', '#80b5bc', '#a6c449', '#1b74cc', '#4eccae']
  });


  if (gon.explore_time_series){
    // due to using tabs, chart and table cannot be properly drawn
    // because they may be hidden. 
    // this event catches when a tab is being shown to make sure 
    // the item is properly drawn
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
      switch($(this).attr('href')){
        case '#tab-chart':
          $('#container-chart .chart').each(function(){
            $(this).highcharts().reflow();        
          });
          break;
        case '#tab-table':
          var ttInstances = TableTools.fnGetMasters();
          for (i in ttInstances) {
          if (ttInstances[i].fnResizeRequired()) 
            ttInstances[i].fnResizeButtons();
          }
          break;
      }
    });

    // catch the form submit and call the url with the
    // form values in the url
    $("form#form-explore-time-series").submit(function(){
      $('#jumpto-loader').fadeIn('slow');
      $('#explore-data-loader').fadeIn('slow', function(){
        get_explore_time_series();
      });
      return false;
    });

    // reset the form fields
    $("form#form-explore-time-series input#btn-reset").click(function(e){
      e.preventDefault();
      $('#jumpto-loader').fadeIn('slow');
      $('#explore-data-loader').fadeIn('slow', function(){
        reset_filter_form();
        get_explore_time_series();
      });

    });


    // initalize the fancy select boxes
    $('select.selectpicker').selectpicker();    
    $('select.selectpicker-filter').selectpicker();    

    // if option changes, make sure the select option is not available in the other lists
    $('select.selectpicker').change(function(){
      // update filter list
      var question_code = $('select#question_code').val();
      // if filter is one of these values, reset filter to no filter
      if ($('select#filtered_by_code').val() == question_code && question_code != ''){
        // reset value and hide filter answers
        $('select#filtered_by_code').selectpicker('val', '');
      }   
      // mark selected items as disabled
      $('select#filtered_by_code option[disabled="disabled"]').removeAttr('disabled');  
      if (question_code != ''){
        $('select#filtered_by_code option[value="' + question_code + '"]').attr('disabled','disabled');
      }

      // refresh the filter list
      $('select#filtered_by_code').selectpicker('refresh');
      $('select#filtered_by_code').selectpicker('render');

      // update tooltip for selects
      $('form button.selectpicker').tooltip('fixTitle')

      // if selected options have can_exclude, show the checkbox, else hide it
      set_can_exclude_visibility();
    });  

    // update tooltip when filter tooltip changes
    $('select.selectpicker-filter').change(function(){
      $('form button.selectpicker').tooltip('fixTitle')

      // if selected options have can_exclude, show the checkbox, else hide it
      set_can_exclude_visibility();
    });


    // get the initial data
    $('#explore-data-loader').fadeIn('slow', function(){
      get_explore_time_series();
    });


    // jumpto scrolling
    $("#jumpto").on('change', 'select', function(){
      var href = $(this).find('option:selected').data('href');
      $('.tab-pane').animate({
        scrollTop: Math.abs($('.tab-pane.active > div > div:first').offset().top - $('.tab-pane.active ' + href).offset().top)
      }, 1500);
    });

    // when chart tab clicked on, make sure the jumpto block is showing, else, hide it
    $('#explore-tabs li a').click(function(){
      if ($(this).attr('href') == '#tab-chart' && $('#jumpto select option').length > 0){
        $('#jumpto').show();
      }else{
        $('#jumpto').hide();
      }
    });

    // the below code is to override back button to get the ajax content without page reload
    $(window).bind('popstate', function() {

      // pull out the querystring
      params = queryStringToJSON(window.location.href);

      // for each form field, reset if need to
      // question code
      if (params.question_code != $('select#question_code').val()){
        if (params.question_code == undefined){
          $('select#question_code').val('');
        }else{
          $('select#question_code').val(params.question_code);
        }
        $('select#question_code').selectpicker('refresh');
      }

      // filtered by
      if (params.filtered_by_code != $('select#filtered_by_code').val()){
        if (params.filtered_by_code == undefined){
          $('select#filtered_by_code').val('');
        }else{
          $('select#filtered_by_code').val(params.filtered_by_code);
        }
        $('select#filtered_by_code').selectpicker('refresh');
      }

      // can exclude
      if (params.can_exclude == 'true'){
        $('input#can_exclude').attr('checked', 'checked');
      }else{
        $('input#can_exclude').removeAttr('checked');
      }


      // reload the data
      $('#jumpto-loader').fadeIn('slow');
      $('#explore-data-loader').fadeIn('slow', function(){
        get_explore_time_series(true);
      });
    });  
  }
});

