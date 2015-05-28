var datatables, i, j, json_data;



// build highmap
function build_highmaps(json){
  if (json.map){
    // adjust the width of the map to fit its container
    // $('#container-map').width($('#explore-tabs').width());

    // remove all existing maps
    $('#container-map').empty();
    // remove all existing map links
    $('#jumpto #jumpto-map select').empty();
    $('#jumpto #jumpto-map h4').empty().hide();
    var template = $('#jumpto #jumpto-map .jumpto-map-item').clone();
    // remove any existing fancy select list
    $(template).find('div.bootstrap-select').remove();
    // remove all extra jumpto map items
    if ($('#jumpto #jumpto-map .jumpto-map-item').length > 1){
      for (var i=$('#jumpto #jumpto-map .jumpto-map-item').length; i>0; i--){
        $('#jumpto #jumpto-map .jumpto-map-item').splice(i-1,1);
      }
    }

    var jumpto_text = '';
    var non_map_text;
    if (json.broken_down_by){
      non_map_text = json.broken_down_by.text;
      if (json.broken_down_by.is_mappable == true){
        non_map_text = json.question.text;
      }
    }

    // test if the filter is being used and build the chart(s) accordingly
    if (json.map.constructor === Array){
      // filters
      var map_index = 0;
      var jump_ary = [];
      var jump_item;

      for(var h=0; h<json.map.length; h++){
        if (json.broken_down_by && json.map[h].filter_results.map_sets.constructor === Array){
          // add jumpto link
          jump_item = $(template).clone();
          $(jump_item).find('h4').html(json.filtered_by.text + ' = <span>' + json.map[h].filter_answer_text + '</span>');          
          jumpto_text = '<option></option>';

          for(var i=0; i<json.map[h].filter_results.map_sets.length; i++){
            build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.map_sets[i]);

            // add jumpto link
            jumpto_text += '<option data-href="#map-' + (map_index+1) + '">' + non_map_text + ' = ' + json.map[h].filter_results.map_sets[i].broken_down_answer_text + '</option>';

            // increase the map index
            map_index += 1;        
          }

          $(jump_item).find('select').append(jumpto_text);
          jump_ary.push(jump_item);

        }else{
          build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.map_sets);

          // add jumpto link
          jumpto_text += '<option data-href="#map-' + (map_index+1) + '">' + json.filtered_by.text + ' = ' + json.map[h].filter_answer_text + '</option>';

          // increase the map index
          map_index += 1;        
        }
      }

      // show jumpto
      // - if jump_ary exists (filter and broken down), add a drop down for each filter value
      if (jump_ary != undefined && jump_ary.length > 0){
        // remove the existing template
        $('#jumpto #jumpto-map .jumpto-map-item').remove();  
        for (var i=0; i<jump_ary.length; i++){
          $('#jumpto #jumpto-map').append(jump_ary[i]);  

          var select = $('#jumpto #jumpto-map select:last');
          if (i == 0) {
            $(select).find('option:eq(1)').prop('selected', true);
          }
          $(select).selectpicker();
        }
        $('#jumpto #jumpto-map h4').show();
        $('#jumpto #jumpto-map').show();
        $('#jumpto').show();
      }else{
        $('#jumpto #jumpto-map select').append(jumpto_text);
        $('#jumpto #jumpto-map select').val($('#jumpto #jumpto-map select option:first').attr('value'));
        $('#jumpto #jumpto-map select').selectpicker('refresh');
        $('#jumpto #jumpto-map select').selectpicker('render');
        $('#jumpto #jumpto-map').show();
        $('#jumpto').show();
      }

    }else{

      // no filters
      if (json.broken_down_by && json.map.map_sets.constructor === Array){
        for(var i=0; i<json.map.map_sets.length; i++){
          build_highmap(json.map.shape_question_code, json.map.map_sets[i]);

          // add jumpto link
          jumpto_text += '<option data-href="#map-' + (i+1) + '">' + non_map_text + ' = ' + json.map.map_sets[i].broken_down_answer_text + '</option>';
        }

        // show jumpto
        $('#jumpto #jumpto-map select').append(jumpto_text);
        $('#jumpto #jumpto-map select').val($('#jumpto #jumpto-map select option:first').attr('value'));
        $('#jumpto #jumpto-map select').selectpicker('refresh');
        $('#jumpto #jumpto-map select').selectpicker('render');
        $('#jumpto #jumpto-map').show();
        $('#jumpto').show();

      }else{
        build_highmap(json.map.shape_question_code, json.map.map_sets);
  
        // hide jumpto
        $('#jumpto #jumpto-map').hide();
        $('#jumpto').hide();
      }
    }

    // show map tabs
    $('#explore-tabs #nav-map').show();

  }
  else{
    // no map so hide tab
    $('#explore-tabs #nav-map').hide();
    // make sure these are not active
    $('#explore-tabs #nav-map, #explore-content #tab-map').removeClass('active');
  }
}



////////////////////////////////////////////////
// build crosstab charts for each chart item in json
function build_crosstab_charts(json){
  if (json.chart){
    // determine chart height
    var chart_height = crosstab_chart_height(json);

    // remove all existing charts
    $('#container-chart').empty();
    // remove all existing chart links
    $('#jumpto #jumpto-chart select').empty();
    var jumpto_text = '';

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart
        build_crosstab_chart(json.question.original_code, json.broken_down_by.original_code, json.broken_down_by.text, json.chart[i].filter_results, chart_height);

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
      build_crosstab_chart(json.question.original_code, json.broken_down_by.original_code, json.broken_down_by.text, json.chart, chart_height);

      // hide jumpto
      $('#jumpto #jumpt-chart').hide();
      $('#jumpto').hide();
    }
  }
} 





////////////////////////////////////////////////
// build pie chart for each chart item in json
function build_pie_charts(json){
  if (json.chart){
    // determine chart height
    var chart_height = pie_chart_height(json);

    // remove all existing charts
    $('#container-chart').empty();
    // remove all existing chart links
    $('#jumpto #jumpto-chart select').empty();
    var jumpto_text = '';

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart
        build_pie_chart(json.chart[i].filter_results, chart_height);

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
      build_pie_chart(json.chart, chart_height);
  
      // hide jumpto
      $('#jumpto #jumpto-chart').hide();
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

  // build head
  table += "<thead>";

  // test if the filter is being used and build the table accordingly
  if (json.filtered_by == undefined){
    if (json.analysis_type == 'comparative'){
      // 3 headers of:
      //                broken_down_by question
      //                broken_down_by answers .....

      // question code question   count percent count percent .....
      table += "<tr class='th-center'>";
      table += "<th class='var1-col'>" + gon.table_questions_header + "</th>";
      table += "<th class='code-highlight' colspan='" + (2*(json.broken_down_by.answers.length+1)).toString() + "'>";
      table += json.broken_down_by.original_code;
      table += "</th>";
      table += "</tr>";
      
      table += "<tr class='th-center'>";
      table += "<th class='var1-col code-highlight' rowspan='2'>";
      table += json.question.original_code;
      table += "</th>";
      var ln = json.broken_down_by.answers.length;
      for(i=0; i<ln;i++){
        table += "<th colspan='2' class='color"+(ln-i%13)+"'>";
        table += json.broken_down_by.answers[i].text.toString();
        table += "</th>"
      }
      table += "</tr>";

      table += "<tr>";
      // table += "<th class='var1-col code-highlight'>";
      // table += json.question.original_code;
      // table += "</th>";
      for(i=0; i<json.broken_down_by.answers.length;i++){
        table += "<th>";
        table += $('#container-table table').data('count');
        table += "</th>"
        table += "<th>";
        table += $('#container-table table').data('percent');
        table += "</th>"
      }
      table += "</tr>";
    }else{
      // 1 header of: question code question, count, percent
      table += "<tr class='th-center'>";
      table += "<th class='var1-col code-highlight'>";
      table += json.question.original_code;
      table += "</th><th>";
      table += $('#container-table table').data('count');
      table += "</th><th>";
      table += $('#container-table table').data('percent');
      table += "</th></tr>";
    }
  }else{
    if (json.analysis_type == 'comparative'){
      // 3 headers of:
      //                broken_down_by question
      //                broken_down_by answers .....

      // filter question   count percent count percent .....
      table += "<tr class='th-center'>";
      table += "<th class='var1-col' colspan='2'>" + gon.table_questions_header + "</th>";
      table += "<th class='code-highlight' colspan='" + (2*(json.broken_down_by.answers.length+1)).toString() + "'>";
      table += json.broken_down_by.original_code;
      table += "</th>";
      table += "</tr>";

      table += "<tr class='th-center'>";
      table += "<th class='var1-col code-highlight' rowspan='2'>";
      table += json.filtered_by.original_code;
      table += "</th>";
      table += "<th class='var1-col code-highlight' rowspan='2'>";
      table += json.question.original_code;
      table += "</th>";

      var ln = json.broken_down_by.answers.length;
      for(i=0; i<ln;i++){
        table += "<th colspan='2' class='color"+(ln-i%13)+"'>";
        table += json.broken_down_by.answers[i].text.toString();
        table += "</th>"
      }
      table += "</tr>";
      
      table += "<tr>";
      for(i=0; i<json.broken_down_by.answers.length;i++){
        table += "<th>";
        table += $('#container-table table').data('count');
        table += "</th>"
        table += "<th>";
        table += $('#container-table table').data('percent');
        table += "</th>"
      }
      table += "</tr>";

    }else{

      // 1 header of: filter question, count, percent
      table += "<tr class='th-center'>";
      table += "<th class='var1-col'>";
      table += json.filtered_by.original_code;
      table += "</th>";
      table += "<th class='var1-col code-highlight'>";
      table += json.question.original_code;
      table += "</th><th>";
      table += $('#container-table table').data('count');
      table += "</th><th>";
      table += $('#container-table table').data('percent');
      table += "</th></tr>";
    }
  }
  table += "</thead>";


  // build body
  table += "<tbody>";
  if (json.filtered_by == undefined){
    if (json.analysis_type == 'comparative'){
      // cells per row: question code answer, count/percent for each col
      for(i=0; i<json.results.analysis.length; i++){
        table += "<tr>";
        table += "<td class='var1-col' data-order='" + json.question.answers[i].sort_order + "'>";
        table += json.results.analysis[i].answer_text;
        table += "</td>";
        for(j=0; j<json.results.analysis[i].broken_down_results.length; j++){
          table += "<td data-order='" + json.results.analysis[i].broken_down_results[j].count + "'>";
          table += Highcharts.numberFormat(json.results.analysis[i].broken_down_results[j].count,0);
          table += "</td>";
          table += "<td>";
          table += json.results.analysis[i].broken_down_results[j].percent.toFixed(2);
          table += "%</td>";
        }
        table += "</tr>";
      }

    }else{
      
      // cells per row: question code answer, count, percent
      for(i=0; i<json.results.analysis.length; i++){
        table += "<tr>";
        table += "<td class='var1-col' data-order='" + json.question.answers[i].sort_order + "'>";
        table += json.results.analysis[i].answer_text;
        table += "</td><td data-order='" + json.results.analysis[i].count + "'>";
        table += Highcharts.numberFormat(json.results.analysis[i].count,0);
        table += "</td><td>";
        table += json.results.analysis[i].percent.toFixed(2);
        table += "%</td>";
        table += "</tr>";
      }
    }

  }else{

    if (json.analysis_type == 'comparative'){
      // cells per row: filter question code answer, count/percent for each col
      for(h=0; h<json.results.filter_analysis.length; h++){

        for(i=0; i<json.results.filter_analysis[h].filter_results.analysis.length; i++){
          table += "<tr>";
          table += "<td class='var1-col' data-order='" + json.filtered_by.answers[h].sort_order + "'>";
          table += json.results.filter_analysis[h].filter_answer_text;
          table += "</td>";
          table += "<td class='var1-col' data-order='" + json.question.answers[i].sort_order + "'>";
          table += json.results.filter_analysis[h].filter_results.analysis[i].answer_text;
          table += "</td>";

          for(j=0; j<json.results.filter_analysis[h].filter_results.analysis[i].broken_down_results.length; j++){
            table += "<td data-order='" + json.results.filter_analysis[h].filter_results.analysis[i].broken_down_results[j].count + "'>";
            table += Highcharts.numberFormat(json.results.filter_analysis[h].filter_results.analysis[i].broken_down_results[j].count,0);
            table += "</td>";
            table += "<td>";
            table += json.results.filter_analysis[h].filter_results.analysis[i].broken_down_results[j].percent.toFixed(2);
            table += "%</td>";
          }
          table += "</tr>";
        }
      }
    }else{
      // for each filter, show each question and the count/percents
      // cells per row: filter question code answer, count, percent
      for(h=0; h<json.results.filter_analysis.length; h++){

        for(i=0; i<json.results.filter_analysis[h].filter_results.analysis.length; i++){
          table += "<tr>";
          table += "<td class='var1-col' data-order='" + json.filtered_by.answers[h].sort_order + "'>";
          table += json.results.filter_analysis[h].filter_answer_text;
          table += "</td>";
          table += "<td class='var1-col' data-order='" + json.question.answers[i].sort_order + "'>";
          table += json.results.filter_analysis[h].filter_results.analysis[i].answer_text;
          table += "</td>";
          table += "<td data-order='" + json.results.filter_analysis[h].filter_results.analysis[i].count + "'>";
          table += Highcharts.numberFormat(json.results.filter_analysis[h].filter_results.analysis[i].count,0);
          table += "</td>";
          table += "<td>";
          table += json.results.filter_analysis[h].filter_results.analysis[i].percent.toFixed(2);
          table += "%</td>";
          table += "</tr>";
        }
      }
    }
  }

  table += "</tbody>";

  $('#container-table table').html(table);

  // compute how many columns need to have this sort
  var sort_array = [];
  for(var i=1; i<$('#container-table table > thead tr:last-of-type th').length; i++){
    sort_array.push(i);
  }

  // initalize the datatable
  datatables = [];
  $('#container-table table').each(function(){
    datatables.push($(this).dataTable({
      "dom": '<"top"fl>t<"bottom"p><"clear">',
      "language": {
        "url": gon.datatable_i18n_url,
        "search": "_INPUT_",
        "searchPlaceholder": gon.datatable_search,
        "paginate": {
            "first": " ",
            "previous": " ",
            "next": " ",
            "last": " "
        }
      },
      "pagingType": "full_numbers",
      "columnDefs": [
          { "type": "formatted-num", targets: sort_array }
      ],
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
  var details_item = $('#tab-details .details-item').hide(), tmp;
  details_item.find('.name-variable, .notes, .list-answers').empty();
  
  // add questions
  if (json.question && json.question.text && json.question.answers){
    tmp = $('#tab-details #details-question-code');
    tmp.find('.name-variable').html(json.question.text);    
    tmp.find('.name-code').html(json.question.original_code);    
    if (json.question.notes){
      tmp.find('.notes').html(json.question.notes);    
      tmp.find('.details-notes').show();
    }else{
      tmp.find('.details-notes').hide();
    }
    for(var i=0;i<json.question.answers.length;i++){
      tmp.find('.list-answers').append('<li>' + json.question.answers[i].text + '</li>');
    }
    tmp.show();
  }

  // add broken down by
  if (json.broken_down_by && json.broken_down_by.text && json.broken_down_by.answers){
    tmp = $('#tab-details #details-broken-down-by-code');
    tmp.find('.name-variable').html(json.broken_down_by.text);    
    tmp.find('.name-code').html(json.broken_down_by.original_code);    
    if (json.broken_down_by.notes){
      tmp.find('.notes').html(json.broken_down_by.notes);    
      tmp.find('.details-notes').show();
    }else{
      tmp.find('.details-notes').hide();
    }
    for(var i=0;i<json.broken_down_by.answers.length;i++){
      tmp.find('.list-answers').append('<li>' + json.broken_down_by.answers[i].text + '</li>');
    }
    tmp.show();
  }

  // add filters
  if (json.filtered_by && json.filtered_by.text && json.filtered_by.answers){
    tmp = $('#tab-details #details-broken-down-by-code');
    tmp.find('.name-variable').html(json.filtered_by.text);    
    tmp.find('.name-code').html(json.filtered_by.original_code);    
    if (json.filtered_by.notes){
      tmp.find('.notes').html(json.filtered_by.notes);    
      tmp.find('.details-notes').show();
    }else{
      tmp.find('.details-notes').hide();
    }
    for(var i=0;i<json.filtered_by.answers.length;i++){
      tmp.find('.list-answers').append('<li>' + json.filtered_by.answers[i].text + '</li>');
    }
    tmp.show();
  }

}


////////////////////////////////////////////////
// build the visualizations for the explore data page
function build_explore_data_page(json){

  if (json.analysis_type == 'comparative'){
    build_crosstab_charts(json);
  }else{
    build_pie_charts(json);
  }
  build_highmaps(json);
  build_datatable(json);
  build_details(json);

  build_page_title(json);

  // if no visible tab is marked as active, mark the first active one
  if ($('#explore-tabs li.active:visible').length == 0){
    // turn on tab and its content
    $('#explore-tabs li:visible:first a').trigger('click'); 
  }else{
    // make sure correct jumptos are showing
    $('#explore-tabs li.active a').trigger('click');
  }

}

////////////////////////////////////////////////
// get data and load page
function get_explore_data(is_back_button){
//  $('#explore-data-loader').fadeIn('slow');

  if (is_back_button == undefined){
    is_back_button = false;
  }

  // build querystring for url and ajax call
  var ajax_data = {};
  var url_querystring = [];
  // add options
  ajax_data.dataset_id = gon.dataset_id;
  ajax_data.access_token = gon.app_api_key;
  ajax_data.with_title = true;
  ajax_data.with_chart_data = true;
  ajax_data.with_map_data = true;

  params = queryStringToJSON(window.location.href);

  if (is_back_button && params != undefined){
    // add each param that was in the url
    $.map(params, function(v, k){
      ajax_data[k] = v;
      url_querystring.push(k + '=' + v);
    });

  } else{
    // question code
    if ($('select#question_code').val() != null && $('select#question_code').val() != ''){
      ajax_data.question_code = $('select#question_code').val();
      url_querystring.push('question_code=' + ajax_data.question_code);
    }

    // broken down by
    if ($('select#broken_down_by_code').val() != null && $('select#broken_down_by_code').val() != ''){
      ajax_data.broken_down_by_code = $('select#broken_down_by_code').val();
      url_querystring.push('broken_down_by_code=' + ajax_data.broken_down_by_code);
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
    url: gon.api_dataset_analysis_path,
    data: ajax_data,
    dataType: 'json'   
  })
  .error(function( jqXHR, textStatus, errorThrown ) {
    console.log( "Request failed: " + textStatus  + ". Error thrown: " + errorThrown);
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
      build_explore_data_page(json);

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
  $('select#broken_down_by_code').val('');
  $('select#filtered_by_code').val('');
  $('input#can_exclude').removeAttr('checked');

  // reload the lists
  //    $('select#question_code').selectpicker('refresh');
  $('select#broken_down_by_code').selectpicker('refresh');
  $('#btn-swap-vars').hide();
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


  if (gon.explore_data){
    // due to using tabs, the map, chart and table cannot be properly drawn
    // because they may be hidden. 
    // this event catches when a tab is being shown to make sure 
    // the item is properly drawn
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
      switch($(this).attr('href')){
        case '#tab-map':
          $('#container-map .map').each(function(){
            $(this).highcharts().reflow();        
          });
          break;
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
    $("form#form-explore-data").submit(function(){
      $('#jumpto-loader').fadeIn('slow');
      $('#explore-data-loader').fadeIn('slow', function(){
        get_explore_data();
      });
      return false;
    });

    // reset the form fields
    $("form#form-explore-data input#btn-reset").click(function(e){
      e.preventDefault();
      $('#jumpto-loader').fadeIn('slow');
      $('#explore-data-loader').fadeIn('slow', function(){
        reset_filter_form();
        get_explore_data();
      });

    });


    // initalize the fancy select boxes
    $('select.selectpicker').selectpicker();    
    $('select.selectpicker-filter').selectpicker();    

    // if option changes, make sure the select option is not available in the other lists
    $('select.selectpicker').change(function(){
      val = $(this).val();
      // if this is question, update broken down by
      // else, vice-versa
      if ($(this).attr('id') == 'question_code'){
        // update broken down by list
        // remove all disabled
        $('select#broken_down_by_code option[disabled="disabled"]').removeAttr('disabled');  
        // disable the new selection
        $('select#broken_down_by_code option[value="' + val + '"]').attr('disabled', 'disabled');
        // update the select list
        $('select#broken_down_by_code').selectpicker('refresh');
      }else if ($(this).attr('id') == 'broken_down_by_code'){
        // update question list
        // remove all disabled
        $('select#question_code option[disabled="disabled"]').removeAttr('disabled');  
        // disable the new selection
        $('select#question_code option[value="' + val + '"]').attr('disabled', 'disabled');
        // update the select list
        $('select#question_code').selectpicker('refresh');

        // if val != '' then turn on swap button
        if (val == ''){
          $('button#btn-swap-vars').fadeOut();
        }else{
          $('button#btn-swap-vars').fadeIn();
        }
      }

      // update filter list
      var q = $('select#question_code').val();
      var bdb = $('select#broken_down_by_code').val();
      // if filter is one of these values, reset filter to no filter
      if (($('select#filtered_by_code').val() == q && q != '') || ($('select#filtered_by_code').val() == bdb && bdb != '')){
        // reset value and hide filter answers
        $('select#filtered_by_code').selectpicker('val', '');
      }   
      // mark selected items as disabled
      $('select#filtered_by_code option[disabled="disabled"]').removeAttr('disabled');  
      if (q != ''){
        $('select#filtered_by_code option[value="' + q + '"]').attr('disabled','disabled');
      }
      if (bdb != ''){
        $('select#filtered_by_code option[value="' + bdb + '"]').attr('disabled','disabled');
      }
      $('select#filtered_by_code').selectpicker('refresh');
      $('select#filtered_by_code').selectpicker('render');
    });  

    // swap vars button
    // - when clicked, swap the values and then submit the form
    $('button#btn-swap-vars').click(function(){
      // get the vals
      var var1 = $('select#question_code').val();
      var var2 = $('select#broken_down_by_code').val();

      // turn off disabled options
      // so can select in next step
      $('select#question_code option[value="' + var2 + '"]').removeAttr('disabled');
      $('select#broken_down_by_code option[value="' + var1 + '"]').removeAttr('disabled');

      // refresh so disabled options are removed
      $('select#question_code').selectpicker('refresh');
      $('select#broken_down_by_code').selectpicker('refresh');

      // swap the vals
      $('select#question_code').selectpicker('val', var2);
      $('select#broken_down_by_code').selectpicker('val', var1);

      $('select#question_code').selectpicker('render');
      $('select#broken_down_by_code').selectpicker('render');

      // disable the swapped values
      $('select#question_code option[value="' + var1 + '"]').attr('disabled', 'disabled');
      $('select#broken_down_by_code option[value="' + var2 + '"]').attr('disabled', 'disabled');

      // refresh so disabled options are updated
      $('select#question_code').selectpicker('refresh');
      $('select#broken_down_by_code').selectpicker('refresh');

      // submit the form
      $('input#btn-submit').trigger('click');
    });

    // get the initial data
    $('#explore-data-loader').fadeIn('slow', function(){
      get_explore_data();
    });

    // jumpto scrolling
    $("#jumpto").on('change', 'select', function(){
      var href = $(this).find('option:selected').data('href');
      $('.tab-pane').animate({
        scrollTop: $(href).offset().top - 120
      }, 1500);

      // if this is a map item and there are > 1 map items, make sure the other items are set to nil
      var select_index = $('#jumpto #jumpto-map select').index($(this));
      if ($(this).closest('#jumpto-map').length > 0 && $(this).closest('#jumpto-map').find('.jumpto-map-item').length > 1){
        $('#jumpto #jumpto-map select').each(function(i){
          if (i != select_index){
            $(this).find('option:eq(0)').prop('selected', true);
            $(this).selectpicker('refresh');
          }
        });
      }
    });

    // when chart tab/map clicked on, make sure the jumpto block is showing, else, hide it
    $('#explore-tabs li a').click(function(){
      console.log('tab click = ' + $(this).attr('href'));
      if ($(this).attr('href') == '#tab-chart' && $('#jumpto #jumpto-chart select option').length > 0){
        $('#jumpto').show();
        $('#jumpto #jumpto-chart').show();
        $('#jumpto #jumpto-map').hide();
      }else if ($(this).attr('href') == '#tab-map' && $('#jumpto #jumpto-map select option').length > 0){
        $('#jumpto').show();
        $('#jumpto #jumpto-map').show();
        $('#jumpto #jumpto-chart').hide();
      }else{
        $('#jumpto').hide();
        $('#jumpto #jumpto-chart').hide();
        $('#jumpto #jumpto-map').hide();
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

      // broken down by code
      if (params.broken_down_by_code != $('select#broken_down_by_code').val()){
        if (params.broken_down_by_code == undefined){
          $('select#broken_down_by_code').val('');
        }else{
          $('select#broken_down_by_code').val(params.broken_down_by_code);
        }
        $('select#broken_down_by_code').selectpicker('refresh');
      }
      if ($('select#broken_down_by_code').val() == ''){
        $('#btn-swap-vars').hide();
      }else{
        $('#btn-swap-vars').show();
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
      $('#explore-data-loader').fadeIn('slow', function(){
        get_explore_data(true);
      });
    });  
  }
});