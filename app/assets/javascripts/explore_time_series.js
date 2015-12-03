/*global  $, gon, Highcharts, params, console, queryStringToJSON, TableTools, time_series_chart_height, build_time_series_chart, build_page_title */
/*eslint no-undef: 0, no-console: 0  */
var datatables, i, j;

function build_time_series_charts (json){ // build time series line chart for each chart item in json
  if (json.chart){
    // determine chart height
    var chart_height = time_series_chart_height(json);

    // remove all existing charts
    $("#container-chart").empty();
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

function build_datatable (json){ // build data table
  // set the title
  $("#container-table h3").html(json.results.title.html + json.results.subtitle.html);

  // if the datatable alread exists, kill it
  if (datatables != undefined && datatables.length > 0){
    for (var i=0;i<datatables.length;i++){
      datatables[i].fnDestroy();
    }
  }

  var col_headers = ["count", "percent"];

  // test if data is weighted so can build table accordingly
  if (json.weighted_by != undefined){
    col_headers = ["unweighted-count", "weighted-count", "weighted-percent"];
  }
  var col_header_count = col_headers.length;

  // build the table
  var table = "", ln;

  // test if the filter is being used and build the table accordingly
  if (json.filtered_by == undefined){
    // build head
    table += "<thead>";
    // 2 headers of:
    //                dataset label
    // question   count percent count percent .....
    table += "<tr class='th-center'>";
    table += "<th class='var1-col-red'>" + gon.table_questions_header + "</th>";

    ln = json.datasets.length;
    for(i=0; i<ln;i++){
      table += "<th colspan='" + col_header_count + "' class='code-highlight color"+(i % 13 + 1)+"'>";
      table += json.datasets[i].label;
      table += "</th>";
    }
    table += "</tr>";
    table += "<tr>";
    table += "<th class='var1-col code-highlight'>";
    table += json.question.original_code;
    table += "</th>";
    for(i=0; i<json.datasets.length;i++){
      for(j=0; j<col_header_count;j++){
        table += "<th>";
        table += $("#container-table table").data(col_headers[j]);
        table += "</th>";
      }
    }
    table += "</tr>";
    table += "</thead>";

    // build body
    table += "<tbody>";
    // cells per row: row answer, count/percent for each col
    for(i=0; i<json.results.analysis.length; i++){
      table += "<tr>";
      table += "<td class='var1-col' data-order='" + json.question.answers[i].sort_order + "'>";
      table += json.results.analysis[i].answer_text;
      table += "</td>";
      for(j=0; j<json.results.analysis[i].dataset_results.length; j++){
        for(var k=0; k<col_header_count;k++){
          // key is written with "-" but for this part, it must be "_"
          var key_text = col_headers[k].replace("-", "_");
          // percent is the last item and all items before are percent
          if (k < col_header_count-1){
            table += "<td data-order='" + json.results.analysis[i].dataset_results[j][key_text] + "'>";
            if (json.results.analysis[i].dataset_results[j][key_text]){
              table += Highcharts.numberFormat(json.results.analysis[i].dataset_results[j][key_text], 0);
            }
            table += "</td>";
          }else{
            table += "<td>";
            if (json.results.analysis[i].dataset_results[j][key_text]){
              table += json.results.analysis[i].dataset_results[j][key_text].toFixed(2);
              table += "%";
            }
            table += "</td>";
          }
        }
      }
    }

    table += "</tbody>";

  }else{

    // build head
    table += "<thead>";
    // 2 headers of:
    //                dataset label
    // filter   question   count percent count percent .....
    table += "<tr class='th-center'>";
    table += "<th class='var1-col-red' colspan='2'>" + gon.table_questions_header + "</th>";
    ln = json.datasets.length;
    for(i=0; i<ln;i++){
      table += "<th colspan='" + col_header_count + "' class='code-highlight color"+(i % 13 + 1)+"'>";
      table += json.datasets[i].label;
      table += "</th>";
    }
    table += "</tr>";

    table += "<tr>";
    table += "<th class='var1-col code-highlight'>";
    table += json.filtered_by.original_code;
    table += "</th>";
    table += "<th class='var1-col code-highlight'>";
    table += json.question.original_code;
    table += "</th>";
    for(i=0; i<json.datasets.length;i++){
      for(j=0; j<col_header_count;j++){
        table += "<th>";
        table += $("#container-table table").data(col_headers[j]);
        table += "</th>";
      }
    }
    table += "</tr>";
    table += "</thead>";

    // build body
    table += "<tbody>";
    // for each filter, show each question and the count/percents for each dataset
    for(var h=0; h<json.results.filter_analysis.length; h++){

      for(i=0; i<json.results.filter_analysis[h].filter_results.analysis.length; i++){
        table += "<tr>";
        table += "<td class='var1-col' data-order='" + json.filtered_by.answers[h].sort_order + "'>";
        table += json.results.filter_analysis[h].filter_answer_text;
        table += "</td>";
        table += "<td class='var1-col' data-order='" + json.question.answers[i].sort_order + "'>";
        table += json.results.filter_analysis[h].filter_results.analysis[i].answer_text;
        table += "</td>";
        for(j=0; j<json.results.filter_analysis[h].filter_results.analysis[i].dataset_results.length; j++){
          for(k=0; k<col_header_count;k++){
            // key is written with '-' but for this part, it must be '_'
            key_text = col_headers[k].replace("-", "_");
            // percent is the last item and all items before are percent
            if (k < col_header_count-1){
              table += "<td data-order='" + json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j][key_text] + "'>";
              if (json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j][key_text]){
                table += Highcharts.numberFormat(json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j][key_text], 0);
              }
              table += "</td>";
            }else{
              table += "<td>";
              if (json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j][key_text]){
                table += json.results.filter_analysis[h].filter_results.analysis[i].dataset_results[j][key_text].toFixed(2);
                table += "%";
              }
              table += "</td>";
            }
          }
        }
        table += "</tr>";
      }
    }
    table += "</tbody>";
  }


  // add the table to the page
  $("#container-table table").html(table);

  //initalize the datatable
  datatables = [];
  $("#container-table table").each(function (){
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

function build_details (json) { // build details (question and possible answers)

  var details_item = $("#tab-details .details-item").hide(); // clear out existing content and hide
  details_item.find(".name-group .group-title, .name-group .group-description, .name-subgroup .group-title, .name-subgroup .group-description, .name-variable, .name-code, .notes, .list-answers").empty();

  build_details_item(json);

  function build_details_item (json) { // populat a details item block
    var selector = "", json_question = undefined, t, exist, tmp, icon, is_categorical;
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

  var explore_tabs = $("#explore-tabs");
  // if no visible tab is marked as active, mark the first one active
  explore_tabs.find("li" +
    (explore_tabs.find("li.active:visible").length == 0 ? ":visible:first": ".active" )
  ).trigger("click");
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

    // question code
    if ($("select#question_code").val() != null && $("select#question_code").val() != ""){
      ajax_data.question_code = $("select#question_code").val();
      url_querystring.push("question_code=" + ajax_data.question_code);
    }

    // filtered by
    if ($("select#filtered_by_code").val() != null && $("select#filtered_by_code").val() != ""){
      ajax_data.filtered_by_code = $("select#filtered_by_code").val();
      url_querystring.push("filtered_by_code=" + ajax_data.filtered_by_code);
    }

    // weighted by
    if ($("select#weighted_by_code").val() != null && $("select#weighted_by_code").val() != ""){
      ajax_data.weighted_by_code = $("select#weighted_by_code").val();
      url_querystring.push("weighted_by_code=" + ajax_data.weighted_by_code);
    }

    // can exclude
    if ($("input#can_exclude").is(":checked")){
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
      $("#jumpto-loader").fadeOut("slow");
      $("#explore-data-loader").fadeOut("slow");
      $("#explore-error").fadeIn("slow");
    }else if ((json.results.analysis && json.results.analysis.length == 0) || (json.results.filtered_analysis && json.results.filtered_analysis.length == 0)){    
      $("#jumpto-loader").fadeOut("slow");
      $("#explore-data-loader").fadeOut("slow");
      $("#explore-no-results").fadeIn("slow");
    }else{
      // update content
      build_explore_time_series_page(json);

      // update url
      var new_url = [location.protocol, "//", location.host, location.pathname, "?", url_querystring.join("&")].join("");

      // change the browser URL to the given link location
      if (!is_back_button && new_url != window.location.href){
        window.history.pushState({path:new_url}, $("title").html(), new_url);
      }

      $("#explore-data-loader").fadeOut("slow");
      $("#jumpto-loader").fadeOut("slow");
    }
  });
}

function reset_filter_form (){ // reset the filter forms and select a random variable for the row
  $("select#filtered_by_code").val("").selectpicker("refresh");
  $("input#can_exclude").removeAttr("checked");
}

function update_available_weights () { // update the list of avilable weights based on questions that are selected
  var select_weight = $("select#weighted_by_code"),
    dropdown_weight = $(".form-explore-weight-by .bootstrap-select ul.dropdown-menu");

  if (!select_weight.length) { return; }

  var old_value = select_weight.val(),
    matches=[],
    items = [
      $("select#question_code option:selected").data("weights"),
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
    matches.forEach(function (d) {
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
    select_weight.selectpicker("val", "unweighted");
  }
}

function set_can_exclude_visibility (){ // show or hide the can exclude checkbox
  if ($("select#question_code option:selected").data("can-exclude") == true ||
      $("select#filtered_by_code option:selected").data("can-exclude") == true){

    $("div#can-exclude-container").css("visibility", "visible");
  }else{
    $("div#can-exclude-container").css("visibility", "hidden");
  }
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
        if ($("select#question_code").val() == ""){
          $(".instructions").show();//fadeIn("slow");
          $(".tab-container").addClass("hide");
        }else{
          if ($(".instructions").is(":visible")){
            $(".instructions").hide();//fadeOut("slow");
            $(".tab-container").removeClass("hide");
          }
          $("#jumpto-loader").fadeIn("slow");
          $("#explore-error").fadeOut("slow");
          $("#explore-no-results").fadeOut("slow");
          $("#explore-data-loader").fadeIn("slow", function (){
            get_explore_time_series();
          });
        }
        return false;
      });
      // reset the form fields
      $("form#form-explore-time-series input#btn-reset").click(function (e){
        e.preventDefault();
        $("#jumpto-loader").fadeIn("slow");
        $("#explore-error").fadeOut("slow");
        $("#explore-no-results").fadeOut("slow");
        $("#explore-data-loader").fadeIn("slow", function (){
          reset_filter_form();
          get_explore_time_series();
        });

      });


      // initalize the fancy select boxes
      $("select.selectpicker").selectpicker();
      $("select.selectpicker-filter").selectpicker();
      $("select.selectpicker-weight").selectpicker();

      // if an option has data-disabled when page loads, make sure it is hidden in the selectpicker
      $("select#question_code option[data-disabled='disabled']").each(function (){
        $(".form-explore-question-code .bootstrap-select ul.dropdown-menu li:eq(" + $(this).index() + ")").hide();
      });
      $("select#filtered_by_code option[data-disabled='disabled']").each(function (){
        $(".form-explore-filter-by .bootstrap-select ul.dropdown-menu li:eq(" + $(this).index() + ")").hide();
      });

      // make sure the correct weights are being shown
      update_available_weights();

      // make sure the instructions start at the correct offset to align with the first drop down
      $(".instructions p:first").css("margin-top", ($(".form-explore-question-code").offset().top - $(".content").offset().top) + 5);

      // if option changes, make sure the select option is not available in the other lists
      $("select.selectpicker").change(function (){
        //index = $(this).find("option[value='" + $(this).val() + "']").index();

        // update filter list
        var q = $("select#question_code").val();
        var q_index = $("select#question_code option[value='" + q + "']").index();
        // if filter is one of these values, reset filter to no filter
        if ($("select#filtered_by_code").val() == q && q != ""){
          // reset value and hide filter answers
          $("select#filtered_by_code").selectpicker("val", "");
        }

        // turn on all hidden items
        $(".form-explore-filter-by .bootstrap-select ul.dropdown-menu li[style*='display: none']").show();

        // turn off this item
        if (q != "" && q_index != -1){
          $(".form-explore-filter-by .bootstrap-select ul.dropdown-menu li:eq(" + (q_index) + ")").hide();
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

      // get the initial data
      if($("select#question_code").val() !== "")
      {
        // get the initial data
        $("#explore-error").fadeOut("slow");
        $("#explore-no-results").fadeOut("slow");
        $("#explore-data-loader").fadeIn("slow", function (){
          get_explore_time_series();
        });
      }


      // jumpto scrolling
      $("#jumpto").on("change", "select", function () {
        $("#jumpto button.dropdown-toggle").tooltip("fixTitle");
        js.tab_content.animate({
          scrollTop: js.tab_content.scrollTop() + js.tab_content.find(".tab-pane.active > div > " + $(this).find("option:selected").data("href")).offset().top - js.tab_content.offset().top
        }, 1500);
      });

      // when chart tab clicked on, make sure the jumpto block is showing, else, hide it
      $("#explore-tabs li").click(function () {
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
        if (params.question_code != $("select#question_code").val()){
          if (params.question_code == undefined){
            $("select#question_code").val("");
          }else{
            $("select#question_code").val(params.question_code);
          }
          $("select#question_code").selectpicker("refresh");
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
        $("#explore-data-loader").fadeIn("slow", function (){
          get_explore_time_series(true);
        });
      });
    },
    init = function () {
      if(!gon.explore_time_series) { return; }
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
        select_qc: $("select#question_code"),
        select_fb: $("select#filtered_by_code"),
        select_wb: $("select#weighted_by_code"),
        type: 1,
        tab_content: $(".tab-content")
      };

      js["jumpto_chart"] = js.jumpto.find("#jumpto-chart");
      js["jumpto_chart_label"] = js.jumpto_chart.find("label span");
      js["jumpto_chart_select"] = js.jumpto_chart.find("select");

      bind();
    };

  init();
});