var geojson, datatable, i, j, json_data, highmap;


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
    if (json.type == 'crosstab'){
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
        title_html = json.title.map_html.replace('[replace]', filter_name);
        title_text = json.title.map_text.replace('[replace]', filter_name);
      }else{
        data = json.map.data[filter];
        filter_name = $('#highmap-filter-container ul li a[data-id="' + filter + '"]').html();       
        title_html = json.title.map_html.replace('[replace]', filter_name);
        title_text = json.title.map_text.replace('[replace]', filter_name);
      }

    }else{
      // turn off filter
      $('#highmap-filter-container').hide();

      data = json.map.data;
      title_html = json.title.map_html;
      title_text = json.title.map_text;

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
            text: json.subtitle.html,
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
            name: json.row_question,
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
    if (json.row_answers.length + json.column_answers.length < 10){
      $('#chart').height(500);
    }else{
      $('#chart').height(330 + json.row_answers.length*26.125 + json.column_answers.length*21);
    }

    $('#chart').highcharts({
        chart: {
            type: 'bar'
        },
        title: {
            text: json.title.html,
            useHTML: true,
            style: {'text-align': 'center', 'font-size': '16px', 'color': '#888'}
        },
        subtitle: {
            text: json.subtitle.html,
            useHTML: true,
            style: {'text-align': 'center', 'margin-top': '-15px'}
        },
        xAxis: {
            categories: json.chart.labels,
            title: {
                text: json.row_question
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
                text: json.column_question
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
    if (json.row_answers.length < 5){
      $('#chart').height(500);
    }else{
      $('#chart').height(425 + json.row_answers.length*21);
    }

    $('#chart').highcharts({
        chart: {
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false
        },
        title: {
            text: json.title.html,
            useHTML: true,
            style: {'text-align': 'center', 'font-size': '16px', 'color': '#888'}
        },
        subtitle: {
            text: json.subtitle.html,
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
  if (json.type == 'crosstab'){
    // 3 headers of:
    //                col question
    //                col answers .....

    // row question   count percent count percent .....
    table += "<tr class='th-center'>";
    table += "<th class='var1-col'></th>";
    table += "<th colspan='" + (2*(json.column_answers.length+1)).toString() + "'>";
    table += json.column_question;
    table += "</th>";
    table += "</tr>";
    table += "<tr class='th-center'>";
    table += "<th class='var1-col'></th>";
    for(i=0; i<json.column_answers.length;i++){
      table += "<th colspan='2'>";
      table += json.column_answers[i].text.toString();
      table += "</th>"
    }
    table += "</tr>";
    table += "<tr>";
    table += "<th class='var1-col'>";
    table += json.row_question;
    table += "</th>";
    for(i=0; i<json.column_answers.length;i++){
      table += "<th>";
      table += $('#datatable').data('count');
      table += "</th>"
      table += "<th>";
      table += $('#datatable').data('percent');
      table += "</th>"
    }
    table += "</tr>";
  }else{
    // 1 header of: row question, count, percent
    table += "<tr class='th-center'>";
    table += "<th class='var1-col'>";
    table += json.row_question;
    table += "</th><th>";
    table += $('#datatable').data('count');
    table += "</th><th>";
    table += $('#datatable').data('percent');
    table += "</th></tr>";
  }
  table += "</thead>";

  // build body
  table += "<tbody>";
  if (json.type == 'crosstab'){
    // cells per row: row answer, count/percent for each col
    for(i=0; i<json.row_answers.length; i++){
      table += "<tr>";
      table += "<td class='var1-col' data-order='" + json.row_answers[i].sort_order + "'>";
      table += json.row_answers[i].text;
      table += "</td>";
      for(j=0; j<json.counts[i].length; j++){
        table += "<td data-order='" + json.counts[i][j] + "'>";
        table += Highcharts.numberFormat(json.counts[i][j],0);
        table += "</td>";
        table += "<td>";
        table += json.percents[i][j].toFixed(2);
        table += "%</td>";
      }
      table += "</tr>";
    }
  }else{
    // cells per row: row answer, count, percent
    for(i=0; i<json.row_answers.length; i++){
      table += "<tr>";
      table += "<td class='var1-col' data-order='" + json.row_answers[i].sort_order + "'>";
      table += json.row_answers[i].text;
      table += "</td><td data-order='" + json.counts[i] + "'>";
      table += Highcharts.numberFormat(json.counts[i],0);
      table += "</td><td>";
      table += json.percents[i].toFixed(2);
      table += "%</td>";
      table += "</tr>";
    }
  }


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
  $('#tab-details #details-row-question, #tab-details #details-row-answers, #tab-details #details-col-question, #tab-details #details-col-answers').html('');

  // add row question/answers
  if (json.row_question && json.row_answers){
    $('#tab-details #details-row-question').html(json.row_question);    
    for(var i=0;i<json.row_answers.length;i++){
      $('#tab-details #details-row-answers').append('<li>' + json.row_answers[i].text + '</li>');
    }
  }

  // add col question/answers
  if (json.column_question && json.column_answers){
    $('#tab-details #details-col-question').html(json.column_question);    
    for(var i=0;i<json.column_answers.length;i++){
      $('#tab-details #details-col-answers').append('<li>' + json.column_answers[i].text + '</li>');
    }
    $('#tab-details #details-col').show();
  }else{
    // no column data so hide this section
    $('#tab-details #details-col').hide();
  }
}

////////////////////////////////////////////////
// build the visualizations for the explore data page
function build_explore_data_page(json){

  if (json.type == 'crosstab'){
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
  // get params
  // do not get any hidden fields (utf8 and authenticity token)
  var querystring;
  if (is_back_button){
    var split = window.location.href.split('?');
    if (split.length == 2){
      querystring = split[1];
    }
  } else{
    querystring = $("form#form-explore-data select, form#form-explore-data input:not([type=hidden])").serialize();

    // add language param from url query string, if it exists
    params = queryStringToJSON(window.location.href);
    if (params.language != undefined){
      querystring += "&language=" + params.language;
    }
  }

  // call ajax
  $.ajax({
    type: "GET",
    url: gon.explore_data_ajax_path,
    data: querystring,
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
    var new_url = [location.protocol, '//', location.host, location.pathname, '?', querystring].join('');

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

  //    $('select#row').val('');
  $('select#col').val('');
  $('select#filter_variable').val('');
  $('select#filter_value').val('');
  $('input#exclude_dkra').removeAttr('checked');

  // reload the lists
  //    $('select#row').selectpicker('refresh');
  $('select#col').selectpicker('refresh');
  $('#btn-swap-vars').hide();
  $('select#filter_variable').selectpicker('refresh');
  $('select#filter_value').selectpicker('refresh');
  $('#filter_value_container').hide();

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
      // if this is row, update col
      // else, vice-versa
      if ($(this).attr('id') == 'row'){
        // update col list
        // remove all disabled
        $('select.selectpicker#col option[disabled="disabled"]').removeAttr('disabled');  
        // disable the new selection
        $('select.selectpicker#col option[value="' + val + '"]').attr('disabled', 'disabled');
        // update the select list
        $('select.selectpicker#col').selectpicker('refresh');
      }else if ($(this).attr('id') == 'col'){
        // update row list
        // remove all disabled
        $('select.selectpicker#row option[disabled="disabled"]').removeAttr('disabled');  
        // disable the new selection
        $('select.selectpicker#row option[value="' + val + '"]').attr('disabled', 'disabled');
        // update the select list
        $('select.selectpicker#row').selectpicker('refresh');

        // if val != '' then turn on swap button
        if (val == ''){
          $('button#btn-swap-vars').fadeOut();
        }else{
          $('button#btn-swap-vars').fadeIn();
        }
      }

      // update filter list
      var row = $('select.selectpicker#row').val();
      var col = $('select.selectpicker#col').val();
      // if filter is one of these values, reset filter to no filter
      if (($('select#filter_variable').val() == row && row != '') || ($('select#filter_variable').val() == col && col != '')){
        // reset value and hide filter answers
        $('select#filter_variable').selectpicker('val', '');
        $('#filter_value_container').fadeOut();
        $('select#filter_value option:not([disabled])').attr('disabled','disabled');
        $('select#filter_value').selectpicker('refresh');
        $('select#filter_value').selectpicker('render');
      }   
      // mark selected items as disabled
      $('select#filter_variable option[disabled="disabled"]').removeAttr('disabled');  
      $('select#filter_variable option[value="' + row + '"]').attr('disabled','disabled');
      $('select#filter_variable option[value="' + col + '"]').attr('disabled','disabled');

      $('select#filter_variable').selectpicker('refresh');
      $('select#filter_variable').selectpicker('render');
    });  

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

    // swap vars button
    // - when clicked, swap the values and then submit the form
    $('button#btn-swap-vars').click(function(){
      // get the vals
      var var1 = $('select#row').val();
      var var2 = $('select#col').val();

      // turn off disabled options
      // so can select in next step
      $('select#row option[value="' + var2 + '"]').removeAttr('disabled');
      $('select#col option[value="' + var1 + '"]').removeAttr('disabled');

      // refresh so disabled options are removed
      $('select#row').selectpicker('refresh');
      $('select#col').selectpicker('refresh');

      // swap the vals
      $('select#row').selectpicker('val', var2);
      $('select#col').selectpicker('val', var1);

      $('select#row').selectpicker('render');
      $('select#col').selectpicker('render');

      // disable the swapped values
      $('select#row option[value="' + var1 + '"]').attr('disabled', 'disabled');
      $('select#col option[value="' + var2 + '"]').attr('disabled', 'disabled');

      // refresh so disabled options are updated
      $('select#row').selectpicker('refresh');
      $('select#col').selectpicker('refresh');

      // submit the form
      $('input#btn-submit').trigger('click');
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
    $('#explore-data-loader').fadeIn('slow', function(){
      get_explore_data();
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

      // col
      if (params.col != $('select#col').val()){
        if (params.col == undefined){
          $('select#col').val('');
        }else{
          $('select#col').val(params.col);
        }
        $('select#col').selectpicker('refresh');
      }
      if ($('select#col').val() == ''){
        $('#btn-swap-vars').hide();
      }else{
        $('#btn-swap-vars').show();
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
      $('#explore-data-loader').fadeIn('slow', function(){
        get_explore_data(true);
      });
    });  
  }
});

