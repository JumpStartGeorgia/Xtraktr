var datatable, i, j, json_data;

////////////////////////////////////////////////
// build time series line chart
function build_time_series_chart(json){
  if (json.chart && json.chart.data){
    // set languaage text
    Highcharts.setOptions({
      lang: {
        contextButtonTitle: gon.highcharts_context_title
      }
    });


    $('#chart').highcharts({
      chart: {
          plotBackgroundColor: null,
          plotBorderWidth: null,
          plotShadow: false
      },
      title: {
          text: json.title.html,
          useHTML: true,
          style: {'text-align': 'center'}
      },
      subtitle: {
          text: json.subtitle.html,
          useHTML: true,
          style: {'text-align': 'center', 'margin-top': '-15px'}
      },
      xAxis: {
          categories: json.datasets
      },
      yAxis: {
          title: {
              text: '%'
          },
          max: 100,
          min: 0,
          plotLines: [{
              value: 0,
              width: 1,
              color: '#808080'
          }]
      },
      tooltip: {
          headerFormat: '<span style="font-size: 13px; font-style: italic; font-weight: bold;">{point.key}</span><br/>',
          pointFormat: '<span style="font-weight: bold;">{series.name}</span>: {point.count:,.0f} ({point.y:.2f}%)<br/>',
      },
      legend: {
          symbolHeight: 14,
          itemMarginBottom: 5,
          itemStyle: { "color": "#333333", "cursor": "pointer", "fontSize": "14px", "fontWeight": "bold" }
      },
      series: json.chart.data,
      exporting: {
        sourceWidth: 1280,
        sourceHeight: 720,
        filename: json.title.text,
        chartOptions:{
          title: {
            text: json.title.text
          },
          subtitle: {
            text: json.subtitle.text
          }
        },
        buttons: {
          contextButton: {
            menuItems: [
              {
                text: gon.highcharts_png,
                onclick: function () {
                    this.exportChart({type: 'image/png'});
                }
              }, 
              {
                text: gon.highcharts_jpg,
                onclick: function () {
                    this.exportChart({type: 'image/jpeg'});
                }
              }, 
              {
                text: gon.highcharts_pdf,
                onclick: function () {
                    this.exportChart({type: 'application/pdf'});
                }
              }, 
              {
                text: gon.highcharts_svg,
                onclick: function () {
                    this.exportChart({type: 'image/svg+xml'});
                }
              }
            ]
          }
        }
      }
    });
  }
}



////////////////////////////////////////////////
// build data table
function build_datatable(json){
  // set the title
  $('#tab-table h3').html(json.title.html + json.subtitle.html);

  // if the datatable alread exists, kill it
  if (datatable != undefined){
    datatable.fnDestroy();
  }


  // build the table
  var table = '';

  // build head
  table += "<thead>";
  // 1 header of: row question, count, percent
  table += "<tr class='th-center'>";
  table += "<th class='var1-col'>";
  table += json.row_question;
  table += "</th><th>";
  table += $('#datatable').data('count');
  table += "</th><th>";
  table += $('#datatable').data('percent');
  table += "</th></tr>";
  table += "</thead>";

  // build body
  table += "<tbody>";
  // cells per row: row answer, count, percent
  // for(i=0; i<json.row_answers.length; i++){
  //   table += "<tr>";
  //   table += "<td class='var1-col' data-order='" + json.row_answers[i].sort_order + "'>";
  //   table += json.row_answers[i].text;
  //   table += "</td><td data-order='" + json.counts[i] + "'>";
  //   table += Highcharts.numberFormat(json.counts[i],0);
  //   table += "</td><td>";
  //   table += json.percents[i].toFixed(2);
  //   table += "%</td>";
  //   table += "</tr>";
  // }

  table += "</tbody>";

  $('#datatable').html(table);

  // compute how many columns need to have this sort
  var sort_array = [];
  for(var i=1; i<$('#datatable > thead tr:last-of-type th').length; i++){
    sort_array.push(i);
  }

  // initalize the datatable
  datatable = $('#datatable').dataTable({
    "dom": '<"top"fT>t<"bottom"lpi><"clear">',
    "language": {
      "url": gon.datatable_i18n_url
    },
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
  });    

}

////////////////////////////////////////////////
// build details (question and possible answers)
function build_details(json){
  // clear out content first
  $('#tab-details #details-row-question, #tab-details #details-row-answers').html('');

  // add row question/answers
  if (json.row_question && json.row_answers){
    $('#tab-details #details-row-question').html(json.row_question);    
    for(var i=0;i<json.row_answers.length;i++){
      $('#tab-details #details-row-answers').append('<li>' + json.row_answers[i].text + '</li>');
    }
  }

}

////////////////////////////////////////////////
// build the visualizations for the explore data page
function build_explore_time_series_page(json){

  build_time_series_chart(json);
  build_datatable(json);
  build_details(json);

  // if no visible tab is marked as active, mark the first active one
  if ($('#explore-tabs li.active:visible').length == 0){
    // turn on tab and its content
    $('#explore-tabs li:visible:first a').trigger('click'); 
  }
}

////////////////////////////////////////////////
// get data and load page
function get_explore_time_series(is_back_button){
//  $('#explore-time-series-loader').fadeIn('slow');

  if (is_back_button == undefined){
    is_back_button = false;
  }
  // get params
  // do not get any hidden fields (utf8 and authenticity token)
  var querystring;
  if (is_back_button){
    var split = window.location.href.split('?');
    if (split.length == 2){
      querystring = split[1];
    }
  } else{
    querystring = $("form#form-explore-time-series select, form#form-explore-time-series input:not([type=hidden])").serialize();

    // add language param from url query string, if it exists
    params = queryStringToJSON(window.location.href);
    if (params.language != undefined){
      querystring += "&language=" + params.language;
    }
  }

  // call ajax
  $.ajax({
    type: "GET",
    url: gon.explore_time_series_ajax_path,
    data: querystring,
    dataType: 'json'
  })
  .error(function( jqXHR, textStatus, errorThrown ) {
    console.log( "Request failed: " + textStatus  + ". Error thrown: " + errorThrown);
  })
  .success(function( json ) {
    json_data = json;
    // update content
    build_explore_time_series_page(json);

    // update url
    var new_url = [location.protocol, '//', location.host, location.pathname, '?', querystring].join('');

    // change the browser URL to the given link location
    if (!is_back_button && new_url != window.location.href){
      window.history.pushState({path:new_url}, '', new_url);
    }

    $('#explore-time-series-loader').fadeOut('slow');

  });
}

////////////////////////////////////////////////
// reset the filter forms and select a random variable for the row
function reset_filter_form(){

  //    $('select#row').val('');
  $('select#filter_variable').val('');
  $('select#filter_value').val('');
  $('input#exclude_dkra').removeAttr('checked');

  // reload the lists
  //    $('select#row').selectpicker('refresh');
  $('#btn-swap-vars').hide();
  $('select#filter_variable').selectpicker('refresh');
  $('select#filter_value').selectpicker('refresh');
  $('#filter_value_container').hide();

}

////////////////////////////////////////////////
////////////////////////////////////////////////

$(document).ready(function() {
  if (gon.explore_time_series){
    // turn on tooltip for dataset description
    $('#dataset-description').tooltip();

    // due to using tabs, chart and table cannot be properly drawn
    // because they may be hidden. 
    // this event catches when a tab is being shown to make sure 
    // the item is properly drawn
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
      switch($(this).attr('href')){
        case '#tab-table':
          var ttInstances = TableTools.fnGetMasters();
          for (i in ttInstances) {
          if (ttInstances[i].fnResizeRequired()) 
            ttInstances[i].fnResizeButtons();
          }
          break;
        case '#tab-chart':
          $('#chart').highcharts().reflow();        
          break;
      }
    });

    // catch the form submit and call the url with the
    // form values in the url
    $("form#form-explore-time-series").submit(function(){
      $('#explore-time-series-loader').fadeIn('slow', function(){
        get_explore_time_series();
      });
      return false;
    });

    // reset the form fields
    $("form#form-explore-time-series input#btn-reset").click(function(e){
      e.preventDefault();
      $('#explore-time-series-loader').fadeIn('slow', function(){
        reset_filter_form();
        get_explore_time_series();
      });

    });


    // initalize the fancy select boxes
    $('select.selectpicker').selectpicker();    
    $('select.selectpicker-filter').selectpicker();    

    // if filter variable is selected, update the filter values list
    $('select#filter_variable').change(function(){
      var value = $(this).val();

      if (value == ''){
        // no filter, so hide the filter values
        $('#filter_value_container').fadeOut();
        // mark all disabled
        $('select#filter_value option:not([disabled])').attr('disabled','disabled');
      }else{
        // mark all disabled
        $('select#filter_value option:not([disabled])').attr('disabled','disabled');

        // turn on the values that have the filter variable value
        $('select#filter_value option[data-code="' + value + '"]').removeAttr('disabled');

        // show list
        $('#filter_value_container').fadeIn();
      }

      // reload the list, selecting the first item in the list
      $('select#filter_value option[data-code="' + value + '"]:first').attr('selected', 'selected');
      $('select#filter_value').selectpicker('refresh');
      $('select#filter_value').selectpicker('render');

    });

    // to be able to sort the jquery datatable build in the function below
    // - coming in as: xx (xx.xx%); want to only keep first number
    jQuery.fn.dataTableExt.oSort['formatted-num-asc'] = function ( a, b ) {
      var x = a.match(/\d/) ? a.replace( /\s\(\d{0,}.?\d{0,}\%\)/g, "" ) : 0;
      var y = b.match(/\d/) ? b.replace( /\s\(\d{0,}.?\d{0,}\%\)/g, "" ) : 0;
      return parseFloat(x) - parseFloat(y);
    };

    jQuery.fn.dataTableExt.oSort['formatted-num-desc'] = function ( a, b ) {
      var x = a.match(/\d/) ? a.replace( /\s\(\d{0,}.?\d{0,}\%\)/g, "" ) : 0;
      var y = b.match(/\d/) ? b.replace( /\s\(\d{0,}.?\d{0,}\%\)/g, "" ) : 0;
      return parseFloat(y) - parseFloat(x);
    };

    // get the initial data
    $('#explore-time-series-loader').fadeIn('slow', function(){
      get_explore_time_series();
    });

    // the below code is to override back button to get the ajax content without page reload
    $(window).bind('popstate', function() {

      // pull out the querystring
      params = queryStringToJSON(window.location.href);

      // for each form field, reset if need to
      // row
      if (params.row != $('select#row').val()){
        if (params.row == undefined){
          $('select#row').val('');
        }else{
          $('select#row').val(params.row);
        }
        $('select#row').selectpicker('refresh');
      }

      // filter variable
      if (params.filter_variable != $('select#filter_variable').val()){
        if (params.filter_variable == undefined){
          $('select#filter_variable').val('');
        }else{
          $('select#filter_variable').val(params.filter_variable);
        }
        $('select#filter_variable').selectpicker('refresh');
      }

      // filter value
      if (params.filter_variable == ''){
        // no filter, so hide the filter values
        $('#filter_value_container').fadeOut();
        // mark all disabled
        $('select#filter_value option:not([disabled])').attr('disabled','disabled');
      } else{
        // deselect what is there
        $('select#filter_value').val('');

        // mark all disabled
        $('select#filter_value option:not([disabled])').attr('disabled','disabled');

        // turn on the values that have the filter variable value
        $('select#filter_value option[data-code="' + params.filter_variable + '"]').removeAttr('disabled');

        // set the value
        $('select#filter_value option[data-code="' + params.filter_variable + '"][value="' + params.filter_value + '"]').attr('selected', 'selected');

        // show list
        $('#filter_value_container').fadeIn();
      }
      $('select#filter_value').selectpicker('refresh');

      // exclude dkra
      if (params.exclude_dkra == 'true'){
        $('input#exclude_dkra').attr('checked', 'checked');
      }else{
        $('input#exclude_dkra').removeAttr('checked');
      }

      // reload the data
      $('#explore-time-series-loader').fadeIn('slow', function(){
        get_explore_time_series(true);
      });
    });  
  }
});

