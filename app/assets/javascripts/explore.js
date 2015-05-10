////////////////////////////////////////////////
////////////////////////////////////////////////
// collection of functions to build charts/maps
// for datasets and time series
////////////////////////////////////////////////
////////////////////////////////////////////////


////////////////////////////////////////////////
// determine heights of chart based on number of answers
////////////////////////////////////////////////
function pie_chart_height(json){
  var chart_height = 501; // need the 1 for the border bottom line
  if (json.question.answers.length >= 5){
    chart_height = 425 + json.question.answers.length*21 + 1;
  }
  return chart_height;
}

function crosstab_chart_height(json){
  var chart_height = 501; // need the 1 for the border bottom line
  if (json.question.answers.length + json.broken_down_by.answers.length >= 10){
    chart_height = 330 + json.question.answers.length*26.125 + json.broken_down_by.answers.length*21 + 1;
  }
  return chart_height;
}

function time_series_chart_height(json){
  var chart_height = 501; // need the 1 for the border bottom line
  if (json.question.answers.length >= 5){
    chart_height = 425 + json.question.answers.length*21 + 1;
  }
  return chart_height;
}




////////////////////////////////////////////////
// build highmap
////////////////////////////////////////////////
function build_highmap(shape_question_code, json_map_set){
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





////////////////////////////////////////////////
// build crosstab chart
////////////////////////////////////////////////
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
// build pie chart
////////////////////////////////////////////////
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
// build time series line chart
////////////////////////////////////////////////
function build_time_series_chart(json_chart, chart_height){
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
    xAxis: {
        categories: json_chart.datasets
    },
    yAxis: {
        title: {
            text: gon.percent
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
        layout: 'vertical',
        symbolHeight: 14,
        itemMarginBottom: 5,
        itemStyle: { "color": "#333333", "cursor": "pointer", "fontSize": "14px", "fontWeight": "bold" }
    },
    series: json_chart.data,
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
// update the page title to include the title of the analysis
function build_page_title(json){
  // get current page title
  // first index - dataset/time series title
  // last index - app name
  var title_parts = $('title').html().split(' | ');

  if (json.results.title.text){
    $('title').html(title_parts[0] + ' | ' + json.results.title.text + ' | ' + title_parts[title_parts.length-1])
  }else{
    $('title').html(title_parts[0] + ' | ' + title_parts[title_parts.length-1])
  }
   
}



