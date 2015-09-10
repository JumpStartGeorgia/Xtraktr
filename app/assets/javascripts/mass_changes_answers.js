/*global  $, gon*/
$(document).ready(function (){

  /* Create an array with the values of all the checkboxes in a column */
  // take from: http://www.datatables.net/examples/plug-ins/dom_sort.html
  $.fn.dataTable.ext.order["dom-checkbox"] = function ( settings, col )
  {
    return this.api().column( col, {order:"index"} ).nodes().map( function (td) {
      return $("input[type='checkbox']", td).prop("checked") ? "1" : "0";
    });
  };
  var datatable = null;
  // catch form submit and pull out all form values from the datatable
  // the post will return will a status message
  $("form#frm-exclude-answers").submit( function () {
    $(".data-loader").fadeIn("fast", function (){
      $.ajax({
        type: "POST",
        dataType: "script",
        data: data,//datatable.$("input").serialize(),
        url: $(this).attr("action")
      });
    });

    return false;
  });

  // datatable
  var columns = [];
  if ($("form#frm-exclude-answers").hasClass("form-dataset")){
    columns = [
      {"data":"code"},
      {"data":"question", "width":"33%"},
      {"data":"answer", "width":"33%"},
      {"data":"exclude", "orderDataType": "dom-checkbox"},
      {"data":"can_exclude", "orderDataType": "dom-checkbox"}
    ];
  }else if ($("form#frm-exclude-answers").hasClass("form-time-series")){
    columns = [
      {"data":"code"},
      {"data":"question", "width":"33%"},
      {"data":"answer", "width":"33%"},
      {"data":"can_exclude", "orderDataType": "dom-checkbox"}
    ];
  }

  if (columns.length > 1){
    datatable = $("#exclude-answers").dataTable({
      "dom": "<'top'fli>t<'bottom'p><'clear'>",
      "data": gon.datatable_json,
      "columns": columns,
      "sorting": [],
      // "order": [[0, "asc"]],
      "language": {
        "url": gon.datatable_i18n_url,
        "searchPlaceholder": gon.datatable_search
      },
      "pagingType": "full_numbers",
      "orderClasses": false
    });
  }
  var data = { exclude:{}, can_exclude:{} };
  $(datatable.$("tr", {"filter": "applied"})).on("change", "input", function () {
    var t = $(this),
      type = t.hasClass("exclude-input") ? "exclude" : "can_exclude",
      id = t.attr("data-id"),
      orig = t.attr("data-orig") == "true",
      newValue = t.prop("checked");
       // console.log(id);
    if(orig != newValue) {
      data[type][id] = newValue;
    }
    else {
      delete data[type][id];
    }
   // console.log(Object.keys(data.exclude).length);
   // console.log(Object.keys(data.can_exclude).length);
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
