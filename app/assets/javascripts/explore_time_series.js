/*global  $, gon, Highcharts, params, console, queryStringToJSON, TableTools, time_series_chart_height, build_time_series_chart, build_page_title */
/*eslint no-undef: 0, no-console: 0  */
var datatables, i, j, tmp;

function build_time_series_charts (json){ // build time series line chart for each chart item in json
  if (json.chart){
    // determine chart height
    var chart_height = time_series_chart_height(json);

    // remove all existing charts
    js.chart.empty();
    // remove all existing chart links
    js.jumpto_chart_select.empty();

    var jumpto_text = "";
    var weight_name = json.weighted_by ? json.weighted_by.weight_name : undefined;

    // test if the filter is being used and build the chart(s) accordingly
    if (json.chart.constructor === Array){
      // filters
      for(var i=0; i<json.chart.length; i++){
        // create chart
        build_time_series_chart(json.chart[i].filter_results, chart_height, weight_name);

        // add jumpto link
        jumpto_text += "<option data-href='#chart-" + (i+1) + "'>" + json.chart[i].filter_answer_text + "</option>";
      }

      // show jumpto links
      js.jumpto_chart_label.html("(" + json.filtered_by.original_code + ")");
      js.jumpto_chart_select.append(jumpto_text);
      js.jumpto_chart_select.val(js.jumpto_chart_select.find("option:first").attr("value"));
      js.jumpto_chart_select.selectpicker("refresh");
      js.jumpto_chart_select.selectpicker("render");

    }else{
      // no filters
      build_time_series_chart(json.chart, chart_height, weight_name);
    }
  }
}

function build_datatable (json) { // build data table
  $("#container-table h3").html(json.results.title.html + json.results.subtitle.html); // set the title

  if (datatables != undefined && datatables.length > 0){ // if the datatable alread exists, kill it
    for (var i=0;i<datatables.length;i++){ datatables[i].fnDestroy(); }
  }

  var
    $table = $("#container-table table"),
    ln,
    is_weighted = json.weighted_by != undefined, // test if data is weighted so can build table accordingly
    col_headers = is_weighted ? ["unweighted-count", "weighted-count", "weighted-percent"] : ["count", "percent"],
    col_header_count = col_headers.length,
    table = "<thead>", // build the table
    nofilter = json.filtered_by == undefined;

  if (nofilter) { // test if the filter is being used and build the table accordingly
    // build head
    // 2 headers of:  dataset label question   count percent count percent .....
    table += "<tr class='th-center'>" +
      "<th class='var1-col-red'>" + gon.table_questions_header + "</th>";

    ln = json.datasets.length;
    for(i=0; i<ln;i++){
      table += "<th colspan='" + col_header_count + "' class='code-highlight color"+(i % 13 + 1)+"'>" +
        json.datasets[i].label + "</th>";
    }
    table += "</tr><tr><th class='var1-col code-highlight'>" + json.question.original_code + "</th>";
    for(i=0; i<json.datasets.length;i++){
      for(j=0; j<col_header_count;j++){
        table += "<th>" + $table.data(col_headers[j]) + "</th>";
      }
    }
    table += "</tr></thead><tbody>";

    // build body
    json.results.analysis.forEach(function (an, an_i) { // cells per row: row answer, count/percent for each col
      table += "<tr><td class='var1-col' data-order='" + json.question.answers[an_i].sort_order + "'>" +
            an.answer_text + "</td>";
      an.dataset_results.forEach(function (dr){
        for(var k=0; k<col_header_count;k++){
          var key_text = dr[col_headers[k].replace("-", "_")]; // key is written with "-" but for this part, it must be "_"

          if(k < col_header_count-1) { // percent is the last item and all items before are percent
            table += "<td data-order='" + key_text + "'>";
            if(key_text) { table += Highcharts.numberFormat(key_text, 0); }
            table += "</td>";
          }
          else{
            table += "<td>";
            if (key_text){ table += key_text.toFixed(2) + "%"; }
            table += "</td>";
          }
        }
      });
    });
    table += "</tbody>";

  }else{
    // build head
    // 2 headers of: dataset label filter   question   count percent count percent .....
    table += "<tr class='th-center'><th class='var1-col-red' colspan='2'>" + gon.table_questions_header + "</th>";
    ln = json.datasets.length;
    for(i=0; i<ln;i++){
      table += "<th colspan='" + col_header_count + "' class='code-highlight color"+(i % 13 + 1)+"'>" + json.datasets[i].label + "</th>";
    }
    table += "</tr><tr><th class='var1-col code-highlight'>" + json.filtered_by.original_code + "</th><th class='var1-col code-highlight'>" + json.question.original_code + "</th>";
    for(i=0; i<json.datasets.length;i++){
      for(j=0; j<col_header_count;j++){
        table += "<th>" + $table.data(col_headers[j]) + "</th>";
      }
    }
    table += "</tr></thead><tbody>";

    // build body
    // for each filter, show each question and the count/percents for each dataset
    json.results.filter_analysis.forEach(function (an, an_i) {
      an.filter_results.analysis.forEach(function (fan, fan_i) {

        table += "<tr><td class='var1-col' data-order='" + json.filtered_by.answers[an_i].sort_order + "'>" + an.filter_answer_text + "</td>" +
          "<td class='var1-col' data-order='" + json.question.answers[fan_i].sort_order + "'>" +
          fan.answer_text + "</td>";
        fan.dataset_results.forEach(function (dr) {
          for(k=0; k<col_header_count;k++){
            key_text = col_headers[k].replace("-", "_"); // key is written with '-' but for this part, it must be '_'
            if (k < col_header_count-1) { // percent is the last item and all items before are percent
              table += "<td data-order='" + dr[key_text] + "'>";
              if (dr[key_text]){ table += Highcharts.numberFormat(dr[key_text], 0); }
              table += "</td>";
            }else{
              table += "<td>";
              if (dr[key_text]){ table += dr[key_text].toFixed(2) + "%"; }
              table += "</td>";
            }
          }
        });
        table += "</tr>";
      });
    });
    table += "</tbody>";
  }


  // add the table to the page
  $table.html(table);

  //initalize the datatable
  datatables = [];
  $table.each(function (){
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

  tmp = $("#tab-table .table-weighted-footnote");
  if (json.weighted_by){
    tmp.find(" .footnote-weight-name").html(json.weighted_by.weight_name);
  }else{
    tmp.find(" .footnote-weight-name").empty();
  }
  tmp.toggle(json.weighted_by);

}

function build_details (json) { // build details (question and possible answers)

  var details_item = $("#tab-details .details-item").hide(); // clear out existing content and hide
  details_item.find(".name-group .group-title, .name-group .group-description, .name-subgroup .group-title, .name-subgroup .group-description, .name-variable, .name-code, .notes, .list-answers").empty();

  build_details_item(json);

  function build_details_item (json) { // populat a details item block
    var selector = "", json_question = undefined, t, exist, icon, is_categorical;
    ["question", "filtered-by", "weighted-by"].forEach(function (d){
      selector = "#tab-details #details-"+ d +"-code";
      json_question = json[d.replace(/-/g, "_")];
      if (json_question && json_question.text){
        tmp = $(selector);
        if (tmp.length > 0){

          tmp.find(".name-variable").html(json_question.text);
          tmp.find(".name-code").html(json_question.original_code);

          ["notes", "weight"].forEach(function (d){
            t = tmp.find(".details-" + d);
            d = (d === "weight" ? "weight_name" : d);
            exist = !!json_question[d];
            if(exist) { t.find("." + d).html(json_question[d]); }
            t.toggle(exist);
          });

          ["group", "subgroup"].forEach(function (d){
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

function build_explore_time_series_page (json){ // build the visualizations for the explore data page

  build_time_series_charts(json);
  build_datatable(json);
  build_details(json);
  build_page_title(json);

  js.explore_tabs.find("li" + (js.explore_tabs.find("li.active:visible").length == 0 ? ":visible:first": ".active" )).trigger("click"); // if no visible tab is marked as active, mark the first one active
}

function get_explore_time_series (is_back_button){ // get data and load page
  if (is_back_button == undefined){
    is_back_button = false;
  }

  // build querystring for url and ajax call-
  var ajax_data = {};
  var url_querystring = [];
  // add options
  ajax_data.time_series_id = gon.time_series_id;
  ajax_data.access_token = gon.app_api_key;
  ajax_data.with_title = true;
  ajax_data.with_chart_data = true;

  params = queryStringToJSON(window.location.href);

  if (is_back_button && params != undefined){
    // add each param that was in the url
    $.map(params, function (v, k){
      ajax_data[k] = v;
      url_querystring.push(l + "=" + v);
    });

  } else{
    tmp = ["select_qc", "select_fb", "select_wb"];
    ["question_code", "filtered_by_code", "weighted_by_code"].forEach(function (d, i){
      v = js[tmp[i]].val();
      if (v !== null && v !== ""){
        ajax_data[d] = v;
        url_querystring.push(d + "=" + v);
      }
    });

    // can exclude
    if (js.input_can_exclude.is(":checked")){
      ajax_data.can_exclude = true;
      url_querystring.push("can_exclude=" + ajax_data.can_exclude);
    }

    // add language param from url query string, if it exists
    if (params.language != undefined){
      ajax_data.language = params.language;
      url_querystring.push("language=" + ajax_data.language);
    }

    // private pages require user id
    if (gon.private_user != undefined){
      ajax_data.private_user_id = gon.private_user;
    }
  }

  // call ajax
  $.ajax({
    type: "GET",
    url: gon.api_time_series_analysis_path,
    data: ajax_data,
    dataType: "json"
  })
  .error(function (jqXHR, textStatus, errorThrown ) {
    console.log( "Request failed: " + textStatus + ". Error thrown: " + errorThrown);
  })
  .success(function (json) {
    if (json.errors){
      js.jumpto_loader.fadeOut("slow");
      js.explore_data_loader.fadeOut("slow");
      js.explore_error.fadeIn("slow");
    }else if ((json.results.analysis && json.results.analysis.length == 0) || (json.results.filtered_analysis && json.results.filtered_analysis.length == 0)){    
      js.jumpto_loader.fadeOut("slow");
      js.explore_data_loader.fadeOut("slow");
      js.explore_no_results.fadeIn("slow");
    }else{
      // update content
      build_explore_time_series_page(json);

      // update url
      var new_url = [location.protocol, "//", location.host, location.pathname, "?", url_querystring.join("&")].join("");

      // change the browser URL to the given link location
      if (!is_back_button && new_url != window.location.href){
        window.history.pushState({path:new_url}, $("title").html(), new_url);
      }

      js.explore_data_loader.fadeOut("slow");
      js.jumpto_loader.fadeOut("slow");
    }


  });
}

function reset_filter_form (){ // reset the filter forms and select a random variable for the row
  js.select_fb.val("").selectpicker("refresh");
  js.input_can_exclude.removeAttr("checked");
}

function build_selects (skip_content) {
  var q = gon.questions,
    html = "",
    type_map = [],
    type_map_index = 0;

  skip_content = (typeof skip_content !== "boolean" ? false : skip_content);
 //console.log(q.items);
  build_options_partial(q.items, null, null);

  function build_options_partial (items, level, parent_id) { // todo
    tmp = "";
    items.forEach(function (item) {
      if(item.hasOwnProperty("parent_id")) { // Group
        tmp = build_selects_group_option(item);
        html += tmp;
        type_map.push([(level === null ? 0 : 1), 0, (level === null ? null : type_map_index)]);

        if(item.hasOwnProperty("subitems") && item.subitems !== null) {
          build_options_partial(item.subitems, (level !== null ? "subgroup" : "group"), type_map_index);
        }
      }
      else if(item.hasOwnProperty("code")){ // Question
        tmp = build_selects_question_option(item, level, skip_content);
        html += tmp;
        type_map.push([2, item.code, parent_id]);
      }
      ++type_map_index;
    });
  }
  var counts = [0, 0], // group cat, num, subgroup cat, num
    cur;
  for(i = type_map.length-1; i >= 0; --i) {
    cur = type_map[i];
    if(cur[0] == 2) {
      ++counts[0];
      ++counts[1];
    }
    else if(cur[0] == 1) {
      cur[1] = counts[1];
      counts[1] = 0;
    }
    else if(cur[0] == 0) {
      cur[1] = counts[0];
      counts[0] = counts[1] = 0;
    }
  }
  return [html, type_map];
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
  return "<option class='"+cls+"' value='"+question.code+"' title='"+q_text+"' "+content+" "+can_exclude+" "+weights+">"+q_text+"</option>";
}

function update_available_weights () { // update the list of avilable weights based on questions that are selected

  if (!js.select_wb.length) { return; }

  var old_value = js.select_wb.val(),
    matches=[],
    items = [
      js.select_qc.find("option:selected").data("weights"),
      js.select_fb.find("option:selected").data("weights")
    ].filter(function (d) { return typeof d !== "undefined"; });

  if(items.length > 0) {
    matches = items.shift().filter(function (v) {
      return items.every(function (a) {
        return a.indexOf(v) !== -1;
      });
    });
  }
  js.select_wb.find("option:not(:last)").hide(); // hide all items except unweighted

  if (matches.length) { // if there are matches, show the weights that match, and unweighted else hide weight option and set value to unweighted
    matches.forEach(function (d) { js.select_wb.find("option[value='" + d + "']").show(); });
    if (matches.indexOf(old_value) === -1) { // if the old value is no longer an option, select the first one
      js.select_wb.selectpicker("val", js.select_wb.find("option:first").attr("value"));
    }
  }
  else{
    js.select_wb.selectpicker("val", "unweighted");
  }

  js.select_wb.selectpicker("refresh");
}

function set_can_exclude_visibility (){ // show or hide the can exclude checkbox
  $("div#can-exclude-container").css("visibility",
    js.select_qc.find("option:selected").data("can-exclude")+"" == "true" ||
    js.select_fb.find("option:selected").data("can-exclude")+"" == "true" ? "visible" : "hidden");
}

function jumpto (show) { // show/hide jumpto show - for main box and if chart is false then map
  js.jumpto.toggle(show);
  js.jumpto_chart.toggle(show);
}

$(document).ready(function () {

  var
    bind = function () {

      // due to using tabs, chart and table cannot be properly drawn
      // because they may be hidden.
      // this event catches when a tab is being shown to make sure
      // the item is properly drawn
      $("a[data-toggle='tab']").on("shown.bs.tab", function () {
        switch($(this).attr("href")) {
        case "#tab-chart":
          $("#container-chart .chart").each(function (){
            $(this).highcharts().reflow();
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
      $("form#form-explore-time-series").submit(function (){
        if (js.select_qc.val() == ""){
          $(".instructions").show();//fadeIn("slow");
          $(".tab-container").addClass("hide");
        }else{
          if ($(".instructions").is(":visible")){
            $(".instructions").hide();//fadeOut("slow");
            $(".tab-container").removeClass("hide");
          }
          js.jumpto_loader.fadeIn("slow");
          js.explore_error.fadeOut("slow");
          js.explore_no_results.fadeOut("slow");
          js.explore_data_loader.fadeIn("slow", function (){
            get_explore_time_series();
          });
        }
        return false;
      });
      // reset the form fields
      $("form#form-explore-time-series input#btn-reset").click(function (e){
        e.preventDefault();
        js.jumpto_loader.fadeIn("slow");
        js.explore_error.fadeOut("slow");
        js.explore_no_results.fadeOut("slow");
        js.explore_data_loader.fadeIn("slow", function (){
          reset_filter_form();
          get_explore_time_series();
        });

      });


      // initalize the fancy select boxes
      $("select.selectpicker").selectpicker();
      $("select.selectpicker-filter").selectpicker();
      $("select.selectpicker-weight").selectpicker();

      // make sure the correct weights are being shown
      update_available_weights();

      // make sure the instructions start at the correct offset to align with the first drop down
      $(".instructions p:first").css("margin-top", ($(".form-explore-question-code").offset().top - $(".content").offset().top) + 5);
      // if option changes, make sure the select option is not available in the other lists
      $("select.selectpicker").change(function (){
        //index = $(this).find("option[value='" + $(this).val() + "']").index();

        // update filter list
        var q = js.select_qc.val();
        var q_index = js.select_qc.find("option[value='" + q + "']").index();
        // if filter is one of these values, reset filter to no filter
        if (js.select_fb.val() == q && q != ""){
          // reset value and hide filter answers
          js.select_fb.selectpicker("val", "");
        }

        js.select_fb.find("option[style*='display: none']").show(); // turn on all hidden items

        if (q !== "" && q_index !== -1){ js.select_fb.find("option[value='"+q+"']").hide(); }

        js.select_fb.selectpicker("refresh");

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

      // get the initial data
      if(js.select_qc.val() !== "")
      {
        // get the initial data
        js.explore_error.fadeOut("slow");
        js.explore_no_results.fadeOut("slow");
        js.explore_data_loader.fadeIn("slow", function (){
          get_explore_time_series();
        });
      }


      // jumpto scrolling
      js.jumpto.on("change", "select", function () {
        js.jumpto.find("button.dropdown-toggle").tooltip("fixTitle");
        js.tab_content.animate({
          scrollTop: js.tab_content.scrollTop() + js.tab_content.find(".tab-pane.active > div > " + $(this).find("option:selected").data("href")).offset().top - js.tab_content.offset().top
        }, 1500);
      });

      // when chart tab clicked on, make sure the jumpto block is showing, else, hide it
      js.explore_tabs.find("li").click(function () {
        var href = $(this).find("a").attr("href");
        if (href == "#tab-chart" && js.jumpto_chart_select.find("option").length > 0){
          jumpto(true);
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
        if (params.question_code != js.select_qc.val()){
          if (params.question_code == undefined){
            js.select_qc.val("");
          }else{
            js.select_qc.val(params.question_code);
          }
          js.select_qc.selectpicker("refresh");
        }

        // filtered by
        if (params.filtered_by_code != js.select_fb.val()){
          if (params.filtered_by_code == undefined){
            js.select_fb.val("");
          }else{
            js.select_fb.val(params.filtered_by_code);
          }
          js.select_fb.selectpicker("refresh");
        }

        // can exclude
        if (params.can_exclude == "true"){
          js.input_can_exclude.attr("checked", "checked");
        }else{
          js.input_can_exclude.removeAttr("checked");
        }

        // reload the data
        js.jumpto_loader.fadeIn("slow");
        js.explore_error.fadeOut("slow");
        js.explore_no_results.fadeOut("slow");
        js.explore_data_loader.fadeIn("slow", function (){
          get_explore_time_series(true);
        });
      });
    },
    init = function () {
      if(!gon.explore_time_series) { return; }
      Highcharts.setOptions({ // set languaage text
        chart: { spacingRight: 30 },
        lang: {
          contextButtonTitle: gon.highcharts_context_title,
          thousandsSep: ","
        },
        colors: ["#00adee", "#e88d42", "#9674a9", "#f3d952", "#6fa187", "#b2a440", "#d95d6a", "#737d91", "#d694e0", "#80b5bc", "#a6c449", "#1b74cc", "#4eccae"],
        credits: { enabled: false }
      });

      js = {
        isFox: /Firefox/.test(navigator.userAgent),
        cache: {},
        chart: $("#container-chart"),
        jumpto: $("#jumpto"),
        select_qc: $("select#question_code"),
        select_fb: $("select#filtered_by_code"),
        select_wb: $("select#weighted_by_code"),
        type: 1,
        tab_content: $(".tab-content"),
        jumpto_loader: $("#jumpto-loader"),
        explore_data_loader: $("#explore-data-loader"),
        explore_error: $("#explore-error"),
        explore_no_results: $("#explore-no-results"),
        explore_tabs: $("#explore-tabs"),
        input_can_exclude: $("input#can_exclude")
      };

      js["jumpto_chart"] = js.jumpto.find("#jumpto-chart");
      js["jumpto_chart_label"] = js.jumpto_chart.find("label span");
      js["jumpto_chart_select"] = js.jumpto_chart.find("select");


      var select_options = build_selects(true);
      select_map = select_options[1];

      js.select_qc.append(select_options[0]);
      js.select_fb.append(select_options[0]);

      function select_options_default (filters) {
        var qc_option = js.select_qc.find("option[value='"+filters[0]+"']");
        if(qc_option.length) {
          qc_option.attr("selected", "selected");
        }
        set_can_exclude_visibility();
        js.select_fb.find("option[value='"+filters[1]+"']").attr("selected", "selected");
        js.select_fb.find("option[value='"+filters[0]+"']").hide();
      }
      select_options_default(gon.questions.filters);

      bind();
    };

  init();
});
