/*global  $, gon, Highcharts */
/*eslint no-unused-vars: 0, no-undef: 0  */

var is_touch=null;

////////////////////////////////////////////////
// build highmap
function build_highmaps (json){
  if (json.map){
    // adjust the height/width of the map to fit its container if this is embed
    if ($("body#embed").length > 0){
      $("#container-map").width($(document).width());
      $("#container-map").height($(document).height());
    }

    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined, i;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.map.constructor === Array){
      // filters
      var map_index = 0,
        stop_loop = false;
      for(var h=0; h<json.map.length; h++){
        if (json.broken_down_by && json.map[h].filter_results.map_sets.constructor === Array){

          for(i=0; i<json.map[h].filter_results.map_sets.length; i++){
            // create map for filter that matches gon.broken_down_by_value and broken down by that matches gon.broken_down_by_value
            if (json.map[h].filter_answer_value == gon.filtered_by_value && json.map[i].broken_down_answer_value == gon.broken_down_by_value){
              build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.map_sets[i], weight_name);
              stop_loop = true;
              break;
            }

            // increase the map index
            map_index += 1;
          }

          if (stop_loop === true){
            break;
          }
        }else{

          // create map for filter that matches gon.filtered_by_value
          if (json.map[i].filter_answer_value == gon.filtered_by_value){
            build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.map_sets, weight_name);
            break;
          }

          // increase the map index
          map_index += 1;
        }
      }

    }
    else{

      // no filters
      if (json.broken_down_by && json.map.map_sets.constructor === Array){

        for(i=0; i<json.map.map_sets.length; i++){
          // create map for broken down by that matches gon.broken_down_by_value
          if (json.map.map_sets[i].broken_down_answer_value == gon.broken_down_by_value){
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


////////////////////////////////////////////////
// build crosstab charts for each chart item in json
function build_crosstab_charts (json){
  if (json.chart){
    // determine chart height
    var chart_height = crosstab_chart_height(json);
    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart for filter that matches gon.filtered_by_value
        if (json.chart[i].filter_answer_value == gon.filtered_by_value){
          build_crosstab_chart(json.question.original_code, json.broken_down_by.original_code, json.broken_down_by.text, json.chart[i].filter_results, chart_height, weight_name);
          break;
        }
      }

    }else{
      // no filters
      build_crosstab_chart(json.question.original_code, json.broken_down_by.original_code, json.broken_down_by.text, json.chart, chart_height, weight_name);
    }
  }
}


////////////////////////////////////////////////
// build pie chart for each chart item in json
function build_pie_charts (json){
  if (json.chart){
    // determine chart height
    var chart_height = pie_chart_height(json);
    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart for filter that matches gon.filtered_by_value
        if (json.chart[i].filter_answer_value == gon.filtered_by_value){
          build_pie_chart(json.chart[i].filter_results, chart_height, weight_name);
          break;
        }
      }

    }else{
      // no filters
      build_pie_chart(json.chart, chart_height, weight_name);
    }
  }
}

////////////////////////////////////////////////
// build pie chart for each chart item in json
function build_bar_charts (json){
  if (json.chart){
    // determine chart height
    var chart_height = pie_chart_height(json);
    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart for filter that matches gon.filtered_by_value
        if (json.chart[i].filter_answer_value == gon.filtered_by_value){
          build_bar_chart(json.chart[i].filter_results, chart_height, weight_name);
          break;
        }
      }

    }else{
      // no filters
      build_bar_chart(json.chart, chart_height, weight_name);
    }
  }
}

////////////////////////////////////////////////
// build time series line chart for each chart item in json
function build_time_series_charts (json){
  if (json.chart){
    // determine chart height
    var chart_height = time_series_chart_height(json);
    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart for filter that matches gon.filtered_by_value
        if (json.chart[i].filter_answer_value == gon.filtered_by_value){
          build_time_series_chart(json.chart[i].filter_results, chart_height, weight_name);
          break;
        }
      }

    }else{
      // no filters
      build_time_series_chart(json.chart, chart_height, weight_name);
    }
  }
}

function load_highlights (highlight_data){

  var data, key, keys = [];
  $.each(highlight_data, function (k, v){ keys.push(k); });  // pull out all of the keys
 //console.log(keys);
  // build chart for each key
  for(var i=0;i<keys.length;i++){
    key = keys[i];
     // console.log(key);
    data = highlight_data[key];
    if (data.json_data){
      gon.highlight_id = key;

      // set fitler_value and broken_down_by_value if exists
      if (data.broken_down_by_value){
        gon.broken_down_by_value = data.broken_down_by_value;
      }
      if (data.filtered_by_value){
        gon.filtered_by_value = data.filtered_by_value;
      }

    // test if time series or dataset
      if (data.json_data.time_series){
        build_time_series_charts(data.json_data);
      }else if(data.json_data.dataset){
        // test for visual type
        if (data.visual_type == "chart"){
          if (data.json_data.analysis_type == "comparative"){
            build_crosstab_charts(data.json_data);
          }else{
            data.chart_type == "pie" ? build_pie_charts(data.json_data) : build_bar_charts(data.json_data);
          }
        }else if (data.visual_type == "map") {
          build_highmaps(data.json_data);
        }
      }


      if (gon.update_page_title){
        build_page_title(data.json_data);
      }
    }
  }
}

/////////////////////////////////////////
/////////////////////////////////////////
$(document).ready(function () {
  // set languaage text
  Highcharts.setOptions({
    chart: { spacingRight: 30 },
    lang: {
      contextButtonTitle: gon.highcharts_context_title
    },
    colors: ["#C6CA53", "#7DAA92", "#725752", "#E29A27", "#998746", "#A6D3A0", "#808782", "#B4656F", "#294739", "#1B998B", "#7DAA92", "#BE6E46", "#565264"]
  });
  if(gon.highlight_data){ load_highlights(gon.highlight_data); }

});