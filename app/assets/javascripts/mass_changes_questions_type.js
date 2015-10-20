/*global  $, gon, console, Highcharts, jQuery, debounce */
/*eslint no-console: 0, no-unused-vars: 0*/
//= require jquery.ui.draggable

$(document).ready(function (){
  var cache = {},// code and all data with grouped_data for each numerical so it will be grouped_data: { "type;size;min;max": grouped data}
    first = true,
    preview_closed = true,
    preview_code = null,
    datatable = null,
    data = {},
    form = $("#mass_change_form"),
    view_chart_path = form.attr("data-view-chart-path"),
    dataset_id = form.attr("data-id"),
    mass_change = $("#mass_change");


  // catch form submit and pull out all form values from the datatable
  // the post will return will a status message
  form.submit( function () {
    var tmpDataKeys = Object.keys(data),
      tmpData = {};

    if(!tmpDataKeys.length) { return; }
    tmpDataKeys.forEach(function (d) {
      tmpData[d.toLowerCase()] = get_code_meta(d);
    });
     //console.log(tmpData);
    //  // get all values and put to tmpData array for question
    $(".data-loader").fadeIn("fast", function (){
      $.ajax({
        type: "POST",
        dataType: "script",
        data: { mass_data: tmpData },
        url: $(this).attr("action"),
        success: function () {
          var tr;
          tmpDataKeys.forEach(function (d) {
            tr = mass_change.find("tr#" + d);
            d = d.toLowerCase();
            tr.find("[name='question["+d+"][data_type]']").attr("data-o", tmpData[d][0]);
            tr.find("[name='question["+d+"][numerical][type]']").attr("data-o", tmpData[d][1]);
            tr.find("[name='question["+d+"][numerical][size]']").attr("data-o", tmpData[d][2]).attr("value", tmpData[d][2]);
            tr.find("[name='question["+d+"][numerical][min]']").attr("data-o", tmpData[d][3]).attr("value", tmpData[d][3]);
            tr.find("[name='question["+d+"][numerical][max]']").attr("data-o", tmpData[d][4]).attr("value", tmpData[d][4]);
          });
          data = {};
        }
      });
    });
    return false;
  });

  // datatable
  datatable = $("#mass_change").dataTable({
    "dom": "<'top'fli>t<'bottom'p><'clear'>",
    "data": gon.datatable_json,
    createdRow: function (row, data, index) {
        row.id = data.code;
        // $(row).attr("data-orig", data.data_type + ";" + data.nm_type + ";" + data.nm_size + ";" + data.nm_min + ";" + data.nm_max);
    },
    "columns": [
      {"data":"code"},
      {"data":"question"},
      {"data":"data_type",
        render: function (data, type, full) {
          return "<input class='numerical' type='radio' value='1' name='question["+full.code +"][data_type]'" + (data == 1 ? " checked": "") + " data-o='"+data+"'>";
        },
        class: "c"
      },
      {"data":"data_type",
        render: function (data, type, full) {
          return "<input class='numerical' type='radio' value='2' name='question["+full.code +"][data_type]'" + (data == 2 ? " checked": "") + " data-o='"+data+"'>";
        },
        class: "c"
      },
      {"data":"nm_type",
        render: function (data, type, full) {
            return "<select class='conditional' name='question["+full.code +"][numerical][type]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + "><option value='0'" + (data == 0 ? "selected": "") + ">Integer</option>" + 
            "<option value='1'" + (data == "1" ? "selected": "") + ">Float</option></select>";
        },
        class: "c"
      },
      {"data":"nm_size",
        render: function (data, type, full){           
          return "<input class='conditional r' type='number' value='"+data+"' name='question["+full.code +"][numerical][size]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + ">";
        }
      },
      {"data":"nm_min",
        render: function (data, type, full){
          return "<input class='conditional r' type='number' value='"+data+"' name='question["+full.code +"][numerical][min]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + ">";
        }        
      },
      {"data":"nm_max",
        render: function (data, type, full){
          return "<input class='conditional r' type='number' value='"+data+"' name='question["+full.code +"][numerical][max]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + ">";
        }
        
      },
      {"data":null, "defaultContent": "<div class='btn btn-default view-chart'>View</div>"}
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

  mass_change.on( "click", "tr", function () {
    if ( $(this).hasClass("selected") ) {
      $(this).removeClass("selected");
    }
    else {
      mass_change.find("tr.selected").removeClass("selected");
      $(this).addClass("selected");
    }
  });

  $(datatable).on("change", "input, select", debounce(function () {
    var t = $(this),
      p = t.closest("tr"),
      id = p.attr("id"),
      orig = t.attr("data-o"),
      newValue = +t.val();
    if(t.hasClass("numerical")) {
      if(newValue === 2) {
        p.find(".conditional").removeAttr("disabled");
      }
      else {
        p.find(".conditional").attr("disabled", "disabled");
      }
    }

    if(orig != newValue)
    {
      if(data.hasOwnProperty("id")) {
        data[id] = ++data;
      }
      else {
        data[id] = 1;
      }
    }
    else {
      if(data.hasOwnProperty("id") && data.id !== 0) {
        data[id] = --data;
      }
      else
      delete data[id];
    }
   
      if(!preview_closed) {
        p.find(".view-chart").trigger("click");
      }
  
  }, 500));

  $(datatable).on("click", ".view-chart", function () {
    var p = $(this).closest("tr"),
      code = p.attr("id"),
      data_type = +p.find("[name='question["+code+"][data_type]']:checked").val(),
      _d = {},
      code_meta = get_code_meta(code).map(function (d){ return d=+d; }),
      sub_id = code_meta.join(";");
      code_meta.push((code_meta[4] - code_meta[3])/code_meta[2]);

    if(data_type === 2) {
      if(cache.hasOwnProperty(code)) {
        var cached_code = cache[code];
        if(cached_code.grouped_data.hasOwnProperty(sub_id))
        {
          console.log("data for sub_id", sub_id);
        }
        else {
          console.log("no data for", sub_id);
          cached_code.grouped_data[sub_id] = get_grouped_data(code_meta, cached_code.data);
        }
        _d = { meta: code_meta, data: cached_code.grouped_data[sub_id] };
        render_chart();
      }
      else {
        $.ajax({
          type: "GET",
          dataType: "json",
          data: { dataset_id: dataset_id, question_code: $(this).closest("tr").attr("id") },
          url: view_chart_path,
          success: function (d) {
            cache[code] = d;
            var tmpA = [],
              gr = cache[code].grouped_data;
            if(typeof gr !== "undefined" && gr !== null) {
              tmpA = gr.slice();
            }
            else {
              tmpA = get_grouped_data(code_meta, cache[code].data);
            }
            gr = {};
            gr[sub_id] = tmpA;
            _d = { meta: code_meta, data: tmpA };
            render_chart();
          }
        });
      }
    }
    else {
      console.log("Bar chart");
    }

    function render_chart () {
      console.log("render chart");
      var newCode = false;
      if(preview_code !== code) {
        newCode = true;
        preview_code = code;
      }
       console.log(_d);
      preview(_d.meta, _d.data, newCode);
    }
  });

  $("body").append("<div id='preview' class='preview'><div class='header'><div class='move'></div><div class='close'></div></div><div class='chart'></div></div>");
  $("#preview").draggable({ handle: ".header > .move", cursor: "move" });
  $("#preview .close" ).click(function () {
    var t = $(this),
      p = t.closest("#preview");
    p.hide();
    p.find(".chart").highcharts().destroy();
    preview_closed = true;
  });

  var preview = function (meta, data, newCode) {
     console.log(meta);

    var t = $("#preview"), chart, sum = data.reduce(function(a, b){return a+b;});
    t.show();

    if(preview_closed || newCode) {
      chart = new Highcharts.Chart({
        chart: {
          renderTo: $("#preview .chart")[0],
          type: "column",
          spacingRight: 40
        },
        credits: { enabled: false },
        xAxis: {
          labels: {
            align: "right",
            x:-10
          },
          startOnTick: true,
          endOnTick: true,
          categories: formatLabel(meta)
        },
        plotOptions: {
          column: {
            groupPadding: 0,
            pointPadding: 0,
            borderWidth: 0
          }
        },
        series: [{
          data: data
        }],
        tooltip: {
          formatter: function () {
            return this.y + " (" + Math.round10(this.y*100/sum, -2) + "%)";
          }
        }
      }, function () {
        var box = this.plotBox;
        var label = this.renderer.label(meta[4], (box.x+box.width) - 7, (box.y + box.height) + 5)
          .css({
            color:"#606060",
            cursor:"default",
            "font-size":"11px",
            "fill":"#606060"
          }).attr("class", "histogramm-last-label")
          .add();
        this.spacing[1] = label.width + 10 > 40 ? label.width + 10 : 40;
        this.isDirtyBox = true;
        this.redraw();
        label.xSetter((box.x+box.width) - 7);
        if(first) {
          t.css({top: $(window).height() - t.height() - 10 });
          first = false;
        }
      });
    }
    else {
      chart = $("#preview .chart").highcharts();
      chart.xAxis[0].setCategories(formatLabel(meta), true, true);
      chart.series[0].setData(data, false, true);
      $("#preview .chart .histogramm-last-label").remove();
      var box = chart.plotBox;
      var label = chart.renderer.label(meta[4], (box.x+box.width) - 7, (box.y + box.height) + 5)
        .css({
          color:"#606060",
          cursor:"default",
          "font-size":"11px",
          "fill":"#606060"
        }).attr("class", "histogramm-last-label")
        .add();
      chart.spacing[1] = label.width + 10 > 40 ? label.width + 10 : 40;
      chart.isDirtyBox = true;
      chart.redraw();
      label.xSetter((box.x+box.width) - 7);
      console.log("old chart", label );
    }

    if(preview_closed) {
      preview_closed = false;
    }

    function formatLabel (meta) {
      var v = [];
      for(var i = 0; i < meta[2]; ++i) {
        v.push(Math.round(meta[3]+i*meta[5]));
      }
      return v;
    }
  };
  function get_grouped_data (meta, raw_data) {
    var grouped_data = replicate (meta[2], 0);
    if (Array.isArray(raw_data)) {

      raw_data.forEach(function (raw_d) {
        var d = raw_d;
        if(isN(d)) {
          if(meta[1] == 0) {
            d = parseInt(d);
          }
          else if(meta[1] == 1) {
            d = parseFloat(d);
          }

          if(d >= meta[3] && d <= meta[4]) {
            grouped_data[Math.floor((d-meta[3])/meta[5])] += 1;
          }
        }
      });
    }
    return grouped_data;
  }
  function get_code_meta (code) {
    var tr = mass_change.find("tr#" + code),
      tmp = "[name='question["+code+"][numerical]";
    return [ tr.find("[name='question["+code+"][data_type]']:checked").val(),
        tr.find(tmp + "[type]']").val(),
        tr.find(tmp + "[size]']").val(),
        tr.find(tmp + "[min]']").val(),
        tr.find(tmp + "[max]']").val() ].map(function (d){ return d=+d; });
  }
  function is_numerical (code) {
    return $("#mass_change tr [name='question["+code+"][data_type]']:checked").val() === 2;
  }

  function replicate (n, x) {
    var xs = [];
    for (var i = 0; i < n; ++i) {
      xs.push (x);
    }
    return xs;
  }
  var isN = function (obj) {
    return !jQuery.isArray( obj ) && (obj - parseFloat( obj ) + 1) >= 0;
  };
});



  // gon.datatable_json.forEach(function (d, i) {
  //   if(typeof d.data_type === "undefined") {
  //     console.log(d.code);
  //   }
  // });
  // /* Create an array with the values of all the checkboxes in a column */
  // // take from: http://www.datatables.net/examples/plug-ins/dom_sort.html
  // $.fn.dataTable.ext.order["dom-checkbox"] = function (settings, col)
  // {
  //   return this.api().column( col, {order:"index"} ).nodes().map( function (td) {
  //     return $("input[type='checkbox']", td).prop("checked") ? "1" : "0";
  //   });
  // };
  // 
    // update tooltip for disabled inputs in table
  // $("#mass_change tbody tr td input[disabled='disabled']").tooltip({
  //   selector: "[title]",
  //   container: "body"
  // });

    // if data-state = all, select all questions that match the current filter
  // - if not filter -> then all questions are selected
  // else, desfelect all questions that match the current filter
  // - if not filter -> then all questions are deselected
  // $("a.btn-select-all").click(function (){
  //   var t = $(this),
  //     state_all = t.attr("data-state") == "all",
  //     type = t.attr("data-type");

  //   $(datatable.$("tr", {"filter": "applied"}))
  //     .find("td input[type='checkbox']." + type + "-input")
  //     .prop("checked", state_all).trigger("change");

  //   t.attr("data-state", state_all ? "none" : "all" );
  //   return false;
  // });

// Closure
(function() {
  /**
   * Decimal adjustment of a number.
   *
   * @param {String}  type  The type of adjustment.
   * @param {Number}  value The number.
   * @param {Integer} exp   The exponent (the 10 logarithm of the adjustment base).
   * @returns {Number} The adjusted value.
   */
  function decimalAdjust(type, value, exp) {
    // If the exp is undefined or zero...
    if (typeof exp === 'undefined' || +exp === 0) {
      return Math[type](value);
    }
    value = +value;
    exp = +exp;
    // If the value is not a number or the exp is not an integer...
    if (isNaN(value) || !(typeof exp === 'number' && exp % 1 === 0)) {
      return NaN;
    }
    // Shift
    value = value.toString().split('e');
    value = Math[type](+(value[0] + 'e' + (value[1] ? (+value[1] - exp) : -exp)));
    // Shift back
    value = value.toString().split('e');
    return +(value[0] + 'e' + (value[1] ? (+value[1] + exp) : exp));
  }

  // Decimal round
  if (!Math.round10) {
    Math.round10 = function(value, exp) {
      return decimalAdjust('round', value, exp);
    };
  }
  // Decimal floor
  if (!Math.floor10) {
    Math.floor10 = function(value, exp) {
      return decimalAdjust('floor', value, exp);
    };
  }
  // Decimal ceil
  if (!Math.ceil10) {
    Math.ceil10 = function(value, exp) {
      return decimalAdjust('ceil', value, exp);
    };
  }
})();