/*global  $, gon*/
$(document).ready(function (){

  var datatable = null,
    checkboxs = ["exclude", "download"],
    data = { exclude:{}, download:{}};

  /* Create an array with the values of all the checkboxes in a column */
  // take from: http://www.datatables.net/examples/plug-ins/dom_sort.html
  $.fn.dataTable.ext.order["dom-checkbox"] = function (settings, col)
  {
    return this.api().column( col, {order:"index"} ).nodes().map( function (td) {
      return $("input[type='checkbox']", td).prop("checked") ? "1" : "0";
    });
  };

  // catch form submit and pull out all form values from the datatable
  // the post will return will a status message
  $("form#frm-dataset-exclude-questions").submit( function () {
    var tmpData = {};
    checkboxs.forEach(function (checkbox) {
      tmpData[checkbox] = Object.keys(data[checkbox]);
    });
    $(".data-loader").fadeIn("fast", function (){
      $.ajax({
        type: "POST",
        dataType: "script",
        data: tmpData,
        url: $(this).attr("action"),
        success: function () {
          checkboxs.forEach(function (checkbox) {
            tmpData[checkbox].forEach(function (d){
              datatable.find("input." + checkbox + "-input[data-id="+d+"]").attr("data-orig", data[checkbox][d]);
            });
            data[checkbox] = {};
          });
        }
      });
    });

    return false;
  });


  // datatable
  datatable = $("#dataset-exclude-questions").dataTable({
    "dom": "<'top'fli>t<'bottom'p><'clear'>",
    "data": gon.datatable_json,
    "columns": [
      {"data":"code"},
      {"data":"text", "width":"40%"},
      {"data":"exclude", "orderDataType": "dom-checkbox"},
      {"data":"download", "orderDataType": "dom-checkbox"}
    ],
    "sorting": [],
    // "order": [[0, "asc"]],
    "language": {
      "url": gon.datatable_i18n_url,
      "searchPlaceholder": gon.datatable_search
    },
    "pagingType": "full_numbers",
    "orderClasses": false
  });

  // update tooltip for disabled inputs in table
  // $("#dataset-exclude-questions tbody tr td input[disabled="disabled"]").tooltip("fixTitle");
  $("#dataset-exclude-questions tbody tr td input[disabled='disabled']").tooltip({
    selector: "[title]",
    container: "body"
  });



  $(datatable).on("change", "input", function () {
    var t = $(this),
      type = null,
      id = t.attr("data-id"),
      orig = t.attr("data-orig") == "true",
      newValue = t.prop("checked");

    checkboxs.forEach(function (d){
      if(t.hasClass(d + "-input")) {
        type = d;
      }
    });
    if(type == null) return;
       // console.log(id);
    if(orig != newValue) {
      data[type][id] = newValue;
    }
    else {
      delete data[type][id];
    }
  });

  // if data-state = all, select all questions that match the current filter
  // - if not filter -> then all questions are selected
  // else, desfelect all questions that match the current filter
  // - if not filter -> then all questions are deselected
  $("a.btn-select-all").click(function (){
    var t = $(this),
      state_all = t.attr("data-state") == "all",
      type = t.attr("data-type");

    $(datatable.$("tr", {"filter": "applied"}))
      .find("td input[type='checkbox']." + type + "-input")
      .prop("checked", state_all).trigger("change");

    t.attr("data-state", state_all ? "none" : "all" );
    return false;
  });

});
