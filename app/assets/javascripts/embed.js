/*global  $, gon, Highcharts */
/*eslint no-unused-vars: 0, no-undef: 0  */

/**
* Build chart based on data and type
* @param {object} data - Data to build chart
* @param {string} type - Type of chart to build
*/
function build_charts (data, type) {
  if (data.chart) {
    var chart_height = window[type + "_chart_height"](data),     // determine chart height
      weight_name = data.weighted_by ? data.weighted_by.weight_name : undefined,
      ch = undefined;

    if (data.chart.constructor === Array) { // test if the filter is being used and build the chart(s) accordingly
      var chTmp = data.chart.filter(function (d) { return d.filter_answer_value === gon.filtered_by_value; });
      if(chTmp.length === 1) { ch = chTmp[0]; }
    }
    else { ch = data.chart; } // not filtered chart

    if(ch) {
      if(["crosstab", "scatter"].indexOf(type) !== -1) {
        window["build_" + type + "_chart"]({
          qcode: data.question.original_code,
          qtext: data.question.text,
          bcode: data.broken_down_by.original_code,
          btext: data.broken_down_by.text,
          filtered: data.filtered_by ? true : false },
          ch, chart_height, weight_name);
      }
      else {
        if(type === "histogramm") {
          ch["numerical"] = data.question.numerical;
        }
        window["build_" + type + "_chart"](ch, chart_height, weight_name); // create chart
      }
    }
  }
}

/**
* Build map
* @param {object} data - Data to build map
*/
function build_highmaps (json){ // build highmap
  if (json.map){
    // adjust the height/width of the map to fit its container if this is embed
    if ($("body#embed").length > 0){
      var t = $("#container-map");
      t.width($(document).width());
      t.height($(document).height());
    }

    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined, i;

    // test if the filter is being used and build the chart(s) accordingly
    if(json.map.constructor === Array) { // filters
      var map_index = 0,
        stop_loop = false;
      for(var h=0; h<json.map.length; h++){
        if (json.broken_down_by && json.map[h].filter_results.map_sets.constructor === Array){
          for(i=0; i<json.map[h].filter_results.map_sets.length; i++){
            if (json.map[h].filter_answer_value == gon.filtered_by_value && json.map[i].broken_down_answer_value == gon.broken_down_by_value) { // create map for filter that matches gon.broken_down_by_value and broken down by that matches gon.broken_down_by_value
              build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.map_sets[i], weight_name);
              stop_loop = true;
              break;
            }
            map_index += 1; // increase the map index
          }
          if (stop_loop === true){ break; }
        }else{

          if (json.map[i].filter_answer_value == gon.filtered_by_value){ // create map for filter that matches gon.filtered_by_value
            build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.map_sets, weight_name);
            break;
          }
          map_index += 1; // increase the map index
        }
      }
    }
    else { // no filters
      if (json.broken_down_by && json.map.map_sets.constructor === Array){
        for(i=0; i<json.map.map_sets.length; i++){
          if (json.map.map_sets[i].broken_down_answer_value == gon.broken_down_by_value){ // create map for broken down by that matches gon.broken_down_by_value
            build_highmap(json.map.shape_question_code, json.map.map_sets[i], weight_name);
            break;
          }
        }
      }else{
        build_highmap(json.map.shape_question_code, json.map.map_sets, weight_name);
      }
    }
  }
}

/**
* Building all highlights(chart, map) based on type
* @param {object} highlight_data - Data about all highlights
*/
function load_highlights (highlight_data){
  if(!highlight_data){ return; }

  Highcharts.setOptions({
    chart: { spacingRight: 30 },
    lang: {
      contextButtonTitle: gon.highcharts_context_title,
      thousandsSep: ','
    },
    colors: ["#C6CA53", "#7DAA92", "#725752", "#E29A27", "#998746", "#A6D3A0", "#808782", "#B4656F", "#294739", "#1B998B", "#7DAA92", "#BE6E46", "#565264"]
  });

  var data,
    type;

  Object.keys(highlight_data).forEach(function (key){ // build chart for each key
    data = highlight_data[key];
    if (data.json_data){
      gon.highlight_id = key;
      // set fitler_value and broken_down_by_value if exists
      if (data.broken_down_by_value) { gon.broken_down_by_value = data.broken_down_by_value; }
      if (data.filtered_by_value){ gon.filtered_by_value = data.filtered_by_value; }

      type = null;

      if (data.json_data.time_series) { type = "time_series"; } // test if time series or dataset
      else if(data.json_data.dataset) {
        Object.keys(gon.visual_types).forEach(function (d) {
          if(gon.visual_types[d] == data.visual_type) {
            type = d;
          }
        });
      }
      
      if(type === "map") { build_highmaps(data.json_data); }
      else { build_charts(data.json_data, type); }

      if (gon.update_page_title){ build_page_title(data.json_data); }
    }
  });
}
function is_touch_device () {
  return (("ontouchstart" in window)
      || (navigator.MaxTouchPoints > 0)
      || (navigator.msMaxTouchPoints > 0));
}
var is_touch = is_touch_device();



/**
* Script Initialization
*/
$(document).ready(function () { load_highlights(gon.highlight_data); });