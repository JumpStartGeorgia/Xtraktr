/*global  $, gon, Highcharts, modal, js_modal_off, notification, is_touch, highmap_shapes, page_wrapper, js */
/*eslint camelcase: 0, no-underscore-dangle: 0, no-unused-vars: 0*/
// collection of functions to build charts/maps
// for datasets and time series


String.prototype.upcase = function () {
  return this[0].toUpperCase() + this.substring(1);
};
var buttons_options = {
    contextButton: {
      symbol: "url(/assets/svg/download.svg)",
      x: 20,
      theme: {
        "stroke-width": 1,
        stroke: "white",
        states: {
          hover: {
            stroke: "white",
            fill: "white"
          },
          select: {
            stroke: "white",
            fill: "white"
          }
        }
      },
      menuItems: [
        {
          text: gon.highcharts_png,
          onclick: function () {
            this.exportChart({type: "image/png"});
          }
        },
        {
          text: gon.highcharts_jpg,
          onclick: function () {
            this.exportChart({type: "image/jpeg"});
          }
        },
        {
          text: gon.highcharts_pdf,
          onclick: function () {
            this.exportChart({type: "application/pdf"});
          }
        },
        {
          text: gon.highcharts_svg,
          onclick: function () {
            this.exportChart({type: "image/svg+xml"});
          }
        }
      ]
    }
  },
  style1 = {"text-align": "center", "font-family":"sourcesans_pro_l, sans-serif", "font-size": "18px", "color": "#3c4352", "padding": "0px 86px"},
  style2 = { "cursor": "pointer", "font-family":"sourcesans_pro_l, sans-serif", "font-size": "12px", "color": "#3C4352", "fontWeight": "normal" };


function map_chart_height (json) { // determine heights of chart based on number of answers and group text
  var chart_height = 501; // need the 1 for the border bottom line
  // if showing group, add space for it
  if (json.question.group && json.question.group.include_in_charts){
    chart_height += 24;
  }
  if (json.broken_down_by && json.broken_down_by.group && json.broken_down_by.group.include_in_charts){
    chart_height += 24;
  }
  if (json.filtered_by && json.filtered_by.group && json.filtered_by.group.include_in_charts){
    chart_height += 24;
  }

  return chart_height;
}
function pie_chart_height (json) {
  var chart_height = 501, // need the 1 for the border bottom line
    q_ans_len = json.question.hasOwnProperty("answers") ? json.question.answers.length : 0;

  if (q_ans_len >= 5){
    chart_height = 425 + q_ans_len*21 + 1;
  }
  // if showing group, add space for it
  if (json.question.group && json.question.group.include_in_charts){
    chart_height += 24;
  }
  if (json.filtered_by && json.filtered_by.group && json.filtered_by.group.include_in_charts){
    chart_height += 24;
  }

  return chart_height;
}
var bar_chart_height = pie_chart_height,
  histogramm_chart_height = pie_chart_height,
  scatter_chart_height = crosstab_chart_height;

function crosstab_chart_height (json) {
  var chart_height = 501, // need the 1 for the border bottom line
    q_ans_len = json.question.hasOwnProperty("answers") ? json.question.answers.length : 0,
    bd_ans_len = json.broken_down_by.hasOwnProperty("answers") ? json.broken_down_by.answers.length : 0;

  if(q_ans_len + bd_ans_len >= 10){
    chart_height = 330 + q_ans_len*26.125 + bd_ans_len*21 + 1;
  }
  // if showing group, add space for it
  if (json.question.group && json.question.group.include_in_charts){
    chart_height += 24;
  }
  if (json.broken_down_by.group && json.broken_down_by.group.include_in_charts){
    chart_height += 24;
  }
  if (json.filtered_by && json.filtered_by.group && json.filtered_by.group.include_in_charts){
    chart_height += 24;
  }

  return chart_height;
}

function time_series_chart_height (json){
  var chart_height = 501; // need the 1 for the border bottom line
  if (json.question.answers.length >= 5){
    chart_height = 425 + json.question.answers.length*21 + 1;
  }
  // if showing group, add space for it
  if (json.question.group && json.question.group.include_in_charts){
    chart_height += 24;
  }
  if (json.filtered_by && json.filtered_by.group && json.filtered_by.group.include_in_charts){
    chart_height += 24;
  }

  // add space for each dataset in the total responses
  if (json.datasets){
    chart_height += json.datasets.length*20;
  }

  return chart_height;
}

function add_disclaimer_link (visual_element){ // add disclaimer link
  if (gon.disclaimer_link && gon.disclaimer_text) {
    $(visual_element).append("<a class='chart-disclaimer' href='" + gon.disclaimer_link + "' target='_blank'>" + gon.disclaimer_text + "</a>");
  }
}

function add_powered_by_link (visual_element){ // add powered by xtraktr link
  if (gon.powered_by_link && gon.powered_by_text){
    $(visual_element).append("<a class='chart-powered-by' href='" + gon.powered_by_link + "' target='_blank' title='" + gon.powered_by_title + "'>" + gon.powered_by_text + "</a>");
  }
}

function add_weighted_footnote (visual_element, weight_name){ // add weighted footnote
  if (gon.weighted_footnote && weight_name){
    $(visual_element).append("<span class='chart-weighted-footnote'><span class='footnote-flag'>*</span> " + gon.weighted_footnote + weight_name + "</span>");
  }
}

function determine_highlight_button (visual_element, embed_id, visual_type) { // determine which highlight button to add to chart
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

function add_highlight_button (visual_element, embed_id, visual_type) { // add add highlight button to chart
  if (gon.is_admin){
    var parent = $(visual_element).parent();

    // create add link
    var link = "<a class='add-highlight btn btn-default btn-xs' href='" + $(parent).data("add-highlight") + "' data-embed-id='" + embed_id + "' data-visual-type='" + visual_type + "' ";
    link += "title='" + gon.add_highlight_text + "' data-placement='right'><span class='glyphicon glyphicon-star' aria-hidden='true'></span></a>";

    // add link to visual
    $(visual_element).append(link);
  }
}

function delete_highlight_button (visual_element, embed_id, visual_type) { // add delete highlight button to chart
  if (gon.is_admin){
    var parent = $(visual_element).parent();

    // create delete link
    var link = "<a class='delete-highlight btn btn-default btn-xs' href='" + $(parent).data("delete-highlight") + "' data-embed-id='" + embed_id + "' data-visual-type='" + visual_type + "' ";
    link += "title='" + gon.delete_highlight_text + "' data-placement='right'><span class='glyphicon glyphicon-star' aria-hidden='true'></span></a>";

    // create desc link
    link += "<a class='description-highlight btn btn-default btn-xs' data-href='" + $(parent).data("description") + "' data-embed-id='" + embed_id + "' ";
    link += "title='" + gon.description_highlight_text + "' data-placement='right'><span class='glyphicon glyphicon-pencil' aria-hidden='true'></span></a>";

    // add link to visual
    $(visual_element).append(link);

  }
}

function add_embed_button (visual_element, embed_id) { // add embed button to chart
  if (gon.embed_button_link){
    $(visual_element).append("<div class='embed-chart' data-href='" + gon.embed_button_link.replace("replace", embed_id) + "'" + "title='" + gon.embed_chart_text + "' data-placement='bottom'><img src='/assets/svg/embed.svg' alt='" + gon.embed_chart_text + "' /></div>");
  }
}

function add_highlight_description_button (visual_element, embed_id) { // add highlight description button to chart
  if (gon.get_highlight_desc_link && embed_id){
    // get the description for this embed_id
    $.ajax({
      type: "POST",
      url: gon.get_highlight_desc_link,
      data: {embed_id: embed_id},
      dataType: "json"
    }).done(function (data){
      if (data && data.description != null && data.description != ""){
        // create link
        // - if the embed link does not exist, make sure it is in the correct place
        var cls = "";
        if (gon.embed_button_link){
          cls = " with-embed-chart";
        }
        var link = "<div class='highlight-description-chart " + cls + "' data-text='" + data.description + "'";
        link += "title='" + gon.highlight_description_chart_text + "' data-placement='bottom'><img src='/assets/svg/desc_icon.svg' alt='" + data.description + "' /></div>";

        // add link to visual
        $(visual_element).append(link);
      }
    });

  }
}

function build_visual_title (highlight_path, text) { // build title/sub title for chart/map // if gon.visual_link is present, turn the title into a link
  return $(highlight_path).data("explore-link") !== undefined
          ? ("<a class='visual-title-link' target='_parent' href='" + $(highlight_path).data("explore-link") + "'>" + text + "</a>")
          : text;
}

function build_highmap (shape_question_code, adjustable_max, json_map_set, chart_height, weight_name) { // build highmap

  var opt = prepareChart(chart_height, "map"),
    selector_path = opt[1],
    highlight_path = opt[2],
    map_id = opt[3];

  chart_height = opt[0];

  var max = 100;
  if (adjustable_max == true){
    //  for use in the color axis
    // get the max percent value and round temp_max to the nearest 10s
    max = Math.ceil(Math.max.apply(Math, $.map(json_map_set.data, function (obj){return obj.value; })) / 10)*10;
  }

  $(selector_path + " #" + map_id).highcharts("Map", {
    chart:{
      events: {
        load: function () {
          if (this.options.chart.forExport) {
            Highcharts.each(this.series, function (series) {
              // only show data labels for shapes that have data
              if (series.name != "baseLayer"){
                series.update({
                  dataLabels: {
                    enabled: true,
                    color: "white",
                    formatter: function () {
                      return this.point.display_name + "<br/>" + Highcharts.numberFormat(this.point.count, 0) + "   (" + this.point.value + "%)";
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
      style: style1
    },
    subtitle: {
      text: json_map_set.subtitle.html,
      useHTML: true,
      style: {"text-align": "center"}
    },
    mapNavigation: {
      enabled: true,
      enableMouseWheelZoom: false,
      buttonOptions: {
        align: "left",
        verticalAlign: "bottom",
        alignTo: "plotBox",        
        theme: {
          states: {
            hover: {
              stroke: "#999999",
              fill: "#eeeeee"
            },
            select: {
              stroke: "#999999",
              fill: "#eeeeee"
            }
          }
        }
      },
      buttons: {
        zoomIn: {
          y: -38
        },
        zoomOut: {
          y: -10
        }
      }
    },
    colorAxis: {
      min: 0,
      max: max,
      minColor: "#d2f1f9",
      maxColor: "#0086a5",
      labels: {
        formatter: function () {
          return this.value + "%";
        }
      }
    },
    loading: {
      labelStyle: {
        color: "white",
        fontSize: "20px"
      },
      style: {
        backgroundColor: "#000"
      }
    },
    series : [{
      // create base layer for N/A
      // will be overriden with next data series if data exists
      data : Highcharts.geojson(highmap_shapes[shape_question_code], "map"),
      name: "baseLayer",
      color: "#eeeeee",
      showInLegend: false,
      tooltip: {
        backgroundColor: "#fff",
        headerFormat: "",
        pointFormat: "<b>{point.properties.name_en}:</b> " + gon.na
        // using name_en in case shape has no data and therefore no display_name
      },
      borderColor: "#f6f6f6",
      borderWidth: 2,
      states: {
        hover: {
          color: "#0086a5",
          borderColor: "#3c4352",
          borderWidth: 2
        }
      }
    },
    {
      // shape layer with data
      data : json_map_set.data,
      name: "dataLayer",
      mapData: highmap_shapes[shape_question_code],
      joinBy: ["name_en", "shape_name"],
      allAreas: false, // if shape does not have value, do not show it so base layer above will show
      tooltip: {
        backgroundColor: "#fff",
        headerFormat: "",
        pointFormat: "<b>{point.display_name}:</b> {point.count:,.0f} ({point.value}%)"
      },
      borderColor: "#f6f6f6",
      borderWidth: 2,
      states: {
        hover: {
          color: "#0086a5",
          borderColor: "#3c4352",
          borderWidth: 2
        }
      },
      dataLabels: {
        enabled: true,
        color: "#3C4352",
        style: {
          textShadow: false
        },
        formatter: function () {
          return Highcharts.numberFormat(this.point.count, 0) + "   (" + this.point.value + "%)";
        }
      }
    }],
    exporting: {
      sourceWidth: 1280,
      sourceHeight: chart_height,
      filename: json_map_set.title.text.replace(/[\|&;\$%@"\'<>\(\)\+,]/g, ""),
      chartOptions:{
        chart: {
          spacingLeft:110,
          spacingRight:110
        },
        title: {
          useHTML: false,
          text: json_map_set.title.text
        },
        subtitle: {
          useHTML: false,
          text: json_map_set.subtitle.text
        }
      },
      buttons: buttons_options
    }
  }, function () {
    if(js.isFox)
    {
      var t = this;
      setTimeout(function () {
        var rect = $(t.container).find(".highcharts-legend-item > rect"),
          rect_value = rect.attr("fill");
        rect.attr("fill", "").attr("fill", rect_value);
      }, 500);
    }
  });


  finalizeChart($(selector_path + " #" + map_id), json_map_set.embed_id, weight_name, gon.visual_types.map);
}

function build_bar_chart (json_chart, chart_height, weight_name) { // build pie chart
  var opt = prepareChart(chart_height, "chart"),
    selector_path = opt[1],
    highlight_path = opt[2],
    chart_id = opt[3];

  chart_height = opt[0];

  // create chart
  $(selector_path + " #" + chart_id).addClass("pie_or_bar");
  $(selector_path + " #" + chart_id).highcharts({
    chart: {
      type: "column",
      inverted: true
    },
    title: {
      text: build_visual_title(highlight_path, json_chart.title.html),
      useHTML: true,
      style: style1
    },
    subtitle: {
      text: json_chart.subtitle.html,
      useHTML: true,
      style: {"text-align": "center"}
    },
    xAxis: {
      categories: json_chart.data.map(function (d) { return d.name.upcase(); }),
      title: {
        text:null
      },
      labels:
      {
        style: { "color": "#3c4352", "fontSize": "14px", "fontFamily":"'sourcesans_pro', 'sans-serif'", "fontWeight": "normal", "textAlign": "right" },
        step: 1,
        formatter: function () { return (this.value+"").upcase(); }
      }
    },
    yAxis: {
      floor: 0,
      ceiling: 100,
      title: {
        text: gon.percent
      }
    },
    tooltip: {
      backgroundColor: "#fff",
      formatter: function () {
        return "<b>" + this.key + ":</b> " + Highcharts.numberFormat(this.point.options.count, 0) + " (" + this.y + "%)";
      }
    },
    legend: { enabled: false },
    series: [{ data: json_chart.data }],
    exporting: {
      sourceWidth: 1280,
      sourceHeight: chart_height,
      filename: json_chart.title.text.replace(/[\|&;\$%@"\'<>\(\)\+,]/g, ""),
      chartOptions:{
        chart: {
          spacingLeft:110,
          spacingRight:110
        },
        title: {
          useHTML: false,
          text: json_chart.title.text
        },
        subtitle: {
          useHTML: false,
          text: json_chart.subtitle.text
        },
        legend: {
          enabled: false
        }
      },
      buttons: buttons_options
    },
    navigation: {
      buttonOptions: {
        theme: {
          "stroke-width": 0,
          r: 0,
          states: {
            hover: {
              fill: "#fff",
              stroke: "#eaeaea",
              "stroke-width": 1
            },
            select: {
              fill: "#fff",
              stroke: "#eaeaea",
              "stroke-width": 1
            }
          }
        }
      }
    }

  });

  finalizeChart($(selector_path + " #" + chart_id), json_chart.embed_id.bar_chart, weight_name, gon.visual_types.pie_chart);
}

function build_histogramm_chart (json_chart, chart_height, weight_name) { // build pie chart
  var opt = prepareChart(chart_height, "chart"),
    selector_path = opt[1],
    highlight_path = opt[2],
    chart_id = opt[3],
    nm = json_chart.numerical; // numerical meta data

  chart_height = opt[0];  
  $(selector_path + " #" + chart_id).highcharts({
    colors: ["#C6CA53"],
    chart: {
      type: "column"
    },
    title: {
      text: build_visual_title(highlight_path, json_chart.title.html),
      useHTML: true,
      style: style1
    },
    subtitle: {
      text: json_chart.subtitle.html,
      useHTML: true,
      style: {"text-align": "center"}
    },
    xAxis: {
      title: { text: nm.title },
      tickPositions: formatLabel(),
      startOnTick: true,
      endOnTick: true,
    },
    yAxis: { title: null },

    plotOptions: {
      column: {
        groupPadding: 0,
        pointPadding: 0,
        borderWidth: 0,
        pointPlacement: "between"
      }
    },
    series: [{ data:  json_chart.data.map(function (d, i){ return { x:nm.min_range + nm.width*i, y: d.count, percent: d.y }; }) }],
    legend: { enabled: false },
    tooltip: {
      formatter: function () { return this.y + " (" + this.point.percent + "%)"; }
    },
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
        },
        legend: {
          enabled: false
        }
      },
      buttons: buttons_options
    },
    navigation: {
      buttonOptions: {
        theme: {
          "stroke-width": 0,
          r: 0,
          states: {
            hover: {
              fill: "#fff",
              stroke: "#eaeaea",
              "stroke-width": 1
            },
            select: {
              fill: "#fff",
              stroke: "#eaeaea",
              "stroke-width": 1
            }
          }
        }
      }
    }
  });

  function formatLabel () {
    var v = [], i;
    for(i = 0; i <= nm.size; ++i) {
      v.push(nm.min_range+i*nm.width);
    }
    return v;
  }
  finalizeChart($(selector_path + " #" + chart_id), json_chart.embed_id.bar_chart, weight_name, gon.visual_types.pie_chart);
}

function build_crosstab_chart (meta, json_chart, chart_height, weight_name){ // build crosstab chart
  var opt = prepareChart(chart_height, "chart"),
    selector_path = opt[1],
    highlight_path = opt[2],
    chart_id = opt[3];

  chart_height = opt[0];

  // create chart
  $(selector_path + " #" + chart_id).highcharts({
    chart: {
      type: "bar"
    },
    title: {
      text: build_visual_title(highlight_path, json_chart.title.html),
      useHTML: true,
      style: style1
    },
    subtitle: {
      text: json_chart.subtitle.html,
      useHTML: true,
      style: {"text-align": "center"}
    },
    xAxis: {
      categories: json_chart.labels,
      title: {
        text: "<span class='code-highlight'>" + meta.qtext + "</span>",
        useHTML: true,
        style: { "fontSize": "14px", "fontWeight": "bold" }
      },
      labels:
      {
        style: { "color": "#3c4352", "fontSize": "14px", "fontFamily":"'sourcesans_pro', 'sans-serif'", "fontWeight": "normal", "textAlign": "right" },
        // useHTML: true,
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
      },
      reversedStacks: false
    },
    legend: {
      title: {
        text: meta.bcode,
        style: { "color": "#00adee", "fontSize": "18px", "fontFamily":"'sourcesans_pro_sb', 'sans-serif'", "fontWeight": "normal" }
      },
      useHTML: true,
      layout: 'vertical',
      symbolWidth: 14,
      symbolHeight: 14,
      itemMarginBottom: 5,
      itemStyle: style2,
      symbolRadius: 100
    },
    tooltip: {
      pointFormat: "<span style='color:{series.color}'>{series.name}</span>: <b>{point.y:,.0f}</b> ({point.percentage:.2f}%)<br/>",
      //shared: true,
      backgroundColor: "rgba(255, 255, 255, 0.95)",
      followPointer: true
    },
    plotOptions: {
      bar: {
        stacking: "percent"
      }
    },
    series: json_chart.data,
    exporting: {
      sourceWidth: 1280,
      sourceHeight: chart_height,
      filename: json_chart.title.text.replace(/[\|&;\$%@"\'<>\(\)\+,]/g, ""),
      chartOptions:{
        chart: {
          spacingLeft:110,
          spacingRight:110
        },
        title: {
          useHTML: false,
          text: json_chart.title.text
        },
        subtitle: {
          useHTML: false,
          text: json_chart.subtitle.text
        }
      },
      buttons: buttons_options
    }
  });

  finalizeChart($(selector_path + " #" + chart_id), json_chart.embed_id, weight_name, gon.visual_types.crosstab_chart);
}

function build_scatter_chart (meta, json_chart, chart_height, weight_name){ // build crosstab chart
  var opt = prepareChart(chart_height, "chart"),
    selector_path = opt[1],
    highlight_path = opt[2],
    chart_id = opt[3],
    colors = Highcharts.getOptions().colors;

  chart_height = opt[0];

  // create chart
  $(selector_path + " #" + chart_id).highcharts({
    chart: {
      type: "scatter",
      zoomType: "xy"
    },
    title: {
      text: build_visual_title(highlight_path, json_chart.title.html),
      useHTML: true,
      style: style1
    },
    subtitle: {
      text: json_chart.subtitle.html,
      useHTML: true,
      style: {"text-align": "center"}
    },
    xAxis: {
      title: {
        text: "<span class='code-highlight'>" + meta.qcode + "</span>",
        useHTML: true,
        style: { "fontSize": "14px", "fontWeight": "bold" }
      },
      labels:
      {
        style: { "color": "#777c86", "fontSize": "14px", "fontFamily":"'sourcesans_pro', 'sans-serif'", "fontWeight": "normal", "textAlign": "right" },
        useHTML: true,
      }
    },
    yAxis: {      
      title: {
        text: "<span class='code-highlight'>" + meta.bcode + "</span>",
        useHTML: true,
        style: { "fontSize": "14px", "fontWeight": "bold" }
      },
      labels:
      {
        style: { "color": "#777c86", "fontSize": "14px", "fontFamily":"'sourcesans_pro', 'sans-serif'", "fontWeight": "normal" },
        useHTML: true
      }
    },
    legend: {
      enabled: meta.filtered,
      title: {
        text: null,// meta.bcode,
        style: { "color": "#d67456", "fontSize": "18px", "fontFamily":"'sourcesans_pro_sb', 'sans-serif'", "fontWeight": "normal" }
      },
      useHTML: true,
      layout: "vertical",
      symbolWidth: 14,
      symbolHeight: 14,
      itemMarginBottom: 5,
      itemStyle: style2,
      symbolRadius: 100
    },
    tooltip: {
      useHTML: true,
      formatter: function () {
        return (meta.filtered ? "<div class='title'>" + this.series.name + "</div>" : "") + 
          "<span class='tooltip-code-highlight'>" + meta.qcode + "</span>: " + this.x + "<br/>" +
          "<span class='tooltip-code-highlight'>" + meta.bcode + "</span>: " + this.y + "<br/>";
      },
      // pointFormat: "<span style='color:{series.color}'>{series.name}</span>: <b>{point.y:,.0f}</b> ({point.percentage:.2f}%)<br/>",
      // //shared: true,
      // backgroundColor: "rgba(255, 255, 255, 0.95)",
      followPointer: true
    },
    plotOptions: {
      scatter: {
        marker: {
          radius: 3,
          symbol: "circle"
        }
      }
    },  
    series: meta.filtered ? json_chart.data.map(function (d, i) { return {name: d.name, data: d.data, color: rgba(colors[i%colors.length]) }; }) : [{ data: json_chart.data, color: rgba(colors[0]) }],
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
      buttons: buttons_options
    }
  });


  finalizeChart($(selector_path + " #" + chart_id), json_chart.embed_id, weight_name, gon.visual_types.crosstab_chart);
}

function build_pie_chart (json_chart, chart_height, weight_name) { // build pie chart

  var opt = prepareChart(chart_height, "chart"),
    selector_path = opt[1],
    highlight_path = opt[2],
    chart_id = opt[3];

  chart_height = opt[0];

  // create chart
  $(selector_path + " #" + chart_id).highcharts({
    chart:{
      plotBackgroundColor: null,
      plotBorderWidth: null,
      plotShadow: false,
      events: {
        load: function () {
          if (this.options.chart.forExport) {
            Highcharts.each(this.series, function (series) {
              series.update({
                dataLabels: {
                  enabled: true,
                  formatter: function () {
                    return this.key + "<br/>" + Highcharts.numberFormat(this.point.options.count, 0) + "   (" + this.y + "%)";
                  }
                }
              }, false);
            });
            this.redraw();
          }
        }
      }
    },
    title: {
      text: build_visual_title(highlight_path, json_chart.title.html),
      useHTML: true,
      style: style1
    },
    subtitle: {
      text: json_chart.subtitle.html,
      useHTML: true,
      style: {"text-align": "center"}
    },
    tooltip: {
      backgroundColor: "#fff",
      formatter: function () {
        return "<b>" + this.key + ":</b> " + Highcharts.numberFormat(this.point.options.count, 0) + " (" + this.y + "%)";
      }
    },
    plotOptions: {
      pie: {
        cursor: "pointer",
        dataLabels: {
          enabled: false
        },
        showInLegend: true
      }
    },
    legend: {
      align: "center",
      layout: "vertical",
      symbolHeight: 14,
      symbolWidth: 14,
      itemMarginBottom: 5,
      itemStyle: style2,
      symbolRadius: 100
    },
    series: [{
      type: "pie",
      data: json_chart.data
    }],
    exporting: {
      sourceWidth: 1280,
      sourceHeight: chart_height,
      filename: json_chart.title.text.replace(/[\|&;\$%@"\'<>\(\)\+,]/g, ""),
      chartOptions:{
        chart: {
          spacingLeft:110,
          spacingRight:110
        },
        title: {
          useHTML: false,
          text: json_chart.title.text
        },
        subtitle: {
          useHTML: false,
          text: json_chart.subtitle.text
        },
        legend: {
          enabled: false
        }
      },
      buttons: buttons_options
    },
    navigation: {
      buttonOptions: {
        theme: {
          "stroke-width": 0,
          r: 0,
          states: {
            hover: {
              fill: "#fff",
              stroke: "#eaeaea",
              "stroke-width": 1
            },
            select: {
              fill: "#fff",
              stroke: "#eaeaea",
              "stroke-width": 1
            }
          }
        }
      }
    }

  });  
  finalizeChart($(selector_path + " #" + chart_id), json_chart.embed_id.pie_chart, weight_name, gon.visual_types.pie_chart);
}

function build_time_series_chart (json_chart, chart_height, weight_name) { // build time series line chart

  var opt = prepareChart(chart_height, "chart"),
    selector_path = opt[1],
    highlight_path = opt[2],
    chart_id = opt[3];

  chart_height = opt[0];

  // create chart
  $(selector_path + " #" + chart_id).highcharts({
    chart: {
      plotBackgroundColor: null,
      plotBorderWidth: null,
      plotShadow: false
    },
    title: {
      text: build_visual_title(highlight_path, json_chart.title.html),
      useHTML: true,
      style: style1
    },
    subtitle: {
      text: json_chart.subtitle.html,
      useHTML: true,
      style: {"text-align": "center"}
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
        color: "#808080"
      }]
    },
    tooltip: {
      backgroundColor: "#fff",
      headerFormat: "<span style='font-size: 13px; font-style: italic; font-weight: bold;'>{point.key}</span><br/>",
      pointFormat: "<span style='font-weight: bold;'>{series.name}</span>: {point.count:,.0f} ({point.y:.2f}%)<br/>"
    },
    legend: {
      layout: "vertical",
      symbolWidth: 14,
      symbolHeight: 14,
      itemMarginBottom: 5,
      itemStyle: style2,
      symbolRadius: 100
    },
    series: json_chart.data,
    exporting: {
      sourceWidth: 1280,
      sourceHeight: chart_height,
      filename: json_chart.title.text.replace(/[\|&;\$%@"'<>\(\)\+,]/g, ""),
      chartOptions:{
        chart: {
          spacingLeft:110,
          spacingRight:110
        },
        title: {
          useHTML: false,
          text: json_chart.title.text
        },
        subtitle: {
          useHTML: false,
          text: json_chart.subtitle.text
        }
      },
      buttons: buttons_options
    }
  });

  finalizeChart($(selector_path + " #" + chart_id), json_chart.embed_id, weight_name, gon.visual_types.line_chart);
}

function prepareChart (chart_height, type) {
  var opt = [
    (typeof chart_height === "undefined" ? 501 : chart_height), // need the 1 for the border bottom line
    "#container-" + type,
    ".highlight-data[data-id='" + gon.highlight_id + "'] ",
    type + "-" + ($("#container-" + type + " ." + type).length+1)
  ];

  if(gon.highlight_id){ opt[1] = opt[2] + opt[1]; } // if gon.highlight_id exist, add it to the jquery selector path

  $(opt[1]).append("<div id='" + opt[3] + "' class='" + type + "' style='height: " + opt[0] + "px;'></div>"); // create a div tag for this chart

  return opt;
}


function finalizeChart (selector, embed_id, weight_name, visual_types) {

  // now add button to add as highlight
  determine_highlight_button(selector, embed_id, visual_types);

  // add embed chart button
  add_embed_button(selector, embed_id);

  // add highlight description button
  add_highlight_description_button(selector, embed_id);

  // add disclaimer link
  add_disclaimer_link(selector);

  // add powered by link
  add_powered_by_link(selector);

  // add weighted footnote
  add_weighted_footnote(selector, weight_name);
}

function build_page_title (json) { // update the page title to include the title of the analysis
  // get current page title
  // first index - dataset/time series title
  // last index - app name
  var title_parts = $("title").data('original').split(" | ");

  $("head title").html(title_parts[0] + " | " +
    (json.results.title.text ? json.results.title.text + " | " + title_parts[title_parts.length-1]
                              : title_parts[title_parts.length-1]));
}

function resizeExploreData (){
  var w = $(window).width(),
    h = $(window).height(),
    footerHeight = 41,
    headerHeight = 51,
    sidebarFilterWidth = 140 + 300,
    explore_data = $(".explore-data"),
    explore_form = explore_data.find("#explore-form");
  $("html").toggleClass("l992", w < 992);
  if(explore_form.length) {
    var tab_content = $(".tab-content");
    explore_data.height(h-headerHeight-$("#subnav-navbar").outerHeight()-footerHeight);
    tab_content.height(h-tab_content.offset().top-footerHeight);
    explore_data.find("#explore-data-content").width(w - sidebarFilterWidth);

  }
}
////////////////////////////////////////////////
$(document).ready(function () {

  // record a chart as a highlight
  $("#tab-chart, #tab-map").on("click", "a.add-highlight", function (e){
    e.preventDefault();
    var link = this;

    $.ajax({
      type: "POST",
      url: $(link).attr("href"),
      data: {embed_id: $(link).data("embed-id"), visual_type: $(link).data("visual-type")},
      dataType: "json"
    }).done(function (success){
      if (success){
        // record embed id
        gon.embed_ids.push($(link).data("embed-id"));

        // show delete button
        $(link).fadeOut(function (){
          delete_highlight_button($(link).parent(), $(link).data("embed-id"), $(link).data("visual-type"));
        });
      }
      // else {
      // }
    });

  });


  // delete a chart as a highlight
  $("#tab-chart, #tab-map").on("click", "a.delete-highlight", function (e){
    e.preventDefault();
    var link = this;
    var text = gon.confirm_text != undefined ? gon.confirm_text : "Are you sure?";

    var answer=confirm(text);
    if(answer){
      $.ajax({
        type: "POST",
        url: $(link).attr("href"),
        data: {embed_id: $(link).data("embed-id"), visual_type: $(link).data("visual-type")},
        dataType: "json"
      }).done(function (success){
        if (success){
          // delete embed id
          gon.embed_ids.splice( $.inArray($(link).data("embed-id"), gon.embed_ids), 1 );

          // show delete button
          $(link).parent().find("a.description-highlight").fadeOut().remove();
          $(link).fadeOut(function (){
            add_highlight_button($(link).parent(), $(link).data("embed-id"), $(link).data("visual-type"));
          });
        }
        // else {

        // }
      });
    }
  });


// share button with slide effect used on dashboard, timeseries and explore page
  if(is_touch) {
    $(".share-box").on("click", function (){ share_toggle(($(this).attr("data-state") == "in" ? "out" : "in"), $(this)); });
  }
  else {
    $(".share-box").hover(function (){
      share_toggle("in", $(this));
    }, function () { share_toggle("out", $(this)); });
  }
// tabs - on li click fire inner a tag
  $(document).on("click", "#explore-data-content.tabs li", function () {
    $(this).find("a").tab("show");
  });

  // show embed chart modal
  $(document).on("click", ".embed-chart", function () {
    var url = $(this).attr("data-href");
    var popup = $("#embed-popup").html();
    var embed_iframe = $("#embed-iframe").html();
    modal(popup,
      {
        position:"center",
        events: [
          {
            event:"change",
            element: ".wide input",
            callback:function ()
            {
              var t = $(this);
              var par = t.closest(".box");
              par.find("textarea").val($(embed_iframe).attr("src", url).attr("width", t.val()).attr("height", par.find(".high input").val()).prop("outerHTML"));
            }
          },
          {
            event:"change",
            element: ".high input",
            callback:function ()
            {
              var t = $(this);
              var par = t.closest(".box");
              par.find("textarea").val($(embed_iframe).attr("src", url).attr("width", t.val()).attr("height", par.find(".high input").val()).prop("outerHTML"));
            }
          }
        ],
        before: function (t)
        {
          t.find("textarea").val($(embed_iframe).attr("src", url).attr("width", t.find(".wide input").val()).attr("height", t.find(".high input").val()).prop("outerHTML"));
        }
      }
    );
  });


  // show highlight description modal
  $(document).on("click", ".highlight-description-chart", function () {
    var text = $(this).attr("data-text").replace(/(?:\r\n|\r|\n)/g, "<br />");
    var popup = $("#highlight-description-popup").html();
    modal(popup, {
      position:"center",
      before: function (t)
      {
        t.find(".text").html(text);
      }
    });
  });


  // show highlight description form
  $(document).on("click", ".description-highlight", function () {
    var url = $(this).attr("data-href");
    var embed_id = $(this).attr("data-embed-id");
    var chart = $(this).closest("div");

    // get the form for this embed id
    $.ajax({
      type: "GET",
      url: url,
      data: {embed_id: embed_id},
      dataType: "json"
    }).done(function (data){
      if (data && data.form != null){
        // got form, create modal popup
        modal($("#description-form-popup").html().replace("{form}", data.form), {
          position:"center",
          events: [
            {
              event:"submit",
              element: "form.highlight",
              callback:function (e)
              {
                e.preventDefault();
                var params = $(this).serialize();
                params += "&embed_id=" + embed_id;
                var desc = $(this).find("textarea:first").val();

                // submit the form and close window
                $.ajax({
                  type: "POST",
                  url: $(this).attr("action"),
                  data: params,
                  dataType: "json"
                }).done(function (data){
                  if (data && data.success == true){
                    // turn off show desc button if exists
                    $(chart).find("div.highlight-description-chart").remove();

                    if (desc != undefined && desc != ""){
                      // show desc button
                      add_highlight_description_button(chart, embed_id);
                    }

                    // close popup
                    js_modal_off();

                    // show success message
                    $("#page-wrapper .content").prepend(notification("success", data.message, "message"));
                    $("#page-wrapper .content > .message").delay(3000).fadeOut(3000);
                  }else{
                    $("#js_modal .popup .header").after(notification("error", data.message));
                  }
                });
              }
            }
          ]
        });
      }
    });
  });



  resizeExploreData();
  $( window ).resize(function () { resizeExploreData(); });
});
function share_toggle (state, t) {
  var at = t.find(".addthis_sharing_toolbox"),
    dir = { },
    dir2 = { }, tmp, tmp2;

  if(state == "in") {
    var atwidth = at.width();

    tmp = "right";
    tmp2 = "left";
    if(at.offset().left < atwidth)
    {
      tmp = "left";
      tmp2 = "right";
    }
    dir[tmp] = atwidth;
    dir2[tmp2] = "initial";
    t.attr("data-dir", tmp);
    t.find(".prompt").css(dir2).animate(dir, 500);
    at.delay( 500 ).animate({"opacity":1}, 100);
  }
  else {

    tmp = t.attr("data-dir");
    tmp2 = tmp == "left" ? "right" : "left";
    dir[tmp] = 0;
    dir2[tmp2] = "initial";
    at.stop().animate({"opacity":0}, 100);
    t.find(".prompt").css(dir2).stop().delay( 100 ).animate(dir, 250);
  }
  t.attr("data-state", state);
}
function rgba (hex) {
  return "rgba(" + hex2rgb(hex).join(",") + ", .4)";
}
function hex2rgb (hex) {
  var r = hex.match(/^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i);
  if (r) {
    return r.slice(1, 4).map(function (x) { return parseInt(x, 16); });
  }
  return [255, 255, 255];
}