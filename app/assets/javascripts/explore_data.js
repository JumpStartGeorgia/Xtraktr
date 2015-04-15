var geojson, datatables, i, j, json_data, highmap;


////////////////////////////////////////////////
////////////////////////////////////////////////


////////////////////////////////////////////////
// build highmap
function build_highmap(json, filter){
  if (json.map && json.map.data){

    // adjust the width of the map to fit its container
    $('#highmap').width($('#explore-tabs').width());

    // set variables according to whether or not map is crosstab
    var data, title_html, title_text, filter_name;
    if (json.analysis_type == 'comparative'){
      // if filter passed in, just get the data for that filter
      // else, build filter and use first item in list for data
      if (filter == undefined){
        // create filter
        // header text
        $('#highmap-filter-container #highmap-filter-header').html($('#highmap-filter-container #highmap-filter-header').data('orig').replace('[replace]', json.map.filter));
        // show first item by default
        $('#highmap-filter-container #highmap-default-id').html(json.map.filters[0].text);
        // empty the exist list items
        $('#highmap-filter-container ul').empty();
        // build drop down lists
        for(i=0; i<json.map.filters.length; i++){
          $('#highmap-filter-container ul').append('<li class="map_filter"><a href="#" data-id="' + json.map.filters[i].value + '">' + json.map.filters[i].text + '</a></li>');
        }      
        // turn on filter
        $('#highmap-filter-container').show();

        // map filter click event
        $('#highmap-filter-container ul li.map_filter a').on('click', function(e) {
          e.preventDefault();
          
          var name = $(this).html();
          var data_id = $(this).data("id");
          $('span#highmap-default-id').text(name);

          // show loading screen
          highmap.showLoading();

          // reload the map
          build_highmap(json_data, data_id);
          
        });

        data = json.map.data[json.map.filters[0].value];
        filter_name = json.map.filters[0].text;       
        title_html = json.map.title.html.replace('[replace]', filter_name);
        title_text = json.map.title.text.replace('[replace]', filter_name);
      }else{
        data = json.map.data[filter];
        filter_name = $('#highmap-filter-container ul li a[data-id="' + filter + '"]').html();       
        title_html = json.map.title.html.replace('[replace]', filter_name);
        title_text = json.map.title.text.replace('[replace]', filter_name);
      }

    }else{
      // turn off filter
      $('#highmap-filter-container').hide();

      data = json.map.data;
      title_html = json.map.title.html;
      title_text = json.map.title.text;

    }

    $('#highmap').highcharts('Map', {
        chart:{
          events: {
            load: function () {
              if (this.options.chart.forExport) {
                  Highcharts.each(this.series, function (series) {
                    // only show data labels for shapes that have data
                    if (series.name != 'baseLayer'){
                      series.update({
                        dataLabels: {
                          enabled: true,
                          color: 'white',
                          formatter: function () {
                            return this.point.properties.display_name + '<br/>' + Highcharts.numberFormat(this.point.count, 0) + '   (' + this.point.value + '%)';
                          }
                        }
                      }, false);
                    }
                });
                this.redraw();
              }
            }
          }          
        },
        title: {
            text: title_html,
            useHTML: true,
            style: {'text-align': 'center', 'font-size': '16px', 'color': '#888'}
        },
        subtitle: {
            text: json.map.subtitle.html,
            useHTML: true,
            style: {'text-align': 'center', 'margin-top': '-15px'}
        },

        mapNavigation: {
            enabled: true,
            buttonOptions: {
                verticalAlign: 'top'
            }
        },
        colorAxis: {
          min: 0,
          max: 100, 
  //            minColor: '#efeaea',
  //            maxColor: '#662E2E',
          labels: {
              formatter: function () {
                return this.value + '%';
              },
          },
        },
        loading: {
          labelStyle: {
            color: 'white',
            fontSize: '20px'
          },
          style: {
            backgroundColor: '#000'
          }
        },
        series : [{
            // create base layer for N/A
            // will be overriden with next data series if data exists
            data : Highcharts.geojson(highmap_shapes[json.map.question_code], 'map'),
            name: 'baseLayer',
            color: '#eeeeee',
            showInLegend: false,
            tooltip: {
                headerFormat: '',
                pointFormat: '<b>{point.properties.name_en}:</b> ' + gon.na
                // using name_en in case shape has no data and therefore no display_name
            },
            borderColor: '#909090',
            borderWidth: 1,
            states: {
                hover: {
                    color: '#D6E3B5',
                    borderColor: '#000',
                    borderWidth: 2
                }
            }
          },
          {
            // shape layer with data
            data : data,
            name: json.question.text,
            mapData: highmap_shapes[json.map.question_code],
            joinBy: ['name_en', 'shape_name'],
            allAreas: false, // if shape does not have value, do not show it so base layer above will show
            tooltip: {
                headerFormat: '',
                pointFormat: '<b>{point.display_name}:</b> {point.count:,.0f} ({point.value}%)'    
            },
            borderColor: '#909090',
            borderWidth: 1,
            states: {
              hover: {
                color: '#D6E3B5',
                borderColor: '#000',
                borderWidth: 2
              }
            },
            dataLabels: {
              enabled: true,
              color: 'white',
              formatter: function () {
                return Highcharts.numberFormat(this.point.count, 0) + '   (' + this.point.value + '%)';
              }
            }
        }],
        exporting: {
          sourceWidth: 1280,
          sourceHeight: 720,
          filename: title_text,
          chartOptions:{
            title: {
              text: title_text
            },
            subtitle: {
              text: json.map.subtitle.text
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
    highmap = $('#highmap').highcharts();

    // show map tabs
    $('#explore-tabs #nav-map').show();
  }else{
    // no map so hide tab
    $('#explore-tabs #nav-map').hide();
    // make sure these are not active
    $('#explore-tabs #nav-map, #explore-content #tab-map').removeClass('active');
  }
}


////////////////////////////////////////////////
// build crosstab chart
function build_crosstab_chart(json){
  if (json.chart && json.chart.data){
    // set languaage text
    Highcharts.setOptions({
      lang: {
        contextButtonTitle: gon.highcharts_context_title
      }
    });

    // if there are a lot of answers, scale the height accordingly
    if (json.question.answers.length + json.broken_down_by.answers.length < 10){
      $('#chart').height(500);
    }else{
      $('#chart').height(330 + json.question.answers.length*26.125 + json.broken_down_by.answers.length*21);
    }

    $('#chart').highcharts({
        chart: {
            type: 'bar'
        },
        title: {
            text: json.chart.title.html,
            useHTML: true,
            style: {'text-align': 'center', 'font-size': '16px', 'color': '#888'}
        },
        subtitle: {
            text: json.chart.subtitle.html,
            useHTML: true,
            style: {'text-align': 'center', 'margin-top': '-15px'}
        },
        xAxis: {
            categories: json.chart.labels,
            title: {
                text: json.question.text
            }
        },
        yAxis: {
            min: 0,
            title: {
                text: gon.percent
            }
        },
        legend: {
            title: {
                text: json.broken_down_by.text
            },
            layout: 'vertical',
            reversed: true,
            symbolHeight: 14,
            itemMarginBottom: 5,
            itemStyle: { "color": "#333333", "cursor": "pointer", "fontSize": "14px", "fontWeight": "bold" }
        },
        tooltip: {
            pointFormat: '<span style="color:{series.color}">{series.name}</span>: <b>{point.y:,.0f}</b> ({point.percentage:.2f}%)<br/>',
            //shared: true,
            backgroundColor: 'rgba(255, 255, 255, 0.95)',
            followPointer: true
        },
        plotOptions: {
            bar: {
                stacking: 'percent'
            }
        },
        series: json.chart.data.reverse(),
        exporting: {
          sourceWidth: 1280,
          sourceHeight: 720,
          filename: json.chart.title.text,
          chartOptions:{
            title: {
              text: json.chart.title.text
            },
            subtitle: {
              text: json.chart.subtitle.text
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
// build pie chart
function build_pie_chart(json){
  if (json.chart && json.chart.data){
    // set languaage text
    Highcharts.setOptions({
      lang: {
        contextButtonTitle: gon.highcharts_context_title
      }
    });

    // if there are a lot of answers, scale the height accordingly
    if (json.question.answers.length < 5){
      $('#chart').height(500);
    }else{
      $('#chart').height(425 + json.question.answers.length*21);
    }

    $('#chart').highcharts({
        chart: {
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false
        },
        title: {
            text: json.chart.title.html,
            useHTML: true,
            style: {'text-align': 'center', 'font-size': '16px', 'color': '#888'}
        },
        subtitle: {
            text: json.chart.subtitle.html,
            useHTML: true,
            style: {'text-align': 'center', 'margin-top': '-15px'}
        },
        tooltip: {
            formatter: function () {
              return '<b>' + this.key + ':</b> ' + Highcharts.numberFormat(this.point.options.count,0) + ' (' + this.y + '%)';
            }
        },
        plotOptions: {
            pie: {
                cursor: 'pointer',
                dataLabels: {
                    enabled: false
                },
                showInLegend: true
            }
        },
        legend: {
            align: 'center',
            layout: 'vertical',
            symbolHeight: 14,
            itemMarginBottom: 5,
            itemStyle: { "color": "#333333", "cursor": "pointer", "fontSize": "14px", "fontWeight": "bold" }
        },
        series: [{
            type: 'pie',
            data: json.chart.data
        }],
        exporting: {
          sourceWidth: 1280,
          sourceHeight: 720,
          filename: json.chart.title.text,
          chartOptions:{
            title: {
              text: json.chart.title.text
            },
            subtitle: {
              text: json.chart.subtitle.text
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
  $('.container-table h3').html(json.results.title.html + json.results.subtitle.html);

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
  if (json.analysis_type == 'comparative'){
    // 3 headers of:
    //                broekn_down_by question
    //                broekn_down_by answers .....

    // question code question   count percent count percent .....
    table += "<tr class='th-center'>";
    table += "<th class='var1-col'></th>";
    table += "<th colspan='" + (2*(json.broken_down_by.answers.length+1)).toString() + "'>";
    table += json.broken_down_by.text;
    table += "</th>";
    table += "</tr>";
    table += "<tr class='th-center'>";
    table += "<th class='var1-col'></th>";
    for(i=0; i<json.broken_down_by.answers.length;i++){
      table += "<th colspan='2'>";
      table += json.broken_down_by.answers[i].text.toString();
      table += "</th>"
    }
    table += "</tr>";
    table += "<tr>";
    table += "<th class='var1-col'>";
    table += json.question.text;
    table += "</th>";
    for(i=0; i<json.broken_down_by.answers.length;i++){
      table += "<th>";
      table += $('.table-data:first').data('count');
      table += "</th>"
      table += "<th>";
      table += $('.table-data:first').data('percent');
      table += "</th>"
    }
    table += "</tr>";
  }else{
    // 1 header of: question code question, count, percent
    table += "<tr class='th-center'>";
    table += "<th class='var1-col'>";
    table += json.question.text;
    table += "</th><th>";
    table += $('.table-data:first').data('count');
    table += "</th><th>";
    table += $('.table-data:first').data('percent');
    table += "</th></tr>";
  }
  table += "</thead>";

  // build body
  table += "<tbody>";
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


  table += "</tbody>";

  $('.table-data').html(table);

  // compute how many columns need to have this sort
  var sort_array = [];
  for(var i=1; i<$('.table-data:first > thead tr:last-of-type th').length; i++){
    sort_array.push(i);
  }

  // initalize the datatable
  datatables = [];
  $('.table-data').each(function(){
    datatables.push($(this).dataTable({
      "dom": '<"top"fl>t<"bottom"p><"clear">',
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
    }))    
  });
}

////////////////////////////////////////////////
// build details (question and possible answers)
function build_details(json){
  // clear out content first
  $('#tab-details #details-question-code-question, #tab-details #details-question-code-answers, #tab-details #details-broken-down-by-question, #tab-details #details-broken-down-by-answers').html('');

  // add question question/answers
  if (json.question && json.question.answers){
    $('#tab-details #details-question-code-question').html(json.question.text);    
    for(var i=0;i<json.question.answers.length;i++){
      $('#tab-details #details-question-code-answers').append('<li>' + json.question.answers[i].text + '</li>');
    }
  }

  // add broken down by question/answers
  if (json.broken_down_by && json.broken_down_by.answers){
    $('#tab-details #details-broken-down-by-question').html(json.broken_down_by.text);    
    for(var i=0;i<json.broken_down_by.answers.length;i++){
      $('#tab-details #details-broken-down-by-answers').append('<li>' + json.broken_down_by.answers[i].text + '</li>');
    }
    $('#tab-details #details-broken-down-by').show();
  }else{
    // no column data so hide this section
    $('#tab-details #details-broken-down-by').hide();
  }
}

////////////////////////////////////////////////
// build the visualizations for the explore data page
function build_explore_data_page(json){

  if (json.analysis_type == 'comparative'){
    build_crosstab_chart(json);
  }else{
    build_pie_chart(json);
  }
  build_highmap(json);
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
      url_querystring.push(l + '=' + v);
    });

  } else{
    // question code
    if ($('select#question_code').val() != ''){
      ajax_data.question_code = $('select#question_code').val();
      url_querystring.push('question_code=' + ajax_data.question_code);
    }

    // broken down by
    if ($('select#broken_down_by_code').val() != ''){
      ajax_data.broken_down_by_code = $('select#broken_down_by_code').val();
      url_querystring.push('broken_down_by_code=' + ajax_data.broken_down_by_code);
    }

    // filtered by
    if ($('select#filtered_by_code').val() != ''){
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
    // update content
    build_explore_data_page(json);

    // update url
    var new_url = [location.protocol, '//', location.host, location.pathname, '?', url_querystring.join('&')].join('');

    // change the browser URL to the given link location
    if (!is_back_button && new_url != window.location.href){
      window.history.pushState({path:new_url}, '', new_url);
    }

    $('#explore-data-loader').fadeOut('slow');

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
  if (gon.explore_data){
    // turn on tooltip for dataset description
    $('#dataset-description').tooltip();

    // due to using tabs, the map, chart and table cannot be properly drawn
    // because they may be hidden. 
    // this event catches when a tab is being shown to make sure 
    // the item is properly drawn
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
      switch($(this).attr('href')){
        case '#tab-map':
          highmap.reflow();
          break;
        case '#tab-chart':
          $('#chart').highcharts().reflow();        
          break;
      }
    });

    // catch the form submit and call the url with the
    // form values in the url
    $("form#form-explore-data").submit(function(){
      $('#explore-data-loader').fadeIn('slow', function(){
        get_explore_data();
      });
      return false;
    });

    // reset the form fields
    $("form#form-explore-data input#btn-reset").click(function(e){
      e.preventDefault();
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
      $('select#filtered_by_code option[value="' + q + '"]').attr('disabled','disabled');
      $('select#filtered_by_code option[value="' + bdb + '"]').attr('disabled','disabled');

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

