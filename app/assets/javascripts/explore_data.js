/*global  $, gon, Highcharts, params */
/*eslint camelcase: 0, no-underscore-dangle: 0, no-unused-vars: 0, no-undef: 0*/
var js = {
  cache: {}
};
var datatables, h, i, j, k, cacheId;

function update_available_weights () { // update the list of avilable weights based on questions that are selected
  // update weight list if weights exist
  if ($("select#weighted_by_code").length > 0){
    var items = [
      $("select#question_code option:selected").data("weights"),
      $("select#broken_down_by_code option:selected").data("weights"),
      $("select#filtered_by_code option:selected").data("weights")
    ];
    // remove undefined (undefined exists if a select does not have a value)
    var und_ind = items.indexOf(undefined);
    while(und_ind != -1){
      if (und_ind != -1){
        items.splice(und_ind, 1);
      }
      und_ind = items.indexOf(undefined);
    }
    var matches = items.shift().filter(function (v) {
      return items.every(function (a) {
        return a.indexOf(v) !== -1;
      });
    });

    // if there are matches, show the weights that match, and unweighted
    // else hide weight option and set value to unweighted
    if (matches.length > 0){
      // show matches, hide rest

      // hide all items
      $(".form-explore-weight-by .bootstrap-select ul.dropdown-menu li").hide();

      // show matched weights
      var match_length = matches.length;
      var i=0;
      var index;
      for (i;i<match_length;i++){
        index = $("select#weighted_by_code option[value='" + matches[i] + "']").index();
        if (index != -1){
          $(".form-explore-weight-by .bootstrap-select ul.dropdown-menu li:eq(" + index + ")").show();
        }
      }
      // show unweighted
      $(".form-explore-weight-by .bootstrap-select ul.dropdown-menu li:last").show();

      $(".form-weight-by").show();
    }else{
      $(".form-weight-by").hide();
      $("select#weighted_by_code").selectpicker("val", "unweighted");
    }
  }
}

function set_can_exclude_visibility () { // show or hide the can exclude checkbox
  $("div#can-exclude-container").css("visibility",
    ($("select#question_code option:selected").data("can-exclude") == true ||
    $("select#broken_down_by_code option:selected").data("can-exclude") == true ||
    $("select#filtered_by_code option:selected").data("can-exclude") == true) ? "visible" : "hidden");
}

function build_highmaps (json) { // build highmap
  var i;
  if (json.map){
    // adjust the width of the map to fit its container
    // $("#container-map").width($("#explore-tabs").width());

    // determine chart height
    var chart_height = map_chart_height(json);

    // remove all existing maps
    $("#container-map").empty();
    // remove all existing map links
    $("#jumpto #jumpto-map select").empty();
    $("#jumpto #jumpto-map h4").empty().hide();
    var template = $("#jumpto #jumpto-map .jumpto-map-item").clone();
    // remove any existing fancy select list
    $(template).find("div.bootstrap-select").remove();
    // remove all extra jumpto map items
    if ($("#jumpto #jumpto-map .jumpto-map-item").length > 1){
      for (i=$("#jumpto #jumpto-map .jumpto-map-item").length; i>0; i--){
        $("#jumpto #jumpto-map .jumpto-map-item").splice(i-1, 1);
      }
    }

    var jumpto_text = "";
    var non_map_text;
    if (json.broken_down_by){
      non_map_text = json.broken_down_by.text;
      if (json.broken_down_by.is_mappable == true){
        non_map_text = json.question.text;
      }
    }

    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.map.constructor === Array){
      // filters
      var map_index = 0;
      var jump_ary = [];
      var jump_item;

      for(h=0; h<json.map.length; h++){
        if (json.broken_down_by && json.map[h].filter_results.map_sets.constructor === Array){
          // add jumpto link
          jump_item = $(template).clone();
          $(jump_item).find("h4").html(json.filtered_by.text + " = <span>" + json.map[h].filter_answer_text + "</span>");
          jumpto_text = "<option></option>";

          for(i=0; i<json.map[h].filter_results.map_sets.length; i++){
            build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.adjustable_max_range, json.map[h].filter_results.map_sets[i], chart_height, weight_name);

            // add jumpto link
            jumpto_text += "<option data-href='#map-" + (map_index+1) + "'>" + non_map_text + " = " + json.map[h].filter_results.map_sets[i].broken_down_answer_text + "</option>";

            // increase the map index
            map_index += 1;
          }

          $(jump_item).find("select").append(jumpto_text);
          jump_ary.push(jump_item);

        }else{
          build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.adjustable_max_range, json.map[h].filter_results.map_sets, chart_height, weight_name);

          // add jumpto link
          jumpto_text += "<option data-href='#map-" + (map_index+1) + "'>" + json.filtered_by.text + " = " + json.map[h].filter_answer_text + "</option>";

          // increase the map index
          map_index += 1;
        }
      }

      // show jumpto
      // - if jump_ary exists (filter and broken down), add a drop down for each filter value
      if (jump_ary != undefined && jump_ary.length > 0){
        // remove the existing template
        $("#jumpto #jumpto-map .jumpto-map-item").remove();
        for (i=0; i<jump_ary.length; i++){
          $("#jumpto #jumpto-map").append(jump_ary[i]);

          var select = $("#jumpto #jumpto-map select:last");
          if (i == 0) {
            $(select).find("option:eq(1)").prop("selected", true);
          }
          $(select).selectpicker();
        }
        $("#jumpto #jumpto-map h4").show();
        $("#jumpto #jumpto-map").show();
        $("#jumpto").show();
      }else{
        $("#jumpto #jumpto-map select").append(jumpto_text);
        $("#jumpto #jumpto-map select").val($("#jumpto #jumpto-map select option:first").attr("value"));
        $("#jumpto #jumpto-map select").selectpicker("refresh");
        $("#jumpto #jumpto-map select").selectpicker("render");
        $("#jumpto #jumpto-map").show();
        $("#jumpto").show();
      }

    }else{

      // no filters
      if (json.broken_down_by && json.map.map_sets.constructor === Array){
        for(i=0; i<json.map.map_sets.length; i++){
          build_highmap(json.map.shape_question_code, json.map.adjustable_max_range, json.map.map_sets[i], chart_height, weight_name);

          // add jumpto link
          jumpto_text += "<option data-href='#map-" + (i+1) + "'>" + non_map_text + " = " + json.map.map_sets[i].broken_down_answer_text + "</option>";
        }

        // show jumpto
        $("#jumpto #jumpto-map select").append(jumpto_text);
        $("#jumpto #jumpto-map select").val($("#jumpto #jumpto-map select option:first").attr("value"));
        $("#jumpto #jumpto-map select").selectpicker("refresh");
        $("#jumpto #jumpto-map select").selectpicker("render");
        $("#jumpto #jumpto-map").show();
        $("#jumpto").show();

      }else{
        build_highmap(json.map.shape_question_code, json.map.adjustable_max_range, json.map.map_sets, chart_height, weight_name);

        // hide jumpto
        $("#jumpto #jumpto-map").hide();
        $("#jumpto").hide();
      }
    }

    // show map tabs
    $("#explore-tabs #nav-map").show();

  }
  else{
    // no map so hide tab
    $("#explore-tabs #nav-map").hide();
    // make sure these are not active
    $("#explore-tabs #nav-map, #explore-content #tab-map").removeClass("active");
  }
}

function build_crosstab_charts (json) { // build crosstab charts for each chart item in json
  var i;
  if (json.chart){
    // determine chart height
    var chart_height = crosstab_chart_height(json);

    // remove all existing charts
    $("#container-chart").empty();
    // remove all existing chart links
    $("#jumpto #jumpto-chart select").empty();
    var jumpto_text = "";
    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(i=0; i<json.chart.length; i++){
        // create chart
        build_crosstab_chart(json.question.original_code, json.broken_down_by.original_code, json.broken_down_by.text, json.chart[i].filter_results, chart_height, weight_name);

        // add jumpto link
        jumpto_text += "<option data-href='#chart-" + (i+1) + "'>" + json.filtered_by.text + " = " + json.chart[i].filter_answer_text + "</option>";
      }

      // show jumpto links
      $("#jumpto #jumpto-chart select").append(jumpto_text);
      $("#jumpto #jumpto-chart select").val($("#jumpto #jumpto-chart select option:first").attr("value"));
      $("#jumpto #jumpto-chart select").selectpicker("refresh");
      $("#jumpto #jumpto-chart select").selectpicker("render");
      $("#jumpto #jumpto-chart").show();
      $("#jumpto").show();

    }else{
      // no filters
      build_crosstab_chart(json.question.original_code, json.broken_down_by.original_code, json.broken_down_by.text, json.chart, chart_height, weight_name);

      // hide jumpto
      $("#jumpto #jumpt-chart").hide();
      $("#jumpto").hide();
    }
  }
}

function build_pie_charts (json) { // build pie chart for each chart item in json
  if (json.chart){
    // determine chart height
    var chart_height = pie_chart_height(json);

    // remove all existing charts
    var container = $("#container-chart");
    container.empty();
    container.append("<div id='chart-type-toggle'><div class='toggle' data-type='bar'></div><div class='toggle selected' data-type='pie'></div>");
    // remove all existing chart links
    $("#jumpto #jumpto-chart select").empty();
    var jumpto_text = "";
    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(i=0; i<json.chart.length; i++){
        // create chart
        build_pie_chart(json.chart[i].filter_results, chart_height, weight_name);

        // add jumpto link
        jumpto_text += "<option data-href='#chart-" + (i+1) + "'>" + json.filtered_by.text + " = " + json.chart[i].filter_answer_text + "</option>";
      }

      // show jumpto links
      $("#jumpto #jumpto-chart select").append(jumpto_text);
      $("#jumpto #jumpto-chart select").val($("#jumpto #jumpto-chart select option:first").attr("value"));
      $("#jumpto #jumpto-chart select").selectpicker("refresh");
      $("#jumpto #jumpto-chart select").selectpicker("render");
      $("#jumpto #jumpto-chart").show();
      $("#jumpto").show();

    }else{
      // no filters
      build_pie_chart(json.chart, chart_height, weight_name);

      // hide jumpto
      $("#jumpto #jumpto-chart").hide();
      $("#jumpto").hide();
    }
  }
}

function build_bar_charts (json) { // build pie chart for each chart item in json
  var flag = false;

  if (json.chart){
    flag = true;

    var chart_height = pie_chart_height(json), // determine chart height
      container = $("#container-chart");

    container.empty();
    container.append("<div id='chart-type-toggle'><div class='toggle selected' data-type='bar'></div><div class='toggle' data-type='pie'></div>");
    // remove all existing chart links
    var select_selector = $("#jumpto #jumpto-chart select");
    select_selector.empty();

    var jumpto_text = "";
    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(i=0; i<json.chart.length; i++){
        // create chart
        build_bar_chart(json.chart[i].filter_results, chart_height, weight_name);

        // add jumpto link
        jumpto_text += "<option data-href='#chart-" + (i+1) + "'>" + json.filtered_by.text + " = " + json.chart[i].filter_answer_text + "</option>";
      }

      // show jumpto links    
      select_selector.append(jumpto_text);
      select_selector.val(select_selector.find("option:first").attr("value"));
      select_selector.selectpicker("refresh");
      select_selector.selectpicker("render");
    }
    else {
      build_bar_chart(json.chart, chart_height, weight_name);       // no filters
    }

    // show/hide jumpto
    $("#jumpto #jumpto-chart").toggle(flag);
    $("#jumpto").toggle(flag);
  }
}

function build_datatable (json) { // build data table
  var ln;
  // set the title
  $("#container-table h3").html(json.results.title.html + json.results.subtitle.html);

  // if the datatable alread exists, kill it
  if (datatables != undefined && datatables.length > 0){
    for (i=0;i<datatables.length;i++){
      datatables[i].fnDestroy();
    }
  }

  var col_headers = ["count", "percent"];

  // test if data is weighted so can build table accordingly
  var is_weighted = json.weighted_by != undefined;
  if (is_weighted){
    col_headers = ["unweighted-count", "weighted-count", "weighted-percent"];
  }
  var col_header_count = col_headers.length;

  // build the table
  var table = "";

  // build head
  table += "<thead>";

  // test if the filter is being used and build the table accordingly
  if (json.filtered_by == undefined){
    if (json.analysis_type == "comparative"){
      // 3 headers of:
      //                broken_down_by question
      //                broken_down_by answers .....

      // question code question   count percent count percent .....
      table += "<tr class='th-center'>";
      table += "<th class='var1-col-red'>" + gon.table_questions_header + "</th>";
      table += "<th class='code-highlight' colspan='" + (col_header_count*(json.broken_down_by.answers.length+1)).toString() + "'>";
      table += json.broken_down_by.original_code;
      table += "</th>";
      table += "</tr>";

      table += "<tr class='th-center'>";
      table += "<th class='var1-col code-highlight' rowspan='2'>";
      table += json.question.original_code;
      table += "</th>";
      ln = json.broken_down_by.answers.length;
      for(i=0; i<ln;i++){
        table += "<th colspan='" + col_header_count + "' class='color"+(i % 13 + 1)+"'>";
        table += json.broken_down_by.answers[i].text.toString();
        table += "</th>";
      }
      table += "</tr>";

      table += "<tr>";
      // table += "<th class='var1-col code-highlight'>";
      // table += json.question.original_code;
      // table += "</th>";
      for(i=0; i<ln;i++){
        for(j=0; j<col_header_count;j++){
          table += "<th>";
          table += $("#container-table table").data(col_headers[j]);
          table += "</th>";
        }
      }
      table += "</tr>";
    }else{
      // 1 header of: question code question, count, percent
      table += "<tr class='th-center'>";
      table += "<th class='var1-col code-highlight'>";
      table += json.question.original_code;
      table += "</th>";
      for(j=0; j<col_header_count;j++){
        table += "<th>";
        table += $("#container-table table").data(col_headers[j]);
        table += "</th>";
      }
      table += "</tr>";
    }
  }else{
    if (json.analysis_type == "comparative"){
      // 3 headers of:
      //                broken_down_by question
      //                broken_down_by answers .....

      // filter question   count percent count percent .....
      table += "<tr class='th-center'>";
      table += "<th class='var1-col-red' colspan='2'>" + gon.table_questions_header + "</th>";
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

      ln = json.broken_down_by.answers.length;
      for(i=0; i<ln;i++) {
        table += "<th colspan='" + col_header_count + "' class='color"+(i % 13 + 1)+"'>";
        table += json.broken_down_by.answers[i].text.toString();
        table += "</th>";
      }
      table += "</tr>";

      table += "<tr>";
      for(i=0; i<ln;i++){
        for(j=0; j<col_header_count;j++){
          table += "<th>";
          table += $("#container-table table").data(col_headers[j]);
          table += "</th>";
        }
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
      table += "</th>";
      for(j=0; j<col_header_count;j++){
        table += "<th>";
        table += $("#container-table table").data(col_headers[j]);
        table += "</th>";
      }
      table += "</tr>";
    }
  }
  table += "</thead>";


  // build body
  table += "<tbody>";
  var key_text;
  if (json.filtered_by == undefined){
    if (json.analysis_type == "comparative"){
      // cells per row: question code answer, count/percent for each col
      for(i=0; i<json.results.analysis.length; i++){
        table += "<tr>";
        table += "<td class='var1-col' data-order='" + json.question.answers[i].sort_order + "'>";
        table += json.results.analysis[i].answer_text;
        table += "</td>";
        for(j=0; j<json.results.analysis[i].broken_down_results.length; j++){
          for(k=0; k<col_header_count;k++){
            // key is written with "-" but for this part, it must be "_"
            key_text = col_headers[k].replace("-", "_");
            // percent is the last item and all items before are percent
            if (k < col_header_count-1){
              table += "<td data-order='" + json.results.analysis[i].broken_down_results[j][key_text] + "'>";
              table += Highcharts.numberFormat(json.results.analysis[i].broken_down_results[j][key_text], 0);
              table += "</td>";
            }else{
              table += "<td>";
              if (json.results.analysis[i].broken_down_results[j][key_text]){
                table += json.results.analysis[i].broken_down_results[j][key_text].toFixed(2);
              }else{
                table += "0";
              }
              table += "%";
              table += "</td>";
            }
          }
        }
        table += "</tr>";
      }

    }else{

      // cells per row: question code answer, count, percent
      for(i=0; i<json.results.analysis.length; i++){
        table += "<tr>";
        table += "<td class='var1-col' data-order='" + json.question.answers[i].sort_order + "'>";
        table += json.results.analysis[i].answer_text;
        table += "</td>";
        for(k=0; k<col_header_count;k++){
          // key is written with "-" but for this part, it must be "_"
          key_text = col_headers[k].replace("-", "_");
          // percent is the last item and all items before are percent
          if (k < col_header_count-1){
            table += "<td data-order='" + json.results.analysis[i][key_text] + "'>";
            table += Highcharts.numberFormat(json.results.analysis[i][key_text], 0);
            table += "</td>";
          }else{
            table += "<td>";
            if (json.results.analysis[i][key_text]){
              table += json.results.analysis[i][key_text].toFixed(2);
            }else{
              table += "0";
            }
            table += "%";
            table += "</td>";
          }
        }
        table += "</tr>";
      }
    }

  }else{

    if (json.analysis_type == "comparative"){
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
            for(k=0; k<col_header_count;k++){
              // key is written with "-" but for this part, it must be "_"
              key_text = col_headers[k].replace("-", "_");
              // percent is the last item and all items before are percent
              if (k < col_header_count-1){
                table += "<td data-order='" + json.results.filter_analysis[h].filter_results.analysis[i].broken_down_results[j][key_text] + "'>";
                table += Highcharts.numberFormat(json.results.filter_analysis[h].filter_results.analysis[i].broken_down_results[j][key_text], 0);
                table += "</td>";
              }else{
                table += "<td>";
                if (json.results.filter_analysis[h].filter_results.analysis[i].broken_down_results[j][key_text]){
                  table += json.results.filter_analysis[h].filter_results.analysis[i].broken_down_results[j][key_text].toFixed(2);
                }else{
                  table += "0";
                }
                table += "%";
                table += "</td>";
              }
            }
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
          for(k=0; k<col_header_count;k++){
            // key is written with "-" but for this part, it must be "_"
            key_text = col_headers[k].replace("-", "_");
            // percent is the last item and all items before are percent
            if (k < col_header_count-1){
              table += "<td data-order='" + json.results.filter_analysis[h].filter_results.analysis[i][key_text] + "'>";
              table += Highcharts.numberFormat(json.results.filter_analysis[h].filter_results.analysis[i][key_text], 0);
              table += "</td>";
            }else{
              table += "<td>";
              if (json.results.filter_analysis[h].filter_results.analysis[i][key_text]){
                table += json.results.filter_analysis[h].filter_results.analysis[i][key_text].toFixed(2);
              }else{
                table += "0";
              }
              table += "%";
              table += "</td>";
            }
          }
          table += "</tr>";
        }
      }
    }
  }

  table += "</tbody>";

  $("#container-table table").html(table);

  // initalize the datatable
  datatables = [];
  $("#container-table table").each(function () {
    datatables.push($(this).dataTable({
      "dom": "<'top'fl>t<'bottom'p><'clear'>",
      "language": {
        "url": gon.datatable_i18n_url,
        "searchPlaceholder": gon.datatable_search
      },
      "pagingType": "full_numbers",
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
    }));
  });

  // if data is weighted, show footnote
  if (json.weighted_by){
    $("#tab-table .table-weighted-footnote .footnote-weight-name").html(json.weighted_by.weight_name);
    $("#tab-table .table-weighted-footnote").show();
  }else{
    $("#tab-table .table-weighted-footnote .footnote-weight-name").empty();
    $("#tab-table .table-weighted-footnote").hide();
  }
}

function build_details_item (selector, json_question) { // populat a details item block
  if (json_question && json_question.text){
    var tmp = $(selector);
    if (tmp.length > 0){
      var icon = "";
      if (json_question.exclude){
        icon += $(".details-icons #detail-icon-exclude-question")[0].outerHTML;
      }
      if (json_question.is_mappable){
        icon += $(".details-icons #detail-icon-mappable-question")[0].outerHTML;
      }
      tmp.find(".name-variable").html(icon + json_question.text);

      tmp.find(".name-code").html(json_question.original_code);
      if (json_question.notes){
        tmp.find(".notes").html(json_question.notes);
        tmp.find(".details-notes").show();
      }else{
        tmp.find(".details-notes").hide();
      }
      if (json_question.weight_name){
        tmp.find(".weight").html(json_question.weight_name);
        tmp.find(".details-weight").show();
      }else{
        tmp.find(".details-weight").hide();
      }
      if (json_question.group){
        tmp.find(".name-group .group-title").html(json_question.group.title);
        if (json_question.group.description != ""){
          tmp.find(".name-group .group-description").html(" - " + json_question.group.description);
        }
        tmp.find(".details-group").show();
      }else{
        tmp.find(".details-group").hide();
      }
      if (json_question.subgroup){
        tmp.find(".name-subgroup .group-title").html(json_question.subgroup.title);
        if (json_question.subgroup.description != ""){
          tmp.find(".name-subgroup .group-description").html(" - " + json_question.subgroup.description);
        }
        tmp.find(".details-subgroup").show();
      }else{
        tmp.find(".details-subgroup").hide();
      }
      if (json_question.answers){
        for(var i=0;i<json_question.answers.length;i++){
          icon = "";
          if (json_question.answers[i].exclude){
            icon += $(".details-icons #detail-icon-exclude-answer")[0].outerHTML;
          }
          tmp.find(".list-answers").append("<li>" + icon + json_question.answers[i].text + "</li>");
        }
        tmp.find(".details-answers").show();
      }else{
        tmp.find(".details-answers").hide();
      }
      tmp.show();
    }
  }
}

function build_details (json) { // build details (question and possible answers)
  // clear out existing content and hide
  var details_item = $("#tab-details .details-item").hide();
  details_item.find(".name-group .group-title, .name-group .group-description, .name-subgroup .group-title, .name-subgroup .group-description, .name-variable, .name-code, .notes, .list-answers").empty();

  // add questions
  build_details_item("#tab-details #details-question-code", json.question);

  // add broken down by
  build_details_item("#tab-details #details-broken-down-by-code", json.broken_down_by);

  // add filters
  build_details_item("#tab-details #details-filtered-by-code", json.filtered_by);

  // add weight
  build_details_item("#tab-details #details-weighted-by-code", json.weighted_by);
}

function build_explore_data_page (json) { // build the visualizations for the explore data page
  if (json.analysis_type == "comparative"){
    build_crosstab_charts(json);
  }
  else {
    (typeof params.chart_type !== "undefined" && params.chart_type === "pie")
      ? build_pie_charts(json)
      : build_bar_charts(json);
  }
  build_highmaps(json);
  build_datatable(json);
  build_details(json);

  build_page_title(json);

  // if no visible tab is marked as active, mark the first one active
  var explore_tabs = $("#explore-tabs");

  // turn on tab and its content || make sure correct jumptos are showing
  $("#explore-tabs li" +
      (explore_tabs.find("li.active:visible").length == 0
        ? ":visible:first"
        : "li.active" )).trigger("click");
}

function get_explore_data (is_back_button) { // get data and load page
  is_back_button = (typeof is_back_button === "undefined" ? false : is_back_button);

  var v,
    ajax_data = {
      dataset_id: gon.dataset_id,
      access_token: gon.app_api_key,
      with_title: true,
      with_chart_data: true,
      with_map_data: true
    },
    url_querystring = []; // build querystring for url and ajax call

  params = queryStringToJSON(window.location.href);

  if (is_back_button && params != undefined){
    $.map(params, function (v, k) { // add each param that was in the url
      ajax_data[k] = v;
      url_querystring.push(k + "=" + v);
    });
  }
  else {

    ["question_code", "broken_down_by_code", "filtered_by_code", "weighted_by_code"].forEach(function (d){
      v = $("select#" + d).val();
      if (v !== null && v !== ""){
        ajax_data[d] = v;
        url_querystring.push(d + "=" + v);
      }
    });

    // can exclude
    if ($("input#can_exclude").is(":checked")){
      ajax_data.can_exclude = true;
      url_querystring.push("can_exclude=" + ajax_data.can_exclude);
    }

    // add language param from url query string, if it exists
    if (typeof params.language !== "undefined"){
      ajax_data.language = params.language;
      url_querystring.push("language=" + ajax_data.language);
    }

    // private pages require user id
    if (typeof gon.private_user !== "undefined"){
      ajax_data.private_user_id = gon.private_user;
    }
  }

  cacheId = "";
  for(tmp in ajax_data) {
    if(["access_token", "with_title", "with_chart_data", "with_map_data"].indexOf(tmp) === -1) {
      cacheId += ajax_data[tmp] + ";";
    }
  }

  if(js.cache.hasOwnProperty(cacheId)) {
    update_content();
  }
  else {
    $.ajax({
      type: "GET",
      url: gon.api_dataset_analysis_path,
      data: ajax_data,
      dataType: "json"
    })
    .error(function ( jqXHR, textStatus, errorThrown ) {
      //console.log( "Request failed: " + textStatus  + ". Error thrown: " + errorThrown);
    })
    .success(function ( json ) {
      if (json.errors || ((json.results.analysis && json.results.analysis.length == 0) || json.results.filtered_analysis && json.results.filtered_analysis.length == 0)){
        $("#jumpto-loader").fadeOut("slow");
        $("#explore-data-loader").fadeOut("slow");
        $("#explore-error").fadeIn("slow");
      }
      else {
        js.cache[cacheId] = json;
        update_content();
      }

    });
  }

  function update_content () {
    var json = js.cache[cacheId];
    build_explore_data_page(json);
    resizeExploreData();
    // update url
    if (typeof params.chart_type !== "undefined" && (["bar", "pie"].indexOf(params.chart_type) !== -1)) {
      url_querystring.push("chart_type=" + params.chart_type);
    }
    var new_url = [location.protocol, "//", location.host, location.pathname, "?", url_querystring.join("&")].join("");

    // change the browser URL to the given link location
    if (!is_back_button && new_url != window.location.href){
      window.history.pushState({path:new_url}, $("title").html(), new_url);
    }
    $("#explore-data-loader").fadeOut("slow");
    $("#jumpto-loader").fadeOut("slow");
  }
}

function reset_filter_form () { // reset the filter forms and select a random variable for the row
  $("select#broken_down_by_code, select#filtered_by_code").val("").selectpicker("refresh");
  $("input#can_exclude").removeAttr("checked");
  $("#btn-swap-vars").hide();
}

$(document).ready(function () {
  // set languaage text
  Highcharts.setOptions({
    chart: { spacingRight: 30 },
    lang: {
      contextButtonTitle: gon.highcharts_context_title
    },
    colors: ["#C6CA53", "#7DAA92", "#725752", "#E29A27", "#998746", "#A6D3A0", "#808782", "#B4656F", "#294739", "#1B998B", "#7DAA92", "#BE6E46", "#565264"]
  });


  if (gon.explore_data){
    // due to using tabs, the map, chart and table cannot be properly drawn
    // because they may be hidden.
    // this event catches when a tab is being shown to make sure
    // the item is properly drawn
    $("a[data-toggle='tab']").on("shown.bs.tab", function (e) {
      switch($(this).attr("href")){
      case "#tab-map":
        $("#container-map .map").each(function () {
          $(this).highcharts().reflow();
          // this is a hack until can figure out why charts are sometimes cut-off
          $(this).find(".highcharts-container").width($("#container-map").width()-1);
        });
        break;
      case "#tab-chart":
        $("#container-chart .chart").each(function () {
          $(this).highcharts().reflow();
          // this is a hack until can figure out why charts are sometimes cut-off
          $(this).find(".highcharts-container").width($("#container-chart").width()-1);
        });
        break;
      case "#tab-table":
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
    $("form#form-explore-data").submit(function () {
      $("#jumpto-loader").fadeIn("slow");
      $("#explore-error").fadeOut("slow");
      $("#explore-no-results").fadeOut("slow");
      $("#explore-data-loader").fadeIn("slow", function () {
        get_explore_data();
      });
      return false;
    });

    // reset the form fields
    $("form#form-explore-data input#btn-reset").click(function (e){
      e.preventDefault();
      $("#jumpto-loader").fadeIn("slow");
      $("#explore-error").fadeOut("slow");
      $("#explore-no-results").fadeOut("slow");
      $("#explore-data-loader").fadeIn("slow", function () {
        reset_filter_form();
        get_explore_data();
      });

    });


    // initalize the fancy select boxes
    $("select.selectpicker").selectpicker();
    $("select.selectpicker-filter").selectpicker();
    $("select.selectpicker-weight").selectpicker();

    // if an option has data-disabled when page loads, make sure it is hidden in the selectpicker
    $("select#question_code option[data-disabled='disabled']").each(function () {
      $(".form-explore-question-code .bootstrap-select ul.dropdown-menu li:eq(" + $(this).index() + ")").hide();
    });
    $("select#broken_down_by_code option[data-disabled='disabled']").each(function () {
      $(".form-explore-broken-by .bootstrap-select ul.dropdown-menu li:eq(" + $(this).index() + ")").hide();
    });
    $("select#filtered_by_code option[data-disabled='disabled']").each(function () {
      $(".form-explore-filter-by .bootstrap-select ul.dropdown-menu li:eq(" + $(this).index() + ")").hide();
    });

    // make sure the correct weights are being shown
    update_available_weights();


    // if option changes, make sure the select option is not available in the other lists
    $("select.selectpicker").change(function (){
      var val = $(this).val(),
        index = $(this).find("option[value='" + val + "']").index();

      // if this is question, update broken down by
      // else, vice-versa
      if ($(this).attr("id") == "question_code"){
        // update broken down by list

        // turn on all hidden items
        $(".form-explore-broken-by .bootstrap-select ul.dropdown-menu li[style*='display: none']").show();

        // turn on off this item
        $(".form-explore-broken-by .bootstrap-select ul.dropdown-menu li:eq(" + (index+1) + ")").hide();

      }else if ($(this).attr("id") == "broken_down_by_code"){
        // update question list

        // turn on all hidden items
        $(".form-explore-question-code .bootstrap-select ul.dropdown-menu li[style*='display: none']").show();

        // turn on off this item
        $(".form-explore-question-code .bootstrap-select ul.dropdown-menu li:eq(" + (index-1) + ")").hide();

        // if val != "" then turn on swap button
        if (val == ""){
          $("button#btn-swap-vars").fadeOut();
        }else{
          $("button#btn-swap-vars").fadeIn();
        }
      }

      // update filter list
      var q = $("select#question_code").val();
      var q_index = $("select#question_code option[value='" + q + "']").index();
      var bdb = $("select#broken_down_by_code").val();
      var bdb_index = $("select#broken_down_by_code option[value='" + bdb + "']").index();
      // if filter is one of these values, reset filter to no filter
      if (($("select#filtered_by_code").val() == q && q != "") || ($("select#filtered_by_code").val() == bdb && bdb != "")){
        // reset value and hide filter answers
        $("select#filtered_by_code").selectpicker("val", "");
      }

      // turn on all hidden items
      $(".form-explore-filter-by .bootstrap-select ul.dropdown-menu li[style*='display: none']").show();

      // turn off this item
      if (q_index != -1){
        $(".form-explore-filter-by .bootstrap-select ul.dropdown-menu li:eq(" + (q_index + 1) + ")").hide();
      }
      if (bdb_index != -1){
        $(".form-explore-filter-by .bootstrap-select ul.dropdown-menu li:eq(" + bdb_index + ")").hide();
      }


      // update the list of weights
      update_available_weights();

      // update tooltip for selects
      $("form button.dropdown-toggle").tooltip("fixTitle");

      // if selected options have can_exclude, show the checkbox, else hide it
      set_can_exclude_visibility();
    });

    // update tooltip when filter tooltip changes
    $("select.selectpicker-filter").change(function (){
      // if selected options have can_exclude, show the checkbox, else hide it
      set_can_exclude_visibility();

      // update the list of weights
      update_available_weights();

      $("form button.dropdown-toggle").tooltip("fixTitle");

    });

    // update tooltip when weight tooltip changes
    $("select.selectpicker-weight").change(function (){
      $("form button.dropdown-toggle").tooltip("fixTitle");
    });

    // swap vars button
    // - when clicked, swap the values and then submit the form
    $("button#btn-swap-vars").click(function (){
      // get the vals
      var var1 = $("select#question_code").val();
      var var2 = $("select#broken_down_by_code").val();

      // turn off disabled options
      // so can select in next step
      $("select#question_code option[value='" + var2 + "']").removeAttr("disabled");
      $("select#broken_down_by_code option[value='" + var1 + "']").removeAttr("disabled");

      // refresh so disabled options are removed
      $("select#question_code").selectpicker("refresh");
      $("select#broken_down_by_code").selectpicker("refresh");

      // swap the vals
      $("select#question_code").selectpicker("val", var2);
      $("select#broken_down_by_code").selectpicker("val", var1);

      $("select#question_code").selectpicker("render");
      $("select#broken_down_by_code").selectpicker("render");

      // disable the swapped values
      $("select#question_code option[value='" + var1 + "']").attr("disabled", "disabled");
      $("select#broken_down_by_code option[value='" + var2 + "']").attr("disabled", "disabled");

      // refresh so disabled options are updated
      $("select#question_code").selectpicker("refresh");
      $("select#broken_down_by_code").selectpicker("refresh");

      // submit the form
      $("input#btn-submit").trigger("click");
    });

    // get the initial data
    $("#explore-error").fadeOut("slow");
    $("#explore-no-results").fadeOut("slow");
    $("#explore-data-loader").fadeIn("slow", function (){
      get_explore_data();
    });

    // jumpto scrolling
    $("#jumpto").on("change", "select", function () {
      var href = $(this).find("option:selected").data("href");
      $(".tab-pane.active").animate({
        scrollTop: Math.abs($(".tab-pane.active > div > div:first").offset().top - $(".tab-pane.active " + href).offset().top)
      }, 1500);

      // if this is a map item and there are > 1 map items, make sure the other items are set to nil
      var select_index = $("#jumpto #jumpto-map select").index($(this));
      if ($(this).closest("#jumpto-map").length > 0 && $(this).closest("#jumpto-map").find(".jumpto-map-item").length > 1){
        $("#jumpto #jumpto-map select").each(function (i){
          if (i != select_index){
            $(this).find("option:eq(0)").prop("selected", true);
            $(this).selectpicker("refresh");
          }
        });
      }
    });

    // when chart tab/map clicked on, make sure the jumpto block is showing, else, hide it
    $("#explore-tabs li").click(function () {
      var ths_link = $(this).find("a");

      if ($(ths_link).attr("href") == "#tab-chart" && $("#jumpto #jumpto-chart select option").length > 0){
        $("#jumpto").show();
        $("#jumpto #jumpto-chart").show();
        $("#jumpto #jumpto-map").hide();
      }else if ($(ths_link).attr("href") == "#tab-map" && $("#jumpto #jumpto-map select option").length > 0){
        $("#jumpto").show();
        $("#jumpto #jumpto-map").show();
        $("#jumpto #jumpto-chart").hide();
      }else{
        $("#jumpto").hide();
        $("#jumpto #jumpto-chart").hide();
        $("#jumpto #jumpto-map").hide();
      }
    });

    // the below code is to override back button to get the ajax content without page reload
    $(window).bind("popstate", function () {

      // pull out the querystring
      params = queryStringToJSON(window.location.href);

      // for each form field, reset if need to
      // question code
      if (params.question_code != $("select#question_code").val()){
        if (params.question_code == undefined){
          $("select#question_code").val("");
        }else{
          $("select#question_code").val(params.question_code);
        }
        $("select#question_code").selectpicker("refresh");
      }

      // broken down by code
      if (params.broken_down_by_code != $("select#broken_down_by_code").val()){
        if (params.broken_down_by_code == undefined){
          $("select#broken_down_by_code").val("");
        }else{
          $("select#broken_down_by_code").val(params.broken_down_by_code);
        }
        $("select#broken_down_by_code").selectpicker("refresh");
      }
      if ($("select#broken_down_by_code").val() == ""){
        $("#btn-swap-vars").hide();
      }else{
        $("#btn-swap-vars").show();
      }

      // filtered by
      if (params.filtered_by_code != $("select#filtered_by_code").val()){
        if (params.filtered_by_code == undefined){
          $("select#filtered_by_code").val("");
        }else{
          $("select#filtered_by_code").val(params.filtered_by_code);
        }
        $("select#filtered_by_code").selectpicker("refresh");
      }

      // can exclude
      if (params.can_exclude == "true"){
        $("input#can_exclude").attr("checked", "checked");
      }else{
        $("input#can_exclude").removeAttr("checked");
      }

      // reload the data
      $("#jumpto-loader").fadeIn("slow");
      $("#explore-error").fadeOut("slow");
      $("#explore-no-results").fadeOut("slow");
      $("#explore-data-loader").fadeIn("slow", function () {
        get_explore_data(true);
      });
    });
    $(document).on("click", "#chart-type-toggle .toggle", function (){
      var t = $(this),
        type = t.attr("data-type"),
        paramsA = [];

      params["chart_type"] = type;
      for(par in params) {
        paramsA.push(par + "=" + params[par]);
      }

      var new_url = [location.protocol, "//", location.host, location.pathname, "?", paramsA.join("&")].join("");
      // // change the browser URL to the given link location
      if (new_url != window.location.href){ // !is_back_button && 
        window.history.pushState({path:new_url}, $("title").html(), new_url);
      }
      build_explore_data_page(js.cache[cacheId]);
    });
  }
});
