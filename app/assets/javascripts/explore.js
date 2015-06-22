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
// add disclaimer link
////////////////////////////////////////////////
function add_disclaimer_link(visual_element){
  if (gon.disclaimer_link && gon.disclaimer_text){
    var parent = $(visual_element).parent();

    // create link
    var link = '<a class="chart-disclaimer" href="' + gon.disclaimer_link + '" target="_blank">' + gon.disclaimer_text + '</a>';

    // add link to visual
    $(visual_element).append(link);
  }
}



////////////////////////////////////////////////
// determine which highlight button to add to chart
////////////////////////////////////////////////
function determine_highlight_button(visual_element, embed_id, visual_type){
  if (gon.embed_ids){
    if (gon.embed_ids.indexOf(embed_id) > -1){
      // already exists, delete btn
      delete_highlight_button(visual_element, embed_id, visual_type);
    }else{
      // not exist, add btn
      add_highlight_button(visual_element, embed_id, visual_type);
    }
  }
}

////////////////////////////////////////////////
// add add highlight button to chart
////////////////////////////////////////////////
function add_highlight_button(visual_element, embed_id, visual_type){
  if (gon.is_admin){
    var parent = $(visual_element).parent();

    // create add link
    var link = '<a class="add-highlight btn btn-primary btn-xs" href="' + $(parent).data('add-highlight') + '" data-embed-id="' + embed_id + '" data-visual-type="' + visual_type + '" ';
    link += 'title="' + gon.add_highlight_text + '" data-placement="right"><span class="glyphicon glyphicon-star" aria-hidden="true"></span></a>';

    // add link to visual
    $(visual_element).append(link);
  }
}

////////////////////////////////////////////////
// add delete highlight button to chart
////////////////////////////////////////////////
function delete_highlight_button(visual_element, embed_id, visual_type){
  if (gon.is_admin){
    var parent = $(visual_element).parent();

    // create delete link
    var link = '<a class="delete-highlight btn btn-danger btn-xs" href="' + $(parent).data('delete-highlight') + '" data-embed-id="' + embed_id + '" data-visual-type="' + visual_type + '" ';
    link += 'title="' + gon.delete_highlight_text + '" data-placement="right"><span class="glyphicon glyphicon-star" aria-hidden="true"></span></a>';

    // create desc link
    link += '<a class="description-highlight btn btn-primary btn-xs" data-href="' + $(parent).data('description') + '" data-embed-id="' + embed_id + '" ';
    link += 'title="' + gon.description_highlight_text + '" data-placement="right"><span class="glyphicon glyphicon-pencil" aria-hidden="true"></span></a>';


    // add link to visual
    $(visual_element).append(link);
    
  }
}



////////////////////////////////////////////////
// add embed button to chart
////////////////////////////////////////////////
function add_embed_button(visual_element, embed_id){
  if (gon.embed_button_link){
    var parent = $(visual_element).parent();

    // create link
    var link = '<div class="embed-chart" data-href="' + gon.embed_button_link.replace('replace', embed_id) + '"';
    link += 'title="' + gon.embed_chart_text + '" data-placement="bottom"><img src="/assets/svg/embed.svg" alt="' + gon.embed_chart_text + '" /></div>';

    // add link to visual
    $(visual_element).append(link);
  }
}


////////////////////////////////////////////////
// add highlight description button to chart
////////////////////////////////////////////////
function add_highlight_description_button(visual_element, embed_id){
  if (gon.get_highlight_desc_link && embed_id){
    // get the description for this embed_id
    $.ajax({
      type: "POST",
      url: gon.get_highlight_desc_link,
      data: {embed_id: embed_id},
      dataType: 'json'
    }).done(function(data){
      if (data && data.description != null && data.description != ''){
        // add the link
        var parent = $(visual_element).parent();

        // create link
        // - if the embed link does not exist, make sure it is in the correct place
        var cls = '';
        if (gon.embed_button_link){
          cls = ' with-embed-chart';
        }
        var link = '<div class="highlight-description-chart ' + cls + '" data-text="' + data.description + '"';
        link += 'title="' + gon.highlight_description_chart_text + '" data-placement="bottom"><img src="/assets/svg/desc_icon.svg" alt="' + data.description + '" /></div>';

        // add link to visual
        $(visual_element).append(link);
      }
    });

  }
}



////////////////////////////////////////////////
// build title/sub title for chart/map
// if gon.visual_link is present, turn the title into a link
////////////////////////////////////////////////
function build_visual_title(highlight_path, text){
  var t = '';
  if ($(highlight_path).data('explore-link') != undefined){
    t = '<a class="visual-title-link" target="_parent" href="' + $(highlight_path).data('explore-link') + '">' + text + '</a>';
  }else{
    t = text;
  }
  return t;
}

////////////////////////////////////////////////
// build highmap
////////////////////////////////////////////////
function build_highmap(shape_question_code, adjustable_max, json_map_set){
  // create a div tag for this map
  // if gon.highlight_id exist, add it to the jquery selector path
  var selector_path = '#container-map';
  var highlight_path = '.highlight-data[data-id="' + gon.highlight_id + '"] ';
  if (gon.highlight_id){
    selector_path = highlight_path + selector_path;
  }
  var map_id = 'map-' + ($('#container-map .map').length+1);
  $(selector_path).append('<div id="' + map_id + '" class="map"></div>');

  var max = 100;
  if (adjustable_max == true){
    //  for use in the color axis
    // get the max percent value and round temp_max to the nearest 10s
    max = Math.ceil(Math.max.apply(Math, $.map(json_data.map.map_sets.data, function(obj, i){return obj.value})) / 10)*10;    
  }

  $(selector_path + ' #' + map_id).highcharts('Map', {
      credits: { enabled: false },
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
                          return this.point.display_name + '<br/>' + Highcharts.numberFormat(this.point.count, 0) + '   (' + this.point.value + '%)';
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
          text: build_visual_title(highlight_path, json_map_set.title.html),
          useHTML: true,
          style: {'text-align': 'center', 'font-family':"'sourcesans_pro_l', 'sans-serif'", 'font-size': '18px', 'color': '#3c4352'}
      },
      subtitle: {
          text: json_map_set.subtitle.html,
          useHTML: true,
          style: {'text-align': 'center'}
      },

      mapNavigation: {
          enabled: true,
          enableMouseWheelZoom: false,
          buttonOptions: {
              verticalAlign: 'top',
              theme: {
                  states: {
                      hover: {
                          stroke: '#999999',
                          fill: '#eeeeee'
                      },
                      select: {
                          stroke: '#999999',
                          fill: '#eeeeee'
                      }
                  }              
              },
          }
      },
      colorAxis: {
        min: 0,
        max: max, 
        minColor: '#d2f1f9',
        maxColor: '#0086a5',
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
          borderColor: '#f6f6f6',
          borderWidth: 2,
          states: {
              hover: {
                  color: '#0086a5',
                  borderColor: '#3c4352',
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
          borderColor: '#f6f6f6',
          borderWidth: 2,
          states: {
            hover: {
              color: '#0086a5',
              borderColor: '#3c4352',
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
        filename: json_map_set.title.text.replace(/[\|&;\$%@"\'<>\(\)\+,]/g, ""),
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
            symbol: 'url(/assets/svg/download.svg)',
            theme: {
                'stroke-width': 1,
                stroke: 'white',
                r: 0,
                states: {
                    hover: {
                        stroke: 'white',
                        fill: 'white'
                    },
                    select: {
                        stroke: 'white',
                        fill: 'white'
                    }
                }              
            },
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

  // now add button to add as highlight
  determine_highlight_button($(selector_path + ' #' + map_id), json_map_set.embed_id, gon.visual_types.map);  

  // add embed chart button
  add_embed_button($(selector_path + ' #' + map_id), json_map_set.embed_id);

  // add highlight description button
  add_highlight_description_button($(selector_path + ' #' + map_id), json_map_set.embed_id);

  // add disclaimer link
  add_disclaimer_link($(selector_path + ' #' + map_id));
}





////////////////////////////////////////////////
// build crosstab chart
////////////////////////////////////////////////
function build_crosstab_chart(question_text, broken_down_by_code, broken_down_by_text, json_chart, chart_height){
  if (chart_height == undefined){
    chart_height = 501; // need the 1 for the border bottom line
  }

  // create a div tag for this chart
  // if gon.highlight_id exist, add it to the jquery selector path
  var selector_path = '#container-chart';
  var highlight_path = '.highlight-data[data-id="' + gon.highlight_id + '"] ';
  if (gon.highlight_id){
    selector_path = highlight_path + selector_path;
  }
  var chart_id = 'chart-' + ($('#container-chart .chart').length+1);
  $(selector_path).append('<div id="' + chart_id + '" class="chart" style="height: ' + chart_height + 'px;"></div>');

  // create chart
  $(selector_path + ' #' + chart_id).highcharts({
    credits: { enabled: false },
    chart: {
        type: 'bar'
    },
    title: {
        text: build_visual_title(highlight_path, json_chart.title.html),
        useHTML: true,
        style: {'text-align': 'center', 'font-family':"'sourcesans_pro_l', 'sans-serif'", 'font-size': '18px', 'color': '#3c4352'}
    },
    subtitle: {
        text: json_chart.subtitle.html,
        useHTML: true,
        style: {'text-align': 'center'}
    },
    xAxis: {
        categories: json_chart.labels,
        title: {
            text: '<span class="code-highlight">' + question_text + '</span>',
            useHTML: true,
            style: { "fontSize": "14px", "fontWeight": "bold" }
        },
        labels:
        {
          style: { "color": "#3c4352", "fontSize": "14px", "fontFamily":"'sourcesans_pro', 'sans-serif'", "fontWeight": "normal", 'textAlign': 'right' },
          useHTML: true,
          step: 1
        }
    },
    yAxis: {
        min: 0,
        title: {
            text: gon.percent,
            style: { "fontSize": "14px", "fontWeight": "bold" }
        },
        labels:
        {
          style: { "color": "#777c86", "fontSize": "14px", "fontFamily":"'sourcesans_pro', 'sans-serif'", "fontWeight": "normal" },
          useHTML: true
        }       
    },
    legend: {
        title: {
          text: broken_down_by_code,
          style: { "color": "#00adee", "fontSize": "18px", "fontFamily":"'sourcesans_pro_sb', 'sans-serif'", "fontWeight": "normal" }
        },
        useHTML: true,
        layout: 'vertical',
        reversed: true,
        symbolWidth: 14,
        symbolHeight: 14,
        itemMarginBottom: 5,
        itemStyle: { "cursor": "pointer", 'font-family':"'sourcesans_pro_l', 'sans-serif'", 'font-size': '12px', 'color': '#3C4352', 'fontWeight': 'normal' },
        symbolRadius: 100
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
      sourceHeight: chart_height,
      filename: json_chart.title.text.replace(/[\|&;\$%@"\'<>\(\)\+,]/g, ""),
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
          symbol: 'url(/assets/svg/download.svg)',
          theme: {
              'stroke-width': 1,
              stroke: 'white',
              r: 0,
              states: {
                  hover: {
                      stroke: 'white',
                      fill: 'white'
                  },
                  select: {
                      stroke: 'white',
                      fill: 'white'
                  }
              }              
          },
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

  // now add button to add as highlight
  determine_highlight_button($(selector_path + ' #' + chart_id), json_chart.embed_id, gon.visual_types.crosstab_chart);  

  // add embed chart button
  add_embed_button($(selector_path + ' #' + chart_id), json_chart.embed_id);

  // add highlight description button
  add_highlight_description_button($(selector_path + ' #' + chart_id), json_chart.embed_id);

  // add disclaimer link
  add_disclaimer_link($(selector_path + ' #' + chart_id));
}





////////////////////////////////////////////////
// build pie chart
////////////////////////////////////////////////
function build_pie_chart(json_chart, chart_height){
  if (chart_height == undefined){
    chart_height = 501; // need the 1 for the border bottom line
  }

  // create a div tag for this chart
  // if gon.highlight_id exist, add it to the jquery selector path
  var selector_path = '#container-chart';
  var highlight_path = '.highlight-data[data-id="' + gon.highlight_id + '"] ';
  if (gon.highlight_id){
    selector_path = highlight_path + selector_path;
  }
  var chart_id = 'chart-' + ($('#container-chart .chart').length+1);
  $(selector_path).append('<div id="' + chart_id + '" class="chart" style="height: ' + chart_height + 'px;"></div>');

  // create chart
  $(selector_path + ' #' + chart_id).highcharts({
    credits: { enabled: false },
    chart:{
      plotBackgroundColor: null,
      plotBorderWidth: null,
      plotShadow: false,
      events: {
        load: function () {
          if (this.options.chart.forExport) {
              Highcharts.each(this.series, function (series) {
                // only show data labels for shapes that have data
                if (series.name != 'baseLayer'){
                  series.update({
                    dataLabels: {
                      enabled: true,
                      formatter: function () {
                        return this.key + '<br/>' + Highcharts.numberFormat(this.point.options.count, 0) + '   (' + this.y + '%)';
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
        text: build_visual_title(highlight_path, json_chart.title.html),
        useHTML: true,
        style: {'text-align': 'center', 'font-family':"'sourcesans_pro_l', 'sans-serif'", 'font-size': '18px', 'color': '#3c4352'}
    },
    subtitle: {
        text: json_chart.subtitle.html,
        useHTML: true,
        style: {'text-align': 'center'}
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
            showInLegend: true,          
        }
    },
    legend: {
        align: 'center',
        layout: 'vertical',
        symbolHeight: 14,
        symbolWidth: 14,
        itemMarginBottom: 5,
        itemStyle: { "cursor": "pointer", 'font-family':"'sourcesans_pro_l', 'sans-serif'", 'font-size': '12px', 'color': '#3C4352', 'fontWeight': 'normal' },
        symbolRadius: 100
    },
    series: [{
        type: 'pie',
        data: json_chart.data
    }],
    exporting: {
      sourceWidth: 1280,
      sourceHeight: 720,
      filename: json_chart.title.text.replace(/[\|&;\$%@"\'<>\(\)\+,]/g, ""),
      chartOptions:{
        title: {
          text: json_chart.title.text
        },
        subtitle: {
          text: json_chart.subtitle.text
        },
        legend: {
          enabled: false
        }
      },
      buttons: {
        contextButton: {
          symbol: 'url(/assets/svg/download.svg)',
          theme: {
              'stroke-width': 1,
              stroke: 'white',
              r: 0,
              states: {
                  hover: {
                      stroke: 'white',
                      fill: 'white'
                  },
                  select: {
                      stroke: 'white',
                      fill: 'white'
                  }
              }              
          },
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
    },
    navigation: {
          buttonOptions: {
              theme: {
                  'stroke-width': 0,
                  r: 0,
                  states: {
                      hover: {
                          fill: '#fff',
                          stroke: '#eaeaea',
                          'stroke-width': 1                            
                      },
                      select: {                          
                          fill: '#fff',
                          stroke: '#eaeaea',
                          'stroke-width': 1
                      }
                  }
              }
          }
      }

  });

  // now add button to add as highlight
  determine_highlight_button($(selector_path + ' #' + chart_id), json_chart.embed_id, gon.visual_types.pie_chart);  

  // add embed chart button
  add_embed_button($(selector_path + ' #' + chart_id), json_chart.embed_id);

  // add highlight description button
  add_highlight_description_button($(selector_path + ' #' + chart_id), json_chart.embed_id);

  // add disclaimer link
  add_disclaimer_link($(selector_path + ' #' + chart_id));
}


////////////////////////////////////////////////
// build time series line chart
////////////////////////////////////////////////
function build_time_series_chart(json_chart, chart_height){
  if (chart_height == undefined){
    chart_height = 501; // need the 1 for the border bottom line
  }

  // create a div tag for this chart
  // if gon.highlight_id exist, add it to the jquery selector path
  var selector_path = '#container-chart';
  var highlight_path = '.highlight-data[data-id="' + gon.highlight_id + '"] ';
  if (gon.highlight_id){
    selector_path = highlight_path + selector_path;
  }
  var chart_id = 'chart-' + ($('#container-chart .chart').length+1);
  $(selector_path).append('<div id="' + chart_id + '" class="chart" style="height: ' + chart_height + 'px;"></div>');

  // create chart
  $(selector_path + ' #' + chart_id).highcharts({
    credits: { enabled: false },
    chart: {
        plotBackgroundColor: null,
        plotBorderWidth: null,
        plotShadow: false
    },
    title: {
        text: build_visual_title(highlight_path, json_chart.title.html),
        useHTML: true,
        style: {'text-align': 'center', 'font-family':"'sourcesans_pro_l', 'sans-serif'", 'font-size': '18px', 'color': '#3c4352' }
    },
    subtitle: {
        text: json_chart.subtitle.html,
        useHTML: true,
        style: {'text-align': 'center'}
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
        symbolWidth: 14,
        symbolHeight: 14,
        itemMarginBottom: 5,
        itemStyle: { "cursor": "pointer", 'font-family':"'sourcesans_pro_l', 'sans-serif'", 'font-size': '12px', 'color': '#3C4352', 'fontWeight': 'normal' },
        symbolRadius: 100
    },
    series: json_chart.data,
    exporting: {
      sourceWidth: 1280,
      sourceHeight: chart_height,
      filename: json_chart.title.text.replace(/[\|&;\$%@"'<>\(\)\+,]/g, ""),
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
          symbol: 'url(/assets/svg/download.svg)',
          theme: {
              'stroke-width': 1,
              stroke: 'white',
              r: 0,
              states: {
                  hover: {
                      stroke: 'white',
                      fill: 'white'
                  },
                  select: {
                      stroke: 'white',
                      fill: 'white'
                  }
              }              
          },
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

  // now add button to add as highlight
  determine_highlight_button($(selector_path + ' #' + chart_id), json_chart.embed_id, gon.visual_types.line_chart);  

  // add embed chart button
  add_embed_button($(selector_path + ' #' + chart_id), json_chart.embed_id);

  // add highlight description button
  add_highlight_description_button($(selector_path + ' #' + chart_id), json_chart.embed_id);

  // add disclaimer link
  add_disclaimer_link($(selector_path + ' #' + chart_id));
}


////////////////////////////////////////////////
// update the page title to include the title of the analysis
function build_page_title(json){
  // get current page title
  // first index - dataset/time series title
  // last index - app name
  var title_parts = $('title').html().split(' | ');

  if (json.results.title.text){
    $('head title').html(title_parts[0] + ' | ' + json.results.title.text + ' | ' + title_parts[title_parts.length-1])
  }else{
    $('head title').html(title_parts[0] + ' | ' + title_parts[title_parts.length-1])
  }
   
}

function resizeExploreData(){
    var w = $(window).width(),
        h = $(window).height(),
        expform = $('#explore-form');
    if(expform.length)
    {
      var offset = expform.offset(),
      expformWidth = expform.width();
      var offsetWidth = offset.left == 0 ? 0 : (offset.left + 302);
      var tmp = expform.find('form');
      $('#explore-form #jumpto').css({'height': (offset.left != 0 ? (h-(tmp.offset().top+tmp.height()+41+2)) : 'auto')  });
      $('#explore-data-content  .tab-pane').css({'width': w-offsetWidth, 'height':h-(51+31+40+41+2)});
    }
}
////////////////////////////////////////////////
$(document).ready(function() {

  // record a chart as a highlight
  $('#tab-chart, #tab-map').on('click', 'a.add-highlight', function(e){
    e.preventDefault();
    var link = this;

    $.ajax({
      type: "POST",
      url: $(link).attr('href'),
      data: {embed_id: $(link).data('embed-id'), visual_type: $(link).data('visual-type')},
      dataType: 'json'
    }).done(function(success){
      if (success){
        // record embed id
        gon.embed_ids.push($(link).data('embed-id'));

        // show delete button
        $(link).fadeOut(function(){
          delete_highlight_button($(link).parent(), $(link).data('embed-id'), $(link).data('visual-type'));
        });
      }else{
      }
    });

  });


  // delete a chart as a highlight
  $('#tab-chart, #tab-map').on('click', 'a.delete-highlight', function(e){
    e.preventDefault();
    var link = this;
    var text = gon.confirm_text != undefined ? gon.confirm_text : 'Are you sure?';

    var answer=confirm(text);
    if(answer){
      $.ajax({
        type: "POST",
        url: $(link).attr('href'),
        data: {embed_id: $(link).data('embed-id'), visual_type: $(link).data('visual-type')},
        dataType: 'json'
      }).done(function(success){
        if (success){
          // delete embed id
          gon.embed_ids.splice( $.inArray($(link).data('embed-id'), gon.embed_ids), 1 );
          
          // show delete button
          $(link).parent().find('a.description-highlight').fadeOut().remove();
          $(link).fadeOut(function(){
            add_highlight_button($(link).parent(), $(link).data('embed-id'), $(link).data('visual-type'));
          });
        }else{

        }
      });
    }
  });

  
// share button with slide effect used on dashboard, timeseries and explore page
  if(is_touch) {
    $('.share-box').on('click', function(){ share_toggle(($(this).attr('data-state') == 'in' ? 'out' : 'in'),$(this)); }); 
  }
  else {
    $('.share-box').hover(function(){ 
      share_toggle('in',$(this));
    }, function() { share_toggle('out',$(this)); }); 
  }
// tabs - on li click fire inner a tag
  $(document).on('click', '.tabs li', function() {    
    $(this).find('a').tab('show');
  });
  $(document).on('click', '.tab-content .up', function () {    
    $('body').animate({ scrollTop: 0 }, 1500);
  });


  // show embed chart modal
  $(document).on('click', '.embed-chart', function () {
    var url = $(this).attr('data-href');
    var popup = $('#embed-popup').html();
    var embed_iframe = $('#embed-iframe').html();
     modal(popup,
      {
        position:'center', 
        events: [
          { 
            event:'change',
            element: '.wide input', 
            callback:function()
            {  
              var t = $(this);
              var par = t.closest('.box');
              par.find('textarea').val($(embed_iframe).attr('src', url).attr('width', t.val()).attr('height', par.find('.high input').val()).prop('outerHTML'));
            }
          },
          {  event:'change',
             element: '.high input',
             callback:function()
             {
                var t = $(this);
                var par = t.closest('.box');
                par.find('textarea').val($(embed_iframe).attr('src', url).attr('width', t.val()).attr('height', par.find('.high input').val()).prop('outerHTML'));
             }
          }
        ],
        before: function(t)
        {
          t.find('textarea').val($(embed_iframe).attr('src', url).attr('width', t.find('.wide input').val()).attr('height', t.find('.high input').val()).prop('outerHTML'));
        }
      }
    );
  });


  // show highlight description modal
  $(document).on('click', '.highlight-description-chart', function () {
    var text = $(this).attr('data-text').replace(/(?:\r\n|\r|\n)/g, '<br />');
    var popup = $('#highlight-description-popup').html();
     modal(popup,
      {
        position:'center', 
        before: function(t)
        {
          t.find('.text').html(text);
        }
      }
    );
  });


  // show highlight description form
  $(document).on('click', '.description-highlight', function (e) {
    var url = $(this).attr('data-href');
    var embed_id = $(this).attr('data-embed-id');
    var chart = $(this).closest('div');

    // get the form for this embed id
    $.ajax({
      type: "GET",
      url: url,
      data: {embed_id: embed_id},
      dataType: 'json'
    }).done(function(data){
      if (data && data.form != null){
        // got form, create modal popup
        modal($('#description-form-popup').html().replace('{form}', data.form),
        {
          position:'center', 
          events: [
            { 
              event:'submit',
              element: 'form.highlight', 
              callback:function(e)
              {  
                e.preventDefault();
                var params = $(this).serialize();
                params += '&embed_id=' + embed_id;
                var desc = $(this).find('textarea:first').val();

                // submit the form and close window
                $.ajax({
                  type: "POST",
                  url: $(this).attr('action'),
                  data: params,
                  dataType: 'json'
                }).done(function(data){
                  if (data && data.success == true){
                    // turn off show desc button if exists 
                    $(chart).find('div.highlight-description-chart').remove();

                    if (desc != undefined && desc != ''){
                      // show desc button 
                      add_highlight_description_button(chart, embed_id);
                    }

                    // close popup
                    js_modal_off();

                    // show success message
                    $('#page-wrapper .content').prepend(notification('success', data.message, 'message'));
                    $('#page-wrapper .content > .message').delay(3000).fadeOut(3000);
                  }else{
                    $('#js_modal .popup .header').after(notification('error', data.message));
                  }
                });
              }
            },
          ]
        }
        );
      }
    });
  });


  
  resizeExploreData();
  $( window ).resize(function() { resizeExploreData(); });
});
function share_toggle(state,t)
{
  var at = t.find('.addthis_sharing_toolbox'),
      dir = { },
      dir2 = { };
  
  if(state == 'in') {   
    var atwidth = at.width();

    var tmp = 'right';
    var tmp2 = 'left';
    if(at.offset().left < atwidth)
    {
      tmp = 'left';
      tmp2 = 'right';
    }
    dir[tmp] = atwidth;
    dir2[tmp2] = 'initial';
    t.attr('data-dir',tmp);
    t.find('.prompt').css(dir2).animate(dir, 500, function(){  });
    at.delay( 500 ).animate({"opacity":1}, 100);
  }
  else {

    var tmp = t.attr('data-dir');
    var tmp2 = tmp == 'left' ? 'right' : 'left';
    dir[tmp] = 0;
    dir2[tmp2] = 'initial';
    at.stop().animate({"opacity":0}, 100);
    t.find('.prompt').css(dir2).stop().delay( 100 ).animate(dir, 250);
  }
  t.attr('data-state', state);
}
