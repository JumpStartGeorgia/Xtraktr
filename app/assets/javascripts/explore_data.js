/*global  $, gon, Highcharts, params */
/*eslint camelcase: 0, no-underscore-dangle: 0, no-unused-vars: 0, no-undef: 0*/
var datatables, h, i, j, k, cacheId,
  js, select_map;

function build_charts (data, type) {
  //console.log("build_charts", data, type);
  if (data.chart) {
    var flag = false,
      chart_height = window[type + "_chart_height"](data),     // determine chart height // pie_chart_height(json);
      weight_name = data.weighted_by ? data.weighted_by.weight_name : undefined,
      jumpto_text = "";

    // check existence of height function for all chart types

    js.chart.empty();  // remove all existing charts
    if(["pie", "bar"].indexOf(type) !== -1) {
      js.chart.append(js["chart_type_toggle_" + type]);
    }
    js.jumpto_chart_select.empty();  // remove all existing chart links

    // test if the filter is being used and build the chart(s) accordingly
    if (data.chart.constructor === Array) { // filters
      data.chart.forEach(function (d, i){
        if(type === "crosstab")
        {
          window["build_" + type + "_chart"]({
            qcode: data.question.original_code,
            qtext: data.question.text,
            bcode: data.broken_down_by.original_code,
            btext: data.broken_down_by.text,
            filtered: data.filtered_by ? true : false },
            d.filter_results, chart_height, weight_name);
        }
        else {
          if(type === "histogramm") {
            d.filter_results["numerical"] = data.question.numerical;
          }
          window["build_" + type + "_chart"](d.filter_results, chart_height, weight_name); // create chart
        }
        jumpto_text += "<option data-href='#chart-" + (i+1) + "'>" + data.filtered_by.text + " = " + d.filter_answer_text + "</option>"; // add jumpto link
      });

      // show jumpto links
      js.jumpto_chart_select.append(jumpto_text);
      js.jumpto_chart_select.val(js.jumpto_chart_select.find("option:first").attr("value"));
      js.jumpto_chart_select.selectpicker("refresh");
      js.jumpto_chart_select.selectpicker("render");
      flag = true;
    }
    else { // no filters or filtered scatter
      if(["crosstab", "scatter"].indexOf(type) !== -1) {
        window["build_" + type + "_chart"]({
          qcode: data.question.original_code,
          qtext: data.question.text,
          bcode: data.broken_down_by.original_code,
          btext: data.broken_down_by.text,
          filtered: data.filtered_by ? true : false },
          data.chart, chart_height, weight_name);
      }
      else {
        if(type === "histogramm") {
          data.chart["numerical"] = data.question.numerical;
        }
        window["build_" + type + "_chart"](data.chart, chart_height, weight_name); // create chart
      }
    }
    js.jumpto_chart.toggle(flag);
    js.jumpto.toggle(flag);
  }
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
    $("#tab-map").addClass("behind_the_scenes");

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
  $("#tab-map").removeClass("behind_the_scenes");
}

function build_datatable (json) { // build data table
  //console.log("datatable",json);
  //if(!(json.analysis_type == "comparative" && json.analysis_data_type == "numerical")) {

  $("#container-table h3").html(json.results.title.html + json.results.subtitle.html); // set the title
  
  if (datatables != undefined && datatables.length > 0) { // if the datatable alread exists, kill it
    for (i=0;i<datatables.length;i++){
      datatables[i].fnDestroy();
    }
  }

  var
    $table = $("#container-table table"),
    ln, key_text, 
    n = json.analysis_data_type == "numerical",
    is_weighted = json.weighted_by != undefined, // test if data is weighted so can build table accordingly
    col_headers = is_weighted ? ["unweighted-count", "weighted-count", "weighted-percent"] : ["count", "percent"],
    col_header_count = col_headers.length,
    table = "<thead>", // build the table
    nofilter = json.filtered_by == undefined,
    is_comparative = json.analysis_type == "comparative";
      
  // build head --------------
  // test if the filter is being used and build the table accordingly
  table += "<tr>";
  if(n && is_comparative) {
    if(nofilter) { // question code question   count percent count percent .....
      table += "<th class='code-highlight'>" + json.question.original_code + "</th>" +
        "<th class='code-highlight'>" + json.broken_down_by.original_code + "</th></tr>";
    }
    else {
      table += "<th class='code-highlight'>" + json.filtered_by.original_code + "</th>" +
      "<th class='code-highlight'>" + json.question.original_code + "</th>" +
      "<th class='code-highlight'>" + json.broken_down_by.original_code + "</th></tr>";
    }
  }
  else {
    if (is_comparative) { // 3 headers of: broken_down_by question broken_down_by answers .....
      if(nofilter) { // question code question   count percent count percent .....
        table += "<th class='var1-col-red'>" + gon.table_questions_header + "</th>" +
          "<th class='code-highlight' colspan='" + (col_header_count*(json.broken_down_by.answers.length+1)).toString() + "'>" + json.broken_down_by.original_code + "</th></tr>" +
          "<tr><th class='var1-col code-highlight' rowspan='2'>" + json.question.original_code + "</th>";
      }
      else { // filter question   count percent count percent .....
        table += "<th class='var1-col-red' colspan='2'>" + gon.table_questions_header + "</th>" +
          "<th class='code-highlight' colspan='" + (2*(json.broken_down_by.answers.length+1)).toString() + "'>" + json.broken_down_by.original_code + "</th></tr>" +
          "<tr><th class='var1-col code-highlight' rowspan='2'>" + json.filtered_by.original_code + "</th>" +
          "<th class='var1-col code-highlight' rowspan='2'>" + json.question.original_code + "</th>";
      }

      ln = json.broken_down_by.answers.length;
      for(i=0; i<ln;i++) {
        table += "<th colspan='" + col_header_count + "' class='color"+(i % 13 + 1)+"'>" + json.broken_down_by.answers[i].text.toString() + "</th>";
      }
      table += "</tr><tr>";

      for(i=0; i<ln;i++){
        for(j=0; j<col_header_count;j++){
          table += "<th>" + $table.data(col_headers[j]) + "</th>";
        }
      }
    }
    else { // 1 header of: question code question, count, percent // 1 header of: filter question, count, percent
      table += (nofilter ? "" :"<th class='var1-col'>" + json.filtered_by.original_code + "</th>") +
        "<th class='var1-col code-highlight'>" + json.question.original_code + "</th>";

      col_headers.forEach(function (d, i){
        table += "<th>" + $table.data(d) + "</th>";
      });
    }
  }
  table += "</tr></thead><tbody>";

  function fill (v) {
    for(k=0; k<col_header_count;k++){
      key_text = v[col_headers[k].replace("-", "_")]; // key is written with "-" but for this part, it must be "_"
      if (k < col_header_count-1) { // percent is the last item and all items before are percent
        table += "<td class='text-right' data-order='" + key_text + "'>" + Highcharts.numberFormat(key_text, 0) + "</td>";
      }
      else { table += "<td class='text-right'>" + (key_text ? key_text.toFixed(2) : "0") + "%</td>"; }
    }
  }
  //build body --------------
  if(n && is_comparative) {
    if(nofilter){
      json.results.analysis.forEach(function (an, an_i) {
        table += "<tr><td class='text-right'>" + an[0] + "</td><td class='text-right'>" + an[1] + "</td></tr>";
      });
    }
    else {
      json.results.filter_analysis.forEach(function (fa, fa_i) {
        fa.filter_results.analysis.forEach(function (an, an_i) {
          table += "<tr><td class='var1-col text-left'>" + fa.filter_answer_text + "</td>" +
            "<td class='text-right'>" + an[0] + "</td><td class='text-right'>" + an[1] + "</td></tr>";
        });
      });
    }
  }
  else {
    if(nofilter){
      json.results.analysis.forEach(function (an, an_i) {
        if(is_comparative) {
          table += "<tr><td class='var1-col' data-order='" + (n ? an_i : json.question.answers[an_i].sort_order) + "'>" + an.answer_text + "</td>";
          an.broken_down_results.forEach(function (bd){ fill(bd); });
        }
        else {
          table += "<tr><td class='var1-col' data-order='" + (n ? an_i : json.question.answers[an_i].sort_order) + "'>" + an.answer_text + "</td>";
          fill(an);
        }
        table += "</tr>";
      });
    }
    else {
      json.results.filter_analysis.forEach(function (fa, fa_i) {
        fa.filter_results.analysis.forEach(function (an, an_i) {
          table += "<tr><td class='var1-col' data-order='" + json.filtered_by.answers[fa_i].sort_order + "'>" + fa.filter_answer_text + "</td>" +
            "<td class='var1-col' data-order='" + (n ? an_i : json.question.answers[an_i].sort_order) + "'>" + an.answer_text + "</td>";
          
          if(is_comparative) { an.broken_down_results.forEach(function (bd) { fill(bd); }); }
          else { fill(an); }

          table += "</tr>";
        });
      });
    }  
  }
  
  table += "</tbody>";

  $table.html(table);

  // initalize the datatable
  datatables = [];
  $table.each(function () {
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
  var tmp = $("#tab-table .table-weighted-footnote");
  if (json.weighted_by){
    tmp.find(" .footnote-weight-name").html(json.weighted_by.weight_name);
  }else{
    tmp.find(" .footnote-weight-name").empty();
  }
  tmp.toggle(json.weighted_by);
  //}
  // else{
  //   // no map so hide tab !question
  //   $("#explore-tabs #nav-table").hide();
  //   // make sure these are not active
  //   $("#explore-tabs #nav-table, #explore-content #tab-table").removeClass("active");
  // }
}

function build_details (json) { // build details (question and possible answers)
  // clear out existing content and hide
  var details_item = $("#tab-details .details-item").hide();
  details_item.find(".name-group .group-title, .name-group .group-description, .name-subgroup .group-title, .name-subgroup .group-description, .name-variable, .name-code, .notes, .list-answers").empty();

  build_details_item(json);

  function build_details_item (json) { // populat a details item block
    var selector = "", json_question = undefined, t, exist, tmp, icon, is_categorical;
    ["question", "brokey-down-by", "filtered-by", "weighted-by"].forEach(function (d){
      selector = "#tab-details #details-"+ d +"-code";
      json_question = json[d.replace(/-/g, "_")];
      if (json_question && json_question.text){
        tmp = $(selector);
        if (tmp.length > 0){
          icon = "";
          is_categorical = json_question.data_type === 1;
          if (json_question.exclude){
            icon += $(".details-icons .exclude-question")[0].outerHTML;
          }
          if (json_question.is_mappable){
            icon += $(".details-icons .mappable-question")[0].outerHTML;
          }

          tmp.find(".name-variable").html(icon + json_question.text);
          tmp.find(".name-code").html(json_question.original_code);


          t = tmp.find(".details-data-type");
          exist = !!json_question["data_type"];
          if(exist) {
            var type_str = is_categorical ? "categorical" : "numerical",
              type_text = t.data(type_str);
            t.find(".v").html("<span>" + type_text + "</span>" + $(".details-icons ." + type_str)[0].outerHTML);
          }
          t.toggle(exist);

          t = tmp.find(".details-descriptive-statistics");
          if(json_question.descriptive_statistics) {
            t.find(".v li").each(function (i, d) {
              var $t = $(d),
                field_value = json_question.descriptive_statistics[$t.data("field")];

              if(field_value)
              {
                $t.find("span").html(Math.round10(+field_value, -2));
                $t.show();
              }
              else { $t.hide(); }
            });
            t.show();
          }
          else { t.hide(); }

          ["notes", "weight"].forEach(function (d, i){
            t = tmp.find(".details-" + d);
            d = (d === "weight" ? "weight_name" : d);
            exist = !!json_question[d];
            if(exist) { t.find("." + d).html(json_question[d]); }
            t.toggle(exist);
          });

          ["group", "subgroup"].forEach(function (d, i){
            t = tmp.find(".details-" + d);
            exist = !!json_question[d];
            if(exist) {
              var ng = t.find(".name-" + d);
              ng.find(".group-title").html(json_question[d].title);
              if (json_question[d].description !== ""){
                ng.find(".group-description").html(" - " + json_question[d].description);
              }
            }
            t.toggle(exist);
          });

          t = tmp.find(".details-answers");
          if (json_question.answers && is_categorical){
            for(var i=0;i<json_question.answers.length;i++){
              icon = "";
              if (json_question.answers[i].exclude){
                icon += $(".details-icons .exclude-answer")[0].outerHTML;
              }
              t.find(".list-answers").append("<li>" + icon + json_question.answers[i].text + "</li>");
            }
            t.show();
          }else{
            t.hide();
          }

          tmp.show();
        }
      }
    });
  }
}

function build_explore_data_page (json) { // build the visualizations for the explore data page
  var type = null,
    is_comparative = json.analysis_type == "comparative",
    is_categorical = json.analysis_data_type == "categorical";

  if (is_comparative){
    if(is_categorical) {
      type = "crosstab";
    }
    else if(json.analysis_data_type == "numerical") {
      type = "scatter";
    }
  }
  else {
    if(is_categorical) {
      type = (typeof params.chart_type !== "undefined" && params.chart_type === "pie") ? "pie" : "bar";
    }
    else {
      type = "histogramm";
    }
  }
  if(type !== null) { build_charts(json, type); }
  if(is_categorical) { build_highmaps(json); }
  build_datatable(json);
  build_details(json);

  build_page_title(json);

  // if no visible tab is marked as active, mark the first one active
  var explore_tabs = $("#explore-tabs");

  // turn on tab and its content || make sure correct jumptos are showing
  explore_tabs.find("li" +
    (explore_tabs.find("li.active:visible").length == 0 ? ":visible:first": "li.active" )
  ).trigger("click");
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

function build_selects (skip_content) {
  //console.log(gon.questions);
  var q = gon.questions,
    dataset = q.dataset,
    html = "",
    html_only_categorical = "",
    type_map = [],
    type_map_index = 0;

  skip_content = (typeof skip_content !== "boolean" ? false : skip_content);

  build_options_partial(q.items, null, null);

  function build_options_partial (items, level, parent_id) { // todo
    var tmp = "";
    items.forEach(function (item) {
      if(item.hasOwnProperty("parent_id")) { // Group
        tmp = build_selects_group_option(item);
        html += tmp;
        html_only_categorical += tmp;

        type_map.push([(level === null ? 0 : 1), 0, 0, (level === null ? null : type_map_index)]);

        if(item.subitems !== null) {
          build_options_partial(item.subitems, (level !== null ? "subgroup" : "group"), type_map_index);
        }
      }
      else if(item.hasOwnProperty("code")){ // Question
        if (item.is_analysable) {
          tmp = build_selects_question_option(item, level, skip_content);
          html += tmp;
          type_map.push([2, item.code, item.data_type, parent_id]);
          if(item.data_type === 1) { html_only_categorical += tmp; }
        }
      }
      ++type_map_index;
    });
  }
  var counts = [0, 0, 0, 0]; // group cat, num, subgroup cat, num
  var cat_count = 0, num_count = 0, cur;
  for(i = type_map.length-1; i >= 0; --i) {
    cur = type_map[i];
    if(cur[0] == 2) {
      if(cur[2] == 1) { ++counts[0]; ++counts[2]; }
      if(cur[2] == 2) { ++counts[1]; ++counts[3]; }
    }
    else if(cur[0] == 1) {
      cur[1] = counts[2];
      cur[2] = counts[3];
      counts[2] = counts[3] = 0;
    }
    else if(cur[0] == 0) {
      cur[1] = counts[0];
      cur[2] = counts[1];
      counts[0] = counts[1] = counts[2] = counts[3] = 0;
    }
  }
  return [html, html_only_categorical, type_map];
}
function build_selects_group_option (group) {
  var has_parent = group.parent_id !== null,
    sub = (has_parent ? "sub" : ""),
    g_text = group.title,
    content = "data-content=\"<span>" + g_text + "</span><span class='pull-right'>" + "<img src='/assets/svg/"+sub+"group.svg' title='" + gon["is_" + sub + "group"] + "' />" + "</span>\"";
  return "<option class='" + sub + "group' disabled='disabled' " + content + ">" + g_text + "</option>";
}
function build_selects_question_option (question, level, skip_content) {
  var q_text = question.original_code + " - " + question.text,
    selected = "",
    disabled = "",
    // selected = selected_code.present? && selected_code == question.code ? 'selected=selected ' : '',
    // disabled = (disabled_code.present? && disabled_code == question.code) || (disabled_code2.present? && disabled_code2 == question.code) ? 'data-disabled=disabled ' : '',
    can_exclude = question.has_can_exclude_answers ? "data-can-exclude=true " : "",
    cls = (level === "group" ? "grouped" : (level === "subgroup" ? "grouped subgrouped" : "")),
    weights = "",
    content = "";

  if(gon.questions.weights.length) {
    var w = gon.questions.weights.filter(function (weight) { return (weight.is_default || weight.applies_to_all || weight.codes.indexOf(question.code) !== -1); });
    if(w.length) {
      weights = "data-weights=\'[\"" + w.map(function (x){ return x.code; }).join("\",\"") + "\"]\'";
    }
  }
  // if the question is mappable or is excluded, show the icons for this
  if (!skip_content || question.data_type !== 0) {
    content += "data-content=\"<span class='outer-layer'><span class='inner-layer'><span>" + q_text + "</span><span class='pull-right'>";

    if(question.data_type !== 0) {
      var type = question.data_type == 1 ? "categorical" : "numerical";
      content += "<img src='/assets/svg/" + type + ".svg' title='"+ gon["question_type_" + type] + "'/>";
    }

    if(question.is_mappable) {
      content += "<img src='/assets/svg/map.svg' title='" + gon.mappable_question + "' />";
    }

    if(question.exclude) {
      content += "<img src='/assets/svg/lock.svg' title='" + gon.private_question + "' />";
    }

    content += "</span></span></span>\"";

  }
  return "<option class='"+cls+"' value='"+question.code+"' title='"+q_text+"' "+selected+" "+disabled+" "+content+" "+can_exclude+" "+weights+" data-type='"+question.data_type+"'>"+q_text+"</option>";
}

function update_available_weights () { // update the list of avilable weights based on questions that are selected
  // update weight list if weights exist
  if (js.type===1 && js.select_wb.length > 0) {
    var old_value = js.select_wb.val();
    var items = [
      js.select_qc.find("option:selected").data("weights"),
      js.select_bd.find("option:selected").data("weights"),
      js.select_fb.find("option:selected").data("weights")
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

      // if the old value is no longer an option, select the first one
      if (matches.indexOf(old_value) == -1){
        $('select#weighted_by_code').selectpicker('val', $('select#weighted_by_code option:first').attr('value'));
      }

      $('.form-explore-weight-by').show();
    } 
    else {
      $(".form-explore-weight-by").hide();
      $("select#weighted_by_code").selectpicker("val", "unweighted");
    }
  }
  else {
    $(".form-explore-weight-by").hide();
    $("select#weighted_by_code").selectpicker("val", "unweighted");
  }
}

function set_can_exclude_visibility () { // show or hide the can exclude checkbox
  $("div#can-exclude-container").css("visibility",
    ($("select#question_code option:selected").data("can-exclude") == true ||
    $("select#broken_down_by_code option:selected").data("can-exclude") == true ||
    $("select#filtered_by_code option:selected").data("can-exclude") == true) ? "visible" : "hidden");
}
function jumpto(show, chart) { // show/hide jumpto show - for main box and if chart is false then map
  if(typeof chart === "undefined") { chart = true; }
  js.jumpto.toggle(show);
  js.jumpto_chart.toggle(show && chart);
  js.jumpto_map.toggle(show && !chart);
}
function empty_groups (index) {
  var tmp_index = select_map[index][3],
    tmp_data_type = select_map[index][2],
    also_to_hide = [];

  if([1, 2].indexOf(tmp_data_type) !== -1)
  {
    while(tmp_index !== null){
      var gr = select_map[tmp_index];
      if(gr[tmp_data_type] <= 1) {
        also_to_hide.push(tmp_index);
      }
      tmp_index = select_map[tmp_index][3];
    }
  }
  return also_to_hide;
}
$(document).ready(function () {
  var
    bind = function () {
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
        var t = $(this),
          id = t.attr("id"),
          val = t.val(),
          option = t.find("option[value='" + val + "']"),
          index = option.index(),
          type = +option.attr("data-type"),
          q = js.select_qc.val(),
          q_index = js.select_qc.find("option[value='" + q + "']").index(),
          bdb = js.select_bd.val(),
          bdb_index = js.select_bd.find("option[value='" + bdb + "']").index(),
          select_filter_by = $("select#filtered_by_code"),
          also_to_hide;
        js.type = type;
        // if this is question, update broken down by else vice-versa
        if(id == "question_code") { // update broken down by list
          var broken_by_menu = $(".form-explore-broken-by .bootstrap-select ul.dropdown-menu");
          broken_by_menu.find("li").hide();

          //broken_by_menu.find("li[style*='display: none']").show(); // turn on all hidden items
          // $(".form-explore-filter-by").toggle(type===1);
          
          also_to_hide = empty_groups(q_index);

          select_map.forEach(function (d, i){
            if( ((d[0] === 2 && d[2] == type) ||
                (d[0] == 1 && ((type == 1 && d[1] > 0)||(type == 2 && d[2] > 0))) ||
                (d[0] == 0 && ((type == 1 && d[1] > 0)||(type == 2 && d[2] > 0)))) && 
                (also_to_hide.indexOf(i) === -1)) {
              broken_by_menu.find("li[data-original-index='" + (i + 1) + "']").show();
            }
          });
          broken_by_menu.find("li[data-original-index='0']").show();
          broken_by_menu.find("li:eq(" + (index+1) + ")").hide(); // turn on off this item

          // turn on all items of same data_type
          // select_broken_down.find("option[data-type='"+type+"']").each(function (i, d) {
          //   broken_by_menu.find("li[data-original-index='" + ($(d).index()) + "']").show();
          // });
        }
        else if (id == "broken_down_by_code"){ // update question list
          var question_code_menu = $(".form-explore-question-code .bootstrap-select ul.dropdown-menu");
          question_code_menu.find("li[style*='display: none']").show(); // turn on all hidden items
          question_code_menu.find("li:eq(" + (index-1) + ")").hide(); // turn on off this item
          $("button#btn-swap-vars").fadeToggle(val !== ""); // if val != "" then turn on swap button
          if(bdb_index !== 0)
          {
            empty_groups(bdb_index-1).forEach(function (d){
              question_code_menu.find("li:eq(" + (d) + ")").hide();
            });
          }
        }

        // update filter list
        if ((select_filter_by.val() == q && q != "") || (select_filter_by.val() == bdb && bdb != "")){ // if filter is one of these values, reset filter to no filter
          select_filter_by.selectpicker("val", ""); // reset value and hide filter answers
        }

        // turn on all hidden items
        var filter_by_menu = $(".form-explore-filter-by .bootstrap-select ul.dropdown-menu");

        filter_by_menu.find("li[style*='display: none']").show();

        // turn off this item only if question type is categorical
        if(type === 1) {
          if (q_index != -1){ filter_by_menu.find("li:eq(" + (q_index + 1) + ")").hide(); }
          if (bdb_index != -1){ filter_by_menu.find("li:eq(" + bdb_index + ")").hide(); }
        }
        
        update_available_weights(); // update the list of weights

        $("form button.dropdown-toggle").tooltip("fixTitle"); // update tooltip for selects
        
        set_can_exclude_visibility(); // if selected options have can_exclude, show the checkbox, else hide it
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
        var var1 = js.select_qc.val(), // get the vals
          var2 = js.select_bd.val();

        // turn off disabled options
        // so can select in next step
        js.select_qc.find("option[value='" + var2 + "']").removeAttr("disabled");
        js.select_bd.find("option[value='" + var1 + "']").removeAttr("disabled");

        // refresh so disabled options are removed
        js.select_qc.selectpicker("refresh");
        js.select_bd.selectpicker("refresh");

        // swap the vals
        js.select_qc.selectpicker("val", var2);
        js.select_bd.selectpicker("val", var1);

        js.select_qc.selectpicker("render");
        js.select_bd.selectpicker("render");

        // disable the swapped values
        js.select_qc.find("option[value='" + var1 + "']").attr("disabled", "disabled");
        js.select_bd.find("option[value='" + var2 + "']").attr("disabled", "disabled");

        // refresh so disabled options are updated
        js.select_qc.selectpicker("refresh");
        js.select_bd.selectpicker("refresh");

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
        var href = $(this).find("a").attr("href");
        if (href == "#tab-chart" &&  js.jumpto_chart.find("select option").length > 0){
          jumpto(true, true);
        }else if (href == "#tab-map" &&  js.jumpto_map.find("select option").length > 0){
          jumpto(show_map_jumpto, false);
        }else{
          jumpto(false);
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
        $(this).tooltip("hide");
        build_explore_data_page(js.cache[cacheId]);
      }); 
    },
    init = function () {
      if (!gon.explore_data) { return; }
      Highcharts.setOptions({ // set languaage text
        chart: { spacingRight: 30 },
        lang: {
          contextButtonTitle: gon.highcharts_context_title
        },
        colors: ['#00adee', '#e88d42', '#9674a9', '#f3d952', '#6fa187', '#b2a440', '#d95d6a', '#737d91', '#d694e0', '#80b5bc', '#a6c449', '#1b74cc', '#4eccae'],
        credits: { enabled: false }
      });

      js = {
        cache: {},
        chart: $("#container-chart"),
        jumpto: $("#jumpto"),
        chart_type_toggle_pie: "<div id='chart-type-toggle'><div class='toggle' data-type='bar' title='" + gon.chart_type_bar + "'></div><div class='toggle selected' data-type='pie' title='" + gon.chart_type_pie + "'></div>",
        chart_type_toggle_bar: "<div id='chart-type-toggle'><div class='toggle selected' data-type='bar' title='" + gon.chart_type_bar + "'></div><div class='toggle' data-type='pie' title='" + gon.chart_type_pie + "'></div>",
        select_qc: $("select#question_code"),
        select_bd: $("select#broken_down_by_code"),
        select_fb: $("select#filtered_by_code"),
        select_wb: $('select#weighted_by_code'),
        type: 1
      };

      js["jumpto_chart"] = js.jumpto.find("#jumpto-chart");
      js["jumpto_map"] = js.jumpto.find("#jumpto-map");
      js["jumpto_chart_select"] = js.jumpto_chart.find("select");
      js["jumpto_map_select"] = js.jumpto_map.find("select");

      var select_options = build_selects();

      select_map = select_options[2];

      js.select_qc.append(select_options[0]);
      js.select_bd.append(select_options[0]);
      js.select_fb.append(select_options[1]);

      function select_options_default (filters) {  
        js.select_qc.find("option[value='"+filters[0]+"']").attr("selected=selected");
        js.type = +js.select_qc.find("option[value='"+filters[0]+"']").attr("data-type");
        js.select_qc.find("option[value='"+filters[1]+"']").attr("data-disabled=disabled");
        js.select_bd.find("option[value='"+filters[1]+"']").attr("selected=selected");
        js.select_bd.find("option[value='"+filters[0]+"']").attr("data-disabled=disabled");
        js.select_fb.find("option[value='"+filters[2]+"']").attr("selected=selected");
        js.select_fb.find("option[value='"+filters[0]+"'], option[value='"+filters[1]+"']").attr("data-disabled=disabled");
      }
      select_options_default(gon.questions.filters);

      bind();
    };

  init();
});
