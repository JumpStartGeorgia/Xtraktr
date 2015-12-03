/*global  $, gon, Highcharts, params, js */
/*eslint camelcase: 0, no-underscore-dangle: 0, no-unused-vars: 0, no-undef: 0*/
var datatables, h, i, j, k, cacheId, select_map;

function build_charts (data, type) {
  //console.log("build_charts", data, type);
  if (data.chart) {
    var chart_height = window[type + "_chart_height"](data),     // determine chart height
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
        jumpto_text += "<option data-href='#chart-" + (i+1) + "'>" + d.filter_answer_text + "</option>"; // add jumpto link
      });

      // show jumpto links
      js.jumpto_chart_label.html("(" + data.filtered_by.original_code + ")");
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
  }
}

function build_highmaps (json) { // build highmap
  var jumpto_title = "";
  if (json.map){
    var chart_height = map_chart_height(json), // determine chart height
      weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined,
      jump_options = "",
      map_index = 1;

    $("#container-map").empty(); // remove all existing maps
    //$("#tab-map").addClass("behind_the_scenes");

    $jumpto_map_select.empty();

    if (json.map.constructor === Array) { // filters // test if the filter is being used and build the chart(s) accordingly
      for(h=0; h<json.map.length; h++){
        jumpto_title = "both";
        if (json.broken_down_by && json.map[h].filter_results.map_sets.constructor === Array){
          json.map[h].filter_results.map_sets.forEach(function (d, i) {
            build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.adjustable_max_range, d, chart_height, weight_name);
            jump_options += "<option data-href='#map-" + (map_index) + "'>" + json.map[h].filter_answer_text + " -> " + d.broken_down_answer_text + "</option>";
            ++map_index;
          });
        }
        else{
          jumpto_title = "filtered";
          build_highmap(json.map[h].filter_results.shape_question_code, json.map[h].filter_results.adjustable_max_range, json.map[h].filter_results.map_sets, chart_height, weight_name);
          jump_options += "<option data-href='#map-" + (map_index) + "'>" + json.map[h].filter_answer_text + "</option>";
          ++map_index;
        }
      }
    }
    else { // no filters
      if (json.broken_down_by && json.map.map_sets.constructor === Array) {
        jumpto_title = "broken";
        json.map.map_sets.forEach(function (d, i) {
          build_highmap(json.map.shape_question_code, json.map.adjustable_max_range, d, chart_height, weight_name);
          jump_options += "<option data-href='#map-" + (i+1) + "'>" + d.broken_down_answer_text + "</option>";
        });
      }
      else{
        build_highmap(json.map.shape_question_code, json.map.adjustable_max_range, json.map.map_sets, chart_height, weight_name);
      }
    }
    if(jump_options !== "") {
      var lbl = [];
      if(json.filtered_by) { lbl.push(json.filtered_by.original_code); }
      if(json.broken_down_by) { lbl.push(json.broken_down_by.original_code); }

      $jumpto_map_label.html("(" + lbl.join(" -> ") + ")");
      $jumpto_map_select.html(jump_options);
      $jumpto_map_select.val($jumpto_map_select.find("option:first").attr("value"));
      $jumpto_map_select.selectpicker("refresh");
      $jumpto_map_select.selectpicker("render");
    }
    $("#explore-tabs #nav-map").show(); // show map tabs
  }
  else{
    $("#explore-tabs #nav-map").hide(); // no map so hide tab
    $("#explore-tabs #nav-map, #explore-content #tab-map").removeClass("active"); // make sure these are not active
  }
  var ititle = $("#jumpto #jumpto-map i");
  ititle.attr("title", ititle.data("title-" + jumpto_title));
  ititle.tooltip("fixTitle");
  //$("#tab-map").removeClass("behind_the_scenes");
}

function build_datatable (json) { // build data table
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
  var details_item = $("#tab-details .details-item").hide(); // clear out existing content and hide
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
            t.find(".v").html($(".details-icons ." + type_str)[0].outerHTML + "<span>" + type_text + "</span>");
          }
          t.toggle(exist);

          t = tmp.find(".details-descriptive-statistics");
          if(json_question.descriptive_statistics) {
            t.find(".v li").each(function (i, d) {
              var $t = $(d),
                field_value = json_question.descriptive_statistics[$t.data("field")];

              if(field_value)
              {
                $t.find("span").html(field_value);
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
    is_categorical = json.analysis_data_type == "categorical";

  Object.keys(gon.visual_types).forEach(function (d) {
    if(gon.visual_types[d] == json.chart.visual_type) {
      if([gon.visual_types["bar"], gon.visual_types["pie"]].indexOf(json.chart.visual_type) !== -1)
      {
        type = (typeof params.visual_type !== "undefined" && params.visual_type === gon.visual_types["pie"]) ? "pie" : "bar";
      }
      else { type = d; }
    }
  });

  if(type !== null) { build_charts(json, type); }
  if(is_categorical) { build_highmaps(json); }
  build_datatable(json);
  build_details(json);
  build_page_title(json);

  // if no visible tab is marked as active, mark the first one active
  var explore_tabs = $("#explore-tabs");

  // turn on tab and its content || make sure correct jumptos are showing
  explore_tabs.find("li" +
    (explore_tabs.find("li.active:visible").length == 0 ? ":visible:first": ".active" )
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
      if (json.errors){
        $("#jumpto-loader").fadeOut("slow");
        $("#explore-data-loader").fadeOut("slow");
        $("#explore-error").fadeIn("slow");
      }
      else if ((json.results.analysis && json.results.analysis.length == 0) || (json.results.filtered_analysis && json.results.filtered_analysis.length == 0)){
        $("#jumpto-loader").fadeOut("slow");
        $("#explore-data-loader").fadeOut("slow");
        $("#explore-no-results").fadeIn("slow");
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
    if (typeof params.visual_type !== "undefined" && ([gon.visual_types["bar"], gon.visual_types["pie"]].indexOf(params.visual_type) !== -1)) {
      url_querystring.push("visual_type=" + params.visual_type);
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
    content = "data-content=\"<span>" + g_text + "</span><span class='right-icons'>" + "<img src='/assets/svg/"+sub+"group.svg' title='" + gon["is_" + sub + "group"] + "' />" + "</span>\"";
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
    content += "data-content=\"<span class='outer-layer'><span class='inner-layer'><span>" + q_text + "</span><span class='right-icons'>";

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
  var select_weight = $("select#weighted_by_code"),
    dropdown_weight = $(".form-explore-weight-by .bootstrap-select ul.dropdown-menu");
  if (js.type===1 && js.select_wb.length > 0) {
    if (!select_weight.length) { return; }

    var old_value = select_weight.val(),
      matches=[],
      items = [
        $("select#question_code option:selected").data("weights"),
        $("select#broken_down_by_code option:selected").data("weights"),
        $("select#filtered_by_code option:selected").data("weights")
      ].filter(function (d) { return typeof d !== "undefined"; });

    if(items.length > 0) {
      matches = items.shift().filter(function (v) {
        return items.every(function (a) {
          return a.indexOf(v) !== -1;
        });
      });
    }

    dropdown_weight.find("li:not(:last)").hide();   // hide all items except unweighted

    if (matches.length) { // if there are matches, show the weights that match, and unweighted else hide weight option and set value to unweighted
      var index;
      matches.forEach(function (d, i) {
        index = select_weight.find("option[value='" + d + "']").index();
        if (index != -1){
          dropdown_weight.find("li:eq(" + index + ")").show();
        }
      });

      if (matches.indexOf(old_value) === -1) { // if the old value is no longer an option, select the first one
        select_weight.selectpicker("val", select_weight.find("option:first").attr("value"));
      }
    }
    else{
      $(".form-explore-weight-by").hide();
      select_weight.selectpicker("val", "unweighted");
    }
  }
  else {
    $(".form-explore-weight-by").hide();
    select_weight.selectpicker("val", "unweighted");
  }
}

function set_can_exclude_visibility () { // show or hide the can exclude checkbox
  $("div#can-exclude-container").css("visibility",
    (js.select_qc.find("option:selected").data("can-exclude") == true ||
    js.select_bd.find("option:selected").data("can-exclude") == true ||
    js.select_fb.find("option:selected").data("can-exclude") == true) ? "visible" : "hidden");
}
function jumpto (show, chart) { // show/hide jumpto show - for main box and if chart is false then map
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
        if(js.select_qc.val() == "") {
          $(".instructions").show();
          $(".tab-container").addClass("hide");
        }
        else {
          if ($(".instructions").is(":visible")) {
            $(".instructions").hide();
            $(".tab-container").removeClass("hide");
          }
          $("#jumpto-loader").fadeIn("slow");
          $("#explore-error").fadeOut("slow");
          $("#explore-no-results").fadeOut("slow");
          $("#explore-data-loader").fadeIn("slow", function () {
            get_explore_data();
          });
        }
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
      js.select_qc.find("option[data-disabled='disabled']").each(function () {
        $(".form-explore-question-code .bootstrap-select ul.dropdown-menu li:eq(" + $(this).index() + ")").hide();
      });
      js.select_bd.find("option[data-disabled='disabled']").each(function () {
        $(".form-explore-broken-by .bootstrap-select ul.dropdown-menu li:eq(" + $(this).index() + ")").hide();
      });
      js.select_fb.find("option[data-disabled='disabled']").each(function () {
        $(".form-explore-filter-by .bootstrap-select ul.dropdown-menu li:eq(" + $(this).index() + ")").hide();
      });

      // make sure the correct weights are being shown
      update_available_weights();

      // make sure the instructions start at the correct offset to align with the first drop down
      $(".instructions p:first").css("margin-top", ($(".form-explore-question-code").offset().top - $(".content").offset().top) + 5);

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
          q_type = js.select_qc.find("option[value='" + q + "']").attr("data-type"),
          bdb = js.select_bd.val(),
          bdb_index = js.select_bd.find("option[value='" + bdb + "']").index(),
          bdb_type = js.select_bd.find("option[value='" + bdb + "']").attr("data-type"),
          select_filter_by = $("select#filtered_by_code"),
          also_to_hide,
          old_type = js.type;
        js.type = type;
        // if this is question, update broken down by else vice-versa
        if(id == "question_code") { // update broken down by list
          var broken_by_menu = $(".form-explore-broken-by .bootstrap-select ul.dropdown-menu");
          broken_by_menu.find("li").hide();

          also_to_hide = empty_groups(q_index);

          select_map.forEach(function (d, i){
            if( ((d[0] === 2 && d[2] == type) ||
                (d[0] == 1 && ((type == 1 && d[1] > 0)||(type == 2 && d[2] > 0))) ||
                (d[0] == 0 && ((type == 1 && d[1] > 0)||(type == 2 && d[2] > 0)))) && 
                (also_to_hide.indexOf(i) === -1)) {
              broken_by_menu.find("li[data-original-index='" + i + "']").show();
            }
          });
          broken_by_menu.find("li[data-original-index='0']").show();
          broken_by_menu.find("li:eq(" + index + ")").hide(); // turn on off this item
          if(type !== old_type) { js.select_bd.selectpicker("val", ""); }
        }
        else if (id == "broken_down_by_code"){ // update question list
          var question_code_menu = $(".form-explore-question-code .bootstrap-select ul.dropdown-menu");
          question_code_menu.find("li[style*='display: none']").show(); // turn on all hidden items
          question_code_menu.find("li:eq(" + index + ")").hide(); // turn on off this item
          $("button#btn-swap-vars").fadeToggle(val !== ""); // if val != "" then turn on swap button
          if(bdb_index !== 0)
          {
            empty_groups(bdb_index).forEach(function (d){
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
          if (q !== "" && q_index !== -1){ filter_by_menu.find("li:eq(" + js.select_fb.find("option[value='"+q+"']").index() + ")").hide(); }
          if (bdb !== "" && bdb_index !== -1 && bdb_index !== 0){ filter_by_menu.find("li:eq(" + js.select_fb.find("option[value='"+bdb+"']").index() + ")").hide(); }
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

      if(js.select_qc.val() !== "") {
        // get the initial data
        $("#explore-error").fadeOut("slow");
        $("#explore-no-results").fadeOut("slow");
        $("#explore-data-loader").fadeIn("slow", function (){
          get_explore_data();
        });
      }

      // jumpto scrolling
      $("#jumpto").on("change", "select", function () {
        $("#jumpto button.dropdown-toggle").tooltip("fixTitle");
        $tab_content.animate({
          scrollTop: $tab_content.scrollTop() + $tab_content.find(".tab-pane.active > div > " + $(this).find("option:selected").data("href")).offset().top - $tab_content.offset().top
        }, 1500);    
      });

      // when chart tab/map clicked on, make sure the jumpto block is showing, else, hide it
      $("#explore-tabs li").click(function () {
        var href = $(this).find("a").attr("href");
        if (href == "#tab-chart" && js.jumpto_chart_select.find("option").length > 0){
          jumpto(true, true);
        }else if (href == "#tab-map" && js.jumpto_map_select.find("option").length > 0){
          jumpto(true, false);
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

        params["visual_type"] = gon.visual_types[type];
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
      $(document).on("click", ".available-language-switcher.redirect .dropdown-menu a", function (e){
        e.preventDefault();
        window.location.href = window.location.href + "&" + $(this).attr("href").substr(1);
      });
    },
    init = function () {
      if (!gon.explore_data) { return; }
      Highcharts.setOptions({ // set languaage text
        chart: { spacingRight: 30 },
        lang: {
          contextButtonTitle: gon.highcharts_context_title
        },
        colors: ["#C6CA53", "#7DAA92", "#725752", "#E29A27", "#998746", "#A6D3A0", "#808782", "#B4656F", "#294739", "#1B998B", "#7DAA92", "#BE6E46", "#565264"],
        credits: { enabled: false }
      });

      js = {
        isFox: /Firefox/.test(navigator.userAgent),
        cache: {},
        chart: $("#container-chart"),
        jumpto: $("#jumpto"),
        chart_type_toggle_pie: "<div id='chart-type-toggle'><div class='toggle' data-type='bar' title='" + gon.chart_type_bar + "'></div><div class='toggle selected' data-type='pie' title='" + gon.chart_type_pie + "'></div>",
        chart_type_toggle_bar: "<div id='chart-type-toggle'><div class='toggle selected' data-type='bar' title='" + gon.chart_type_bar + "'></div><div class='toggle' data-type='pie' title='" + gon.chart_type_pie + "'></div>",
        select_qc: $("select#question_code"),
        select_bd: $("select#broken_down_by_code"),
        select_fb: $("select#filtered_by_code"),
        select_wb: $("select#weighted_by_code"),
        type: 1,
        tab_content: $(".tab-content")
      };

      js["jumpto_chart"] = js.jumpto.find("#jumpto-chart");
      js["jumpto_chart_label"] = js.jumpto_chart.find("label span");
      js["jumpto_chart_select"] = js.jumpto_chart.find("select");
      js["jumpto_map"] = js.jumpto.find("#jumpto-map");
      js["jumpto_map_label"] = js.jumpto_map.find("label span");
      js["jumpto_map_select"] = js.jumpto_map.find("select");

      var select_options = build_selects();
      select_map = select_options[2];

      js.select_qc.append(select_options[0]);
      js.select_bd.append(select_options[0]);
      js.select_fb.append(select_options[1]);

      function select_options_default (filters) {
        var qc_option = js.select_qc.find("option[value='"+filters[0]+"']"),
          bd_option = js.select_bd.find("option[value='"+filters[1]+"']");

        if(qc_option.length) {
          var q_index = qc_option.index();

          qc_option.attr("selected", "selected");
          js.type = +qc_option.attr("data-type");
          var type = js.type;

          also_to_hide = empty_groups(q_index);
          js.select_bd.find("option:eq("+(q_index)+")").attr("data-disabled", "disabled");
          select_map.forEach(function (d, i){
            if(!(((d[0] === 2 && d[2] == type) ||
                (d[0] == 1 && ((type == 1 && d[1] > 0)||(type == 2 && d[2] > 0))) ||
                (d[0] == 0 && ((type == 1 && d[1] > 0)||(type == 2 && d[2] > 0)))) &&
                (also_to_hide.indexOf(i) === -1))) {
              js.select_bd.find("option:eq(" + i + ")").attr("data-disabled", "disabled");
            }
          });

          if(bd_option.length) {
            var bdb_index = bd_option.index();
            bd_option.attr("selected", "selected");
            if(bdb_index !== 0) {
              js.select_qc.find("option:eq(" + bdb_index + ")").attr("data-disabled", "disabled");
              $("button#btn-swap-vars").fadeToggle(true); // if val != "" then turn on swap button

              empty_groups(bdb_index-1).forEach(function (d){
                js.select_qc.find("option:eq("+ d +")").attr("data-disabled", "disabled");
              });
            }
          }
        }
        set_can_exclude_visibility();
        js.select_fb.find("option[value='"+filters[2]+"']").attr("selected", "selected");
        js.select_fb.find("option[value='"+filters[0]+"'], option[value='"+filters[1]+"']").attr("data-disabled", "disabled");
      }
      select_options_default(gon.questions.filters);

      bind();
    };

  init();
});