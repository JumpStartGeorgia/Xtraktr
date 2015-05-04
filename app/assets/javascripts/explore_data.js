var geojson, datatables, i, j, json_data;

////////////////////////////////////////////////
// build highmap
function build_highmap(shape_question_code, json_map_set){
console.log(json_map_set);  
  // create a div tag for this map
  var map_id = 'map-' + ($('#container-map .map').length+1);
  $('#container-map').append('<div id="' + map_id + '" class="map"></div>');

  $('#container-map #' + map_id).highcharts('Map', {
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
          text: json_map_set.title.html,
          useHTML: true,
          style: {'text-align': 'center', 'font-size': '16px', 'color': '#888'}
      },
      subtitle: {
          text: json_map_set.subtitle.html,
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
          data : Highcharts.geojson(highmap_shapes[shape_question_code], 'map'),
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
          data : json_map_set.data,
          name: 'dataLayer',
          mapData: highmap_shapes[shape_question_code],
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
        filename: json_map_set.title.text,
        chartOptions:{
          title: {
            text: json_map_set.title.text
          },
          subtitle: {
            text: json_map_set.subtitle.text
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


// build highmap
function build_highmaps(json){
  if (json.map){
    // adjust the width of the map to fit its container
    $('#container-map').width($('#explore-tabs').width());

    // remove all existing maps
    $('#container-map').empty();
    // remove all existing map links
    $('#jumpto-maps #jumpto-maps').hide();
    $('#jumpto-maps #jumpto-maps-items .jumpto-items').empty();

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

      for(var h=0; h<json.map.length; h++){
        if (json.broken_down_by && json.map[h].filter_results.map_sets.constructor === Array){
          // add jumpto link
          jumpto_text += '<li data-href="#map-' + (map_index+1) + '">' + json.filtered_by.text + ' = ' + json.map[h].filter_answer_text;
          jumpto_text += '<ul>';          

          for(var i=0; i<json.map[h].filter_results.map_sets.length; i++){
            build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.map_sets[i]);

            // add jumpto link
            jumpto_text += '<li class="scroll-link" data-href="#map-' + (map_index+1) + '">' + non_map_text + ' = ' + json.map[h].filter_results.map_sets[i].broken_down_answer_text + '</li>';

            // increase the map index
            map_index += 1;        
          }

          jumpto_text += '</ul></li>';          

        }else{
          build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.map_sets);

          // add jumpto link
          jumpto_text += '<li class="scroll-link" data-href="#map-' + (map_index+1) + '">' + json.filtered_by.text + ' = ' + json.map[h].filter_answer_text + '</li>';

          // increase the map index
          map_index += 1;        
        }
      }

      // show jumpto
      $('#jumpto-maps .jumpto-items').append(jumpto_text);
      $('#jumpto-maps #jumpto-maps').show();
      $('#jumpto').show();

    }else{

      // no filters
      if (json.broken_down_by && json.map.map_sets.constructor === Array){

        for(var i=0; i<json.map.map_sets.length; i++){
          build_highmap(json.map.shape_question_code, json.map.map_sets[i]);

          // add jumpto link
          jumpto_text += '<li class="scroll-link" data-href="#map-' + (i+1) + '">' + non_map_text + ' = ' + json.map.map_sets[i].broken_down_answer_text + '</li>';
        }

        // show jumpto
        $('#jumpto-maps .jumpto-items').append(jumpto_text);
        $('#jumpto-maps #jumpto-maps').show();
        $('#jumpto').show();

      }else{
        build_highmap(json.map.shape_question_code, json.map.map_sets);
  
        // hide jumpto
        $('#jumpto').hide();
      }
    }

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
function build_crosstab_chart(question_text, broken_down_by_text, json_chart, chart_height){
  if (chart_height == undefined){
    chart_height = 501; // need the 1 for the border bottom line
  }

  // create a div tag for this chart
  var chart_id = 'chart-' + ($('#container-chart .chart').length+1);
  $('#container-chart').append('<div id="' + chart_id + '" class="chart" style="height: ' + chart_height + 'px;"></div>');

  // create chart
  $('#container-chart #' + chart_id).highcharts({
    chart: {
        type: 'bar'
    },
    title: {
        text: json_chart.title.html,
        useHTML: true,
        style: {'text-align': 'center', 'font-size': '16px', 'color': '#888'}
    },
    subtitle: {
        text: json_chart.subtitle.html,
        useHTML: true,
        style: {'text-align': 'center', 'margin-top': '-15px'}
    },
    xAxis: {
        categories: json_chart.labels,
        title: {
            text: question_text
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
            text: broken_down_by_text
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
    series: json_chart.data.reverse(),
    exporting: {
      sourceWidth: 1280,
      sourceHeight: 720,
      filename: json_chart.title.text,
      chartOptions:{
        title: {
          text: json_chart.title.text
        },
        subtitle: {
          text: json_chart.subtitle.text
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

////////////////////////////////////////////////
// build crosstab charts for each chart item in json
function build_crosstab_charts(json){
  if (json.chart){
    // determine chart height
    // if there are a lot of answers, scale the height accordingly
    var chart_height = 501; // need the 1 for the border bottom line
    if (json.question.answers.length + json.broken_down_by.answers.length >= 10){
      chart_height = 330 + json.question.answers.length*26.125 + json.broken_down_by.answers.length*21 + 1;
    }

    // remove all existing charts
    $('#container-chart').empty();
    // remove all existing chart links
    $('#jumpto-charts #jumpto-charts').hide();
    $('#jumpto-charts #jumpto-charts-items .jumpto-items').empty();
    var jumpto_text = '';

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart
        build_crosstab_chart(json.question.text, json.broken_down_by.text, json.chart[i].filter_results, chart_height);

        // add jumpto link
        jumpto_text += '<li class="scroll-link" data-href="#chart-' + (i+1) + '">' + json.filtered_by.text + ' = ' + json.chart[i].filter_answer_text + '</li>';
      }

      // show jumpto links
      $('#jumpto-charts .jumpto-items').append(jumpto_text);
      $('#jumpto-charts #jumpto-charts').show();
      $('#jumpto').show();

    }else{
      // no filters
      build_crosstab_chart(json.question.text, json.broken_down_by.text, json.chart, chart_height);

      // hide jumpto
      $('#jumpto').hide();
    }
  }
} 



////////////////////////////////////////////////
// build pie chart
function build_pie_chart(json_chart, chart_height){
  if (chart_height == undefined){
    chart_height = 501; // need the 1 for the border bottom line
  }

  // create a div tag for this chart
  var chart_id = 'chart-' + ($('#container-chart .chart').length+1);
  $('#container-chart').append('<div id="' + chart_id + '" class="chart" style="height: ' + chart_height + 'px;"></div>');

  // create chart
  $('#container-chart #' + chart_id).highcharts({
    chart: {
        plotBackgroundColor: null,
        plotBorderWidth: null,
        plotShadow: false
    },
    title: {
        text: json_chart.title.html,
        useHTML: true,
        style: {'text-align': 'center', 'font-size': '16px', 'color': '#888'}
    },
    subtitle: {
        text: json_chart.subtitle.html,
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
        data: json_chart.data
    }],
    exporting: {
      sourceWidth: 1280,
      sourceHeight: 720,
      filename: json_chart.title.text,
      chartOptions:{
        title: {
          text: json_chart.title.text
        },
        subtitle: {
          text: json_chart.subtitle.text
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

////////////////////////////////////////////////
// build pie chart for each chart item in json
function build_pie_charts(json){
  if (json.chart){
    // determine chart height
    // if there are a lot of answers, scale the height accordingly
    var chart_height = 501; // need the 1 for the border bottom line
    if (json.question.answers.length >= 5){
      chart_height = 425 + json.question.answers.length*21 + 1;
    }

    // remove all existing charts
    $('#container-chart').empty();
    // remove all existing chart links
    $('#jumpto-charts #jumpto-charts').hide();
    $('#jumpto-charts #jumpto-charts-items .jumpto-items').empty();
    var jumpto_text = '';

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart
        build_pie_chart(json.chart[i].filter_results, chart_height);

        // add jumpto link
        jumpto_text += '<li class="scroll-link" data-href="#chart-' + (i+1) + '">' + json.filtered_by.text + ' = ' + json.chart[i].filter_answer_text + '</li>';
      }

      // show jumpto links
      $('#jumpto-charts .jumpto-items').append(jumpto_text);
      $('#jumpto-charts #jumpto-charts').show();
      $('#jumpto').show();

    }else{
      // no filters
      build_pie_chart(json.chart, chart_height);
  
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
      table += "<th class='var1-col'>";
      table += json.question.text;
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
      table += "<th class='var1-col' colspan='2'></th>";
      table += "<th colspan='" + (2*(json.broken_down_by.answers.length+1)).toString() + "'>";
      table += json.broken_down_by.text;
      table += "</th>";
      table += "</tr>";
      table += "<tr class='th-center'>";
      table += "<th class='var1-col' colspan='2'></th>";
      for(i=0; i<json.broken_down_by.answers.length;i++){
        table += "<th colspan='2'>";
        table += json.broken_down_by.answers[i].text.toString();
        table += "</th>"
      }
      table += "</tr>";
      table += "<tr>";
      table += "<th class='var1-col'>";
      table += json.filtered_by.text;
      table += "</th>";
      table += "<th class='var1-col'>";
      table += json.question.text;
      table += "</th>";
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
      table += json.filtered_by.text;
      table += "</th>";
      table += "<th class='var1-col'>";
      table += json.question.text;
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
  // clear out existing content and hide
  $('#tab-details .details-item .name-variable, #tab-details .details-item .notes, #tab-details .details-item .list-answers').empty();
  $('#tab-details .details-item').hide();

  // add questions
  if (json.question && json.question.text && json.question.answers){
    $('#tab-details #details-question-code .name-variable').html(json.question.text);    
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

  // add broken down by
  if (json.broken_down_by && json.broken_down_by.text && json.broken_down_by.answers){
    $('#tab-details #details-broken-down-by-code .name-variable').html(json.broken_down_by.text);    
    if (json.broken_down_by.notes){
      $('#tab-details #details-broken-down-by-code .notes').html(json.broken_down_by.notes);    
      $('#tab-details #details-broken-down-by-code .details-notes').show();
    }else{
      $('#tab-details #details-broken-down-by-code .details-notes').hide();
    }
    for(var i=0;i<json.broken_down_by.answers.length;i++){
      $('#tab-details #details-broken-down-by-code .list-answers').append('<li>' + json.broken_down_by.answers[i].text + '</li>');
    }
    $('#tab-details #details-broken-down-by-code').show();
  }

  // add filters
  if (json.filtered_by && json.filtered_by.text && json.filtered_by.answers){
    $('#tab-details #details-filtered-by-code .name-variable').html(json.filtered_by.text);    
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
// update the page title to include the title of the analysis
function build_page_title(json){
  // get current page title
  // first index - dataset title
  // last index - app name
  var title_parts = $('title').html().split(' | ');

  if (json.results.title.text){
    $('title').html(title_parts[0] + ' | ' + json.results.title.text + ' | ' + title_parts[title_parts.length-1])
  }else{
    $('title').html(title_parts[0] + ' | ' + title_parts[title_parts.length-1])
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
    $('#jumpto-loader').fadeOut('slow');

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
    lang: {
      contextButtonTitle: gon.highcharts_context_title
    }
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

    // jumpto scrolling
    $("#jumpto").on('click', 'ul li.scroll-link', function(){
      var href = $(this).data('href');
      $('html, body').animate({
        scrollTop: $(href).offset().top - 120
      }, 1500);
    });

    // when chart tab clicked on, make sure the jumpto block is showing, else, hide it
    $('#explore-tabs li a').click(function(){
      if ($(this).attr('href') == '#tab-chart' && $('#jumpto #jumpto-charts .jumpto-items li').length > 0){
        $('#jumpto').show();
        $('#jumpto #jumpto-charts').show();
        $('#jumpto #jumpto-maps').hide();
      }else if ($(this).attr('href') == '#tab-map' && $('#jumpto #jumpto-maps .jumpto-items li').length > 0){
        $('#jumpto').show();
        $('#jumpto #jumpto-maps').show();
        $('#jumpto #jumpto-charts').hide();
      }else{
        $('#jumpto').hide();
        $('#jumpto #jumpto-charts').hide();
        $('#jumpto #jumpto-maps').hide();
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

