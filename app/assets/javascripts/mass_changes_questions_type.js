/*global  $, gon, console, Highcharts, jQuery, debounce, isN, replicate */
/*eslint no-console: 0, no-unused-vars: 0*/
//= require jquery.ui.draggable

$(document).ready(function (){
  var cache = {},// code and all data with frequency_data for each numerical so it will be frequency_data: { "type;size;min;max": grouped data}
    first = true,
    datatable = null,
    dirty_rows = { },
    form = $("#mass_change_form"),
    view_chart_path = form.attr("data-view-chart-path"),
    dataset_id = form.attr("data-id"),
    mass_change = $("#mass_change"),
    preview = {
      closed: true,
      code: null,
      selector: null,
      init: function () {
        $("body").append("<div id='preview' class='preview'><div class='header'><div class='move'></div><div class='close'></div></div><div class='chart'></div></div>");
        this.selector = $("#preview");
        this.bind();
      },
      bind: function () {
        this.selector.draggable({ handle: ".header > .move", cursor: "move" });

        this.selector.find(".close" ).click(function () {
          var t = $(this),
            p = t.closest("#preview");
          p.hide();
          p.find(".chart").highcharts().destroy();
          this.closed = true;
        });
      },
      show: function (code, only_if_opened) {
        if(typeof only_if_opened !== "boolean") { only_if_opened = false; }
        if(only_if_opened && this.closed) { return; }

        this.prepaire_data(code);
      },
      chart: function (type, meta, data, newCode) {
        
        var histogramm = function () {
          var t = $("#preview"), chart, sum = data.reduce(function (a, b){return a+b;});
          t.show();

          if(this.closed || newCode) {
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

          if(this.closed) {
            this.closed = false;
          }

          function formatLabel (meta) {
            var v = [];
            for(var i = 0; i < meta[2]; ++i) {
              v.push(Math.round(meta[3]+i*meta[5]));
            }
            return v;
          }
        },
        bar = function () {};

        if(type == "histogramm") {
          histogramm();
        } else if(type == "bar") {
          bar();
        }
      },    
      prepaire_data: function (code) {
        var t = this;
        var _d = {},
          meta = get_code_meta(code),
          code_meta = meta.data,
          data_type = code_meta[0],
          sub_id = code_meta.join(";");

        
        if(data_type === 1) {
          console.log("Bar chart");

          if(cache.hasOwnProperty(code) && cache[code].hasOwnProperty("frequency_data") && cache[code].frequency_data.hasOwnProperty(sub_id)) {
            var cc = cache[code];
            if(!cc.data.hasOwnProperty(sub_id)) // 
            {
              cc.data[sub_id] = cc.data;
            }
            _d = { meta: code_meta, data: cc.data[sub_id] };
            render_chart();
          }
          else {
            $.ajax({
              type: "GET",
              dataType: "json",
              data: { dataset_id: dataset_id, question_code: code },
              url: view_chart_path,
              success: function (d) {
                cache[code] = d;
                var tmpA = [],
                  fr = cache[code].frequency_data;

                if(typeof fr !== "undefined" && fr !== null) {
                  tmpA = fr.slice();
                  fr = {};
                  fr[sub_id] = tmpA;
                  _d = { meta: code_meta, data: tmpA };
                  render_chart();
                }                
              }
            });
          }
        }
        else if(data_type === 2) {
          code_meta.push((code_meta[4] - code_meta[3])/code_meta[2]);
          if(cache.hasOwnProperty(code)) {
            var cached_code = cache[code];
            if(cached_code.frequency_data.hasOwnProperty(sub_id))
            {
              console.log("data for sub_id", sub_id);
            }
            else {
              console.log("no data for", sub_id);
              cached_code.frequency_data[sub_id] = get_frequency_data(code_meta, cached_code.data);
            }
            _d = { meta: code_meta, data: cached_code.frequency_data[sub_id] };
            render_chart();
          }
          else {
            $.ajax({
              type: "GET",
              dataType: "json",
              data: { dataset_id: dataset_id, question_code: code },
              url: view_chart_path,
              success: function (d) {
                console.log(d);
                cache[code] = d;
                var tmpA = [],
                  gr = cache[code].frequency_data;
                   console.log(gr);
                if(typeof gr !== "undefined" && gr !== null) {
                  tmpA = gr.slice();
                }
                else {
                  tmpA = get_frequency_data(code_meta, cache[code].data);
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
          console.log("Message no data-type");
        }

        function render_chart () {
          var nc = false; // if code is new
          if(preview.code !== code) {
            nc = true;
            preview.code = code;
          }          
          t.chart((data_type == 1 ? "bar" : "histogramm"), _d.meta, _d.data, nc);
        }
        function get_frequency_data (meta, raw_data) {
          var frequency_data = replicate(meta[2], 0);
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
                  frequency_data[Math.floor((d-meta[3])/meta[5])] += 1;
                }
              }
            });
          }
          return frequency_data;
        }
      }
    };

  function init () {
    init_datatable();
    init_binds();
    preview.init();
    init_locale_picker();
  }
  function init_datatable () {
    datatable = $("#mass_change").dataTable({
      "dom": "<'top'fli>t<'bottom'p><'clear'>",
      "data": gon.datatable_json,
      createdRow: function (row, data, index) {
        row.id = data.code;
      },
      "columns": [
        {"data":null, "defaultContent": "<div class='btn btn-default view-chart'>View</div>"},
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
        {"data":"nm_title",
          render: function (data, type, full) {
            return "<div class='conditional locale-box' name='question["+full.code +"][numerical][title]' data-o='' "+(full.data_type !== 2 ? " disabled" : "")+">"+
            "<div class='locale-picker' "+(full.data_type !== 2 ? " disabled" : "")+"><div class='locale-toggle' title='"+gon.locale_picker_data[data[0][0]]+"'>"+data[0][0]+"</div><ul>" +
            data.map(function (d, i) { return "<li class='"+[(i+1>6 ? "btop" : ""), (data.length > 5 && i+1 > data.length-data.length%6 ? "bbottom" : "")].join(" ") +"' data-key='"+d[0]+"' data-value='"+d[1]+"' data-orig-value='"+d[1]+"' title='"+gon.locale_picker_data[d[0]]+"'>" + d[0] + "</li>"; }).join("") +
            "<li class='reset' title='"+gon.locale_picker_data.reset+"'></li></ul></div>" +
            "<input type='text' class='title' value='"+data[0][1]+
            "' data-locale='"+ data[0][0] +"'" + (full.data_type !== 2 ? " disabled" : "") + "></div>";
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
          render: function (data, type, full) {
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
        }
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
  }
  function init_binds () {

    form.submit( function () {
      var keys = Object.keys(dirty_rows),
        current_data = {};

      if(!keys.length) { return; }

      keys.forEach(function (d) {
        current_data[d.toLowerCase()] = get_code_meta(d);
      });

      $(".data-loader").fadeIn("fast", function (){
        $.ajax({
          type: "POST",
          dataType: "script",
          data: { mass_data: current_data },
          url: $(this).attr("action"),
          success: function () {
            keys.forEach(function (d) {
              set_code_original_values(d.loLowerCase());
            });
            dirty_rows = {};
          }
        });
      });
      var tr;
      function set_code_original_values (d) {
        tr = mass_change.find("tr#" + d);
        var str = "[name='question["+d+"]",
          dao = "data-o";

        tr.find(str+"[data_type]']").attr("data-o", current_data[d][0]);
        str += "[numerical]";

        tr.find(str+"[type]']").attr(dao, current_data[d][1]);
        tr.find(str+"[size]']").attr(dao, current_data[d][2]).attr("value", current_data[d][2]);
        tr.find(str+"[min]']").attr(dao, current_data[d][3]).attr("value", current_data[d][3]);
        tr.find(str+"[max]']").attr(dao, current_data[d][4]).attr("value", current_data[d][4]);
      }
      return false;
    });

    $(datatable).on("click", "tr", function () {
      var t = $(this);
      if (!t.hasClass("selected")) {
        mass_change.find("tr.selected").removeClass("selected");
      }
      t.toggleClass("selected");
    });

    $(datatable).on("click", ".view-chart", function () { //debounce(, 500)
      preview.show($(this).closest("tr").attr("id"));
    });

    $(datatable).on("change", "input, select", function () {
      var t = $(this),
        td = t.closest("td"),
        tr = td.closest("tr"),
        code = tr.attr("id"), old_value, new_value;

      if(t.hasClass("title")) {
        old_value = t.closest(".locale-box").find(".locale-picker ul li[data-key='"+t.attr("data-locale")+"']").attr("data-orig-value") ;
        new_value = t.val();
      }
      else {
        old_value = t.attr("data-o"),
        new_value = +t.val();
      }

      if(t.hasClass("numerical")) {
        if(new_value === 2) {
          tr.find(".conditional, .conditional input").removeAttr("disabled");
        }
        else {
          tr.find(".conditional, .conditional input").attr("disabled", "disabled");
        }
      }

      update_dirty_rows(code, td.index(), old_value, new_value);
      preview.show(code, true);
    });
  }
  function update_dirty_rows (code, field_index, old_value, new_value) {
    if(old_value != new_value)
    {
      if(dirty_rows.hasOwnProperty(code)) {
        if(dirty_rows[code].fields.indexOf(field_index) === -1) {
          ++dirty_rows[code].count;
          dirty_rows[code].fields.push(field_index);
        }
      }
      else {
        dirty_rows[code] = { count:1, fields: [field_index] };
      }
    }
    else {
      if(dirty_rows.hasOwnProperty(code))
      {
        var index = dirty_rows[code].fields.indexOf(field_index);
        if(index !== -1 && dirty_rows[code].count !== 1) {
          --dirty_rows[code].count;
          dirty_rows[code].fields.splice(index,1);
        }
        else { delete dirty_rows[code]; }
      }
      else { delete dirty_rows[code]; }
    }
  }
  function init_locale_picker () {
    $(document).on("click", ".locale-picker:not([disabled]) .locale-toggle", function (){
      var to_deactivate = $(".locale-box.active"),
        t = $(this),
        key = t.text(),
        p = t.parent(),
        ul = p.find("ul"),
        box = p.parent(),
        input = box.find("input");

      if(to_deactivate.length) {
        to_deactivate.removeClass("active");
        to_deactivate.find("ul").removeClass("active");
        to_deactivate.find("input").addClass("blur");
      }

      ul.find("li").show();
      ul.find("li[data-key='" + key + "']").hide(),
      box.toggleClass("active");
      ul.toggleClass("active");
      input.toggleClass("blur");
    });
    $(document).on("click", ".locale-picker ul li", function () {
      var t = $(this),
        ul = t.parent(),
        p = ul.parent(),
        toggle = p.find(".locale-toggle"),
        box = p.parent(),
        input = box.find("input"),
        prev_locale = input.attr("data-locale"),
        prev_value = input.val();

      if(!t.hasClass("reset")) {
        var key = t.attr("data-key"),
          value = t.attr("data-value");

        if(key !== prev_locale)
        {
          ul.find("li[data-key='"+prev_locale+"']").attr("data-value", prev_value);
          input.val(value);
          input.attr("data-locale", key);
          toggle.text(key);
          toggle.attr("data-original-title", t.attr("data-original-title"));
        }
      }
      else {
        var toggle_key = toggle.text(),
          li = ul.find("li[data-key='"+toggle_key+"']");

        li.attr("data-value", li.attr("data-orig-value"));
        input.val(li.attr("data-orig-value"));
      }
      box.toggleClass("active");
      ul.toggleClass("active");
      input.toggleClass("blur");
    });
    $(document).on("click", function (e) {
      if($(e.target).closest(".locale-box").length === 0 && $(".locale-box.active").length) {
        var to_deactivate = $(".locale-box.active");
        if(to_deactivate.length) {
          to_deactivate.removeClass("active");
          to_deactivate.find("ul").removeClass("active");
          to_deactivate.find("input").addClass("blur");
        }
      }
    });
  }
  function get_code_meta (code) {
    var tr = mass_change.find("tr#" + code),
      tmp = "[name='question["+code+"][numerical]",
      data_type = +tr.find("[name='question["+code+"][data_type]']:checked").val(),
      titles = {}, out;
    if(data_type === 1) {
      return { data: [data_type] };
    }
    else {
      var input = tr.find(".locale-box input"),
        input_key = input.attr("data-locale");
      titles[input_key] = input.val();
      tr.find(".locale-picker ul li:not(.reset)").each(function (i, d) {
        var dd = $(d);
        if(dd.attr("data-key") !== input_key && dd.attr("data-orig-value") !== dd.attr("data-value")) {
          titles[dd.attr("data-key")] = dd.attr("data-value");
        }
      });

      out = [data_type,
        tr.find(tmp + "[type]']").val(),
        tr.find(tmp + "[size]']").val(),
        tr.find(tmp + "[min]']").val(),
        tr.find(tmp + "[max]']").val() ].map(function (d){ return d=+d; });
      // out.unshift(titles);
      return { data: out, titles: titles };
    }
  }
  init();
});




