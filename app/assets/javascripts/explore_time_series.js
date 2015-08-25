var datatables, i, j, json_data;

// update the list of avilable weights based on questions that are selected
function update_available_weights(){
  // update weight list if weights exist
  if ($('select#weighted_by_code').length > 0){
    var old_value = $('select#weighted_by_code').val();
    var items = [
      $('select#question_code option:selected').data('weights'),
      $('select#filtered_by_code option:selected').data('weights')
    ];
    // remove undefined (undefined exists if a select does not have a value)
    var und_ind = items.indexOf(undefined);
    while(und_ind != -1){
      if (und_ind != -1){
        items.splice(und_ind, 1);
      }
      und_ind = items.indexOf(undefined);
    }
    var matches = items.shift().filter(function(v) {
      return items.every(function(a) {
        return a.indexOf(v) !== -1;
      });
    });

    // if there are matches, show the weights that match, and unweighted
    // else hide weight option and set value to unweighted
    if (matches.length > 0){
      // show matches, hide rest

      // hide all items
      $('.form-explore-weight-by .bootstrap-select ul.dropdown-menu li').hide();

      // show matched weights
      var match_length = matches.length;
      var i=0;
      var index;
      for (i;i<match_length;i++){
        index = $('select#weighted_by_code option[value="' + matches[i] + '"]').index();
        if (index != -1){
          $('.form-explore-weight-by .bootstrap-select ul.dropdown-menu li:eq(' + index + ')').show();
        }
      }
      // show unweighted
      $('.form-explore-weight-by .bootstrap-select ul.dropdown-menu li:last').show();

      // if the old value is no longer an option, select the first one
      if (matches.indexOf(old_value) == -1){
        $('select#weighted_by_code').selectpicker('val', $('select#weighted_by_code option:first').attr('value'));
      }

      $('.form-weight-by').show();
    }else{
      $('.form-weight-by').hide();
      $('select#weighted_by_code').selectpicker('val', 'unweighted');
    }
  }
}

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
    $('#jumpto #jumpto-chart select').empty();
    var jumpto_text = '';
    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart
        build_time_series_chart(json.chart[i].filter_results, chart_height, weight_name);

        // add jumpto link
        jumpto_text += '<option data-href="#chart-' + (i+1) + '">' + json.filtered_by.text + ' = ' + json.chart[i].filter_answer_text + '</option>';
      }

      // show jumpto links
      $('#jumpto #jumpto-chart select').append(jumpto_text);
      $('#jumpto #jumpto-chart select').val($('#jumpto #jumpto-chart select option:first').attr('value'));
      $('#jumpto #jumpto-chart select').selectpicker('refresh');
      $('#jumpto #jumpto-chart select').selectpicker('render');
      $('#jumpto #jumpto-chart').show();
      $('#jumpto').show();

    }else{
      // no filters
      build_time_series_chart(json.chart, chart_height, weight_name);

      // hide jumpto
      $('#jumpto #jumpt-chart').hide();
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

  var col_headers = ['count', 'percent'];

  // test if data is weighted so can build table accordingly
  var is_weighted = json.weighted_by != undefined
  if (is_weighted){
    col_headers = ['unweighted-count', 'weighted-count', 'weighted-percent'];
  }
  var col_header_count = col_headers.length;

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
      table += "<th colspan='" + col_header_count + "' class='code-highlight color"+(i % 13 + 1)+"'>";
      table += json.datasets[i].label;
      table += "</th>"
    }
    table += "</tr>";
    table += "<tr>";
    table += "<th class='var1-col code-highlight'>";
    table += json.question.original_code;
    table += "</th>";
    for(i=0; i<json.datasets.length;i++){
      for(j=0; j<col_header_count;j++){
        table += "<th>";
        table += $('#container-table table').data(col_headers[j]);
        table += "</th>";
      }
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
        for(k=0; k<col_header_count;k++){
          // key is written with '-' but for this part, it must be '_'
          key_text = col_headers[k].replace('-', '_');
          // percent is the last item and all items before are percent
          if (k < col_header_count-1){
            table += "<td data-order='" + json.results.analysis[i].dataset_results[j][key_text] + "'>";
            table += Highcharts.numberFormat(json.results.analysis[i].dataset_results[j][key_text],0);
            table += "</td>";
          }else{
            table += "<td>";
            if (json.results.analysis[i].dataset_results[j][key_text]){
              table += json.results.analysis[i].dataset_results[j][key_text].toFixed(2);
            }else{
              table += '0';
            }
            table += "%"
            table += "</td>";
          }
        }
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
      table += "<th colspan='" + col_header_count + "' class='code-highlight color"+(i % 13 + 1)+"'>";
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
      for(j=0; j<col_header_count;j++){
        table += "<th>";
        table += $('#container-table table').data(col_headers[j]);
        table += "</th>";
      }
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
          for(k=0; k<col_header_count;k++){
            // key is written with '-' but for this part, it must be '_'
            key_text = col_headers[k].replace('-', '_');
            // percent is the last item and all items before are percent
            if (k < col_header_count-1){
              table += "<td data-order='" + json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j][key_text] + "'>";
              table += Highcharts.numberFormat(json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j][key_text],0);
              table += "</td>";
            }else{
              table += "<td>";
              if (json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j][key_text]){
                table += json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j][key_text].toFixed(2);
              }else{
                table += '0';
              }
              table += "%"
              table += "</td>";
            }
          }
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

  // if data is weighted, show footnote
  if (json.weighted_by){
    $('#tab-table .table-weighted-footnote .footnote-weight-name').html(json.weighted_by.weight_name);
    $('#tab-table .table-weighted-footnote').show();
  }else{
    $('#tab-table .table-weighted-footnote .footnote-weight-name').empty();
    $('#tab-table .table-weighted-footnote').hide();
  }

}

////////////////////////////////////////////////
// populat a details item block
function build_details_item(selector, json_question){
  if (json_question && json_question.text){
    var tmp = $(selector);
    if (tmp.length > 0){
      tmp.find('.name-variable').html(json_question.text);

      tmp.find('.name-code').html(json_question.original_code);
      if (json_question.notes){
        tmp.find('.notes').html(json_question.notes);
        tmp.find('.details-notes').show();
      }else{
        tmp.find('.details-notes').hide();
      }
      if (json_question.weight_name){
        tmp.find('.weight').html(json_question.weight_name);
        tmp.find('.details-weight').show();
      }else{
        tmp.find('.details-weight').hide();
      }
      if (json_question.group){
        tmp.find('.name-group .group-title').html(json_question.group.title);
        if (json_question.group.description != ''){
          tmp.find('.name-group .group-description').html(' - ' + json_question.group.description);
        }
        tmp.find('.details-group').show();
      }else{
        tmp.find('.details-group').hide();
      }
      if (json_question.subgroup){
        tmp.find('.name-subgroup .group-title').html(json_question.subgroup.title);
        if (json_question.subgroup.description != ''){
          tmp.find('.name-subgroup .group-description').html(' - ' + json_question.subgroup.description);
        }
        tmp.find('.details-subgroup').show();
      }else{
        tmp.find('.details-subgroup').hide();
      }
      if (json_question.answers){
        for(var i=0;i<json_question.answers.length;i++){
          icon = '';
          if (json_question.answers[i].exclude){
            icon += $('.details-icons #detail-icon-exclude-answer')[0].outerHTML;
          }
          tmp.find('.list-answers').append('<li>' + icon + json_question.answers[i].text + '</li>');
        }
        tmp.find('.details-answers').show();
      }else{
        tmp.find('.details-answers').hide();
      }
      tmp.show();
    }
  }
}

// build details (question and possible answers)
function build_details(json){
  // clear out existing content and hide
  var details_item = $('#tab-details .details-item').hide();
  details_item.find('.name-group .group-title, .name-group .group-description, .name-subgroup .group-title, .name-subgroup .group-description, .name-variable, .name-code, .notes, .list-answers').empty();

  // add questions
  build_details_item('#tab-details #details-question-code', json.question);

  // add filters
  build_details_item('#tab-details #details-filtered-by-code', json.filtered_by);

  // add weight
  build_details_item('#tab-details #details-weighted-by-code', json.weighted_by);
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

    // weighted by
    if ($('select#weighted_by_code').val() != null && $('select#weighted_by_code').val() != ''){
      ajax_data.weighted_by_code = $('select#weighted_by_code').val();
      url_querystring.push('weighted_by_code=' + ajax_data.weighted_by_code);
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
      $('#explore-data-loader').fadeOut('slow');
      $('#explore-error').fadeIn('slow');
    }else if ((json.results.analysis && json.results.analysis.length == 0) || json.results.filtered_analysis && json.results.filtered_analysis.length == 0){
      $('#jumpto-loader').fadeOut('slow');
      $('#explore-data-loader').fadeOut('slow');
      $('#explore-no-results').fadeIn('slow');
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
    colors: ['#C6CA53', '#7DAA92', '#725752', '#E29A27', '#998746', '#A6D3A0', '#808782', '#B4656F', '#294739', '#1B998B', '#7DAA92', '#BE6E46', '#565264']
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
      $('#explore-error').fadeOut('slow');
      $('#explore-no-results').fadeOut('slow');
      $('#explore-data-loader').fadeIn('slow', function(){
        get_explore_time_series();
      });
      return false;
    });

    // reset the form fields
    $("form#form-explore-time-series input#btn-reset").click(function(e){
      e.preventDefault();
      $('#jumpto-loader').fadeIn('slow');
      $('#explore-error').fadeOut('slow');
      $('#explore-no-results').fadeOut('slow');
      $('#explore-data-loader').fadeIn('slow', function(){
        reset_filter_form();
        get_explore_time_series();
      });

    });


    // initalize the fancy select boxes
    $('select.selectpicker').selectpicker();
    $('select.selectpicker-filter').selectpicker();
    $('select.selectpicker-weight').selectpicker();

    // if an option has data-disabled when page loads, make sure it is hidden in the selectpicker
    $('select#question_code option[data-disabled="disabled"]').each(function(){
      $('.form-explore-question-code .bootstrap-select ul.dropdown-menu li:eq(' + $(this).index() + ')').hide();
    });
    $('select#filtered_by_code option[data-disabled="disabled"]').each(function(){
      $('.form-explore-filter-by .bootstrap-select ul.dropdown-menu li:eq(' + $(this).index() + ')').hide();
    });

    // make sure the correct weights are being shown
    update_available_weights();

    // if option changes, make sure the select option is not available in the other lists
    $('select.selectpicker').change(function(){
      val = $(this).val();
      index = $(this).find('option[value="' + val + '"]').index();

      // update filter list
      var q = $('select#question_code').val();
      var q_index = $('select#question_code option[value="' + q + '"]').index();
      // if filter is one of these values, reset filter to no filter
      if ($('select#filtered_by_code').val() == q && q != ''){
        // reset value and hide filter answers
        $('select#filtered_by_code').selectpicker('val', '');
      }

      // turn on all hidden items
      $('.form-explore-filter-by .bootstrap-select ul.dropdown-menu li[style*="display: none"]').show();

      // turn off this item
      if (q_index != -1){
        $('.form-explore-filter-by .bootstrap-select ul.dropdown-menu li:eq(' + (q_index + 1) + ')').hide();
      }

      // update the list of weights
      update_available_weights();

      // update tooltip for selects
      $('form button.dropdown-toggle').tooltip('fixTitle');

      // if selected options have can_exclude, show the checkbox, else hide it
      set_can_exclude_visibility();
    });

    // update tooltip when filter tooltip changes
    $('select.selectpicker-filter').change(function(){
      // if selected options have can_exclude, show the checkbox, else hide it
      set_can_exclude_visibility();

      // update the list of weights
      update_available_weights();

      $('form button.dropdown-toggle').tooltip('fixTitle');
    });

    // update tooltip when weight tooltip changes
    $('select.selectpicker-weight').change(function(){
      $('form button.dropdown-toggle').tooltip('fixTitle');
    });

    // get the initial data
    $('#explore-error').fadeOut('slow');
    $('#explore-no-results').fadeOut('slow');
    $('#explore-data-loader').fadeIn('slow', function(){
      get_explore_time_series();
    });


    // jumpto scrolling
    $("#jumpto").on('change', 'select', function(){
      var href = $(this).find('option:selected').data('href');
      $('.tab-pane.active').animate({
        scrollTop: Math.abs($('.tab-pane.active > div > div:first').offset().top - $('.tab-pane.active ' + href).offset().top)
      }, 1500);
    });

    // when chart tab clicked on, make sure the jumpto block is showing, else, hide it
    $('#explore-tabs li a').click(function(){
      var ths_link = $(this).find('a');

      if ($(ths_link).attr('href') == '#tab-chart' && $('#jumpto #jumpto-chart select option').length > 0){
        $('#jumpto').show();
        $('#jumpto #jumpto-chart').show();
      }else{
        $('#jumpto').hide();
        $('#jumpto #jumpto-chart').hide();
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
      $('#explore-error').fadeOut('slow');
      $('#explore-no-results').fadeOut('slow');
      $('#explore-data-loader').fadeIn('slow', function(){
        get_explore_time_series(true);
      });
    });
  }
});
