/*global  $, gon, console, Highcharts, jQuery, debounce, isN, replicate, isInteger */
/*eslint no-console: 0, no-unused-vars: 0*/
//= require jquery.ui.draggable

$(document).ready(function (){

  var cache = { }, // code and all data with frequency_data for each numerical so it will be frequency_data: { "type;size;min;max": grouped data}
    cq = null, // current question
    //first = true,
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
      style1: {"text-align": "center", "font-family":"sourcesans_pro_l, sans-serif", "font-size": "18px", "color": "#3c4352" },
      style2: { "cursor": "pointer", "font-family":"sourcesans_pro_l, sans-serif", "font-size": "13px", "color": "#3C4352", "fontWeight": "normal" },
      init: function () {
        $("body").append("<div id='preview' class='preview'><div class='header'><div class='move'></div><div class='close'></div></div><div class='chart'></div></div>");
        this.selector = $("#preview");
        this.bind();
      },
      bind: function () {
        var _t = this;
        _t.selector.draggable({ handle: ".header > .move", cursor: "move" });
        _t.selector.find(".close" ).click(function () {
          var t = $(this),
            p = t.closest("#preview");
          p.hide();
          p.find(".chart").highcharts().destroy();
          _t.closed = true;
        });
      },
      show: function (code, only_if_opened) {
         console.log("show");
        if(typeof only_if_opened !== "boolean") { only_if_opened = false; }
        if(only_if_opened && this.closed) { return; }

        this.prepaire_data(code);        
      },
      render_chart: function () {
        var t = this;
        console.log(cq, cache);

        var nc = false; // if code is new
        if(preview.code !== cq.code) {
          nc = true;
          preview.code = cq.code;
        }
        console.log("here", cache[cq.code].data[cq.sub_id]);
        var cd = cache[cq.code].data[cq.sub_id].fd, // current data
          cm = cq.meta, // current data
          cg = cache[cq.code].general;  // current general data

        var $preview = $("#preview"), chart;
        $preview.show();

        var histogramm = function () {
          var sum = cd.reduce(function (a, b){return a+b;});

          var num = 0;
          cg.orig_data.forEach(function (n){
            if(isN(n) && +n >= 0) {
              ++num;
            }
          });

          if(t.closed || nc) {
            console.log("new",typeof cd );
            chart = new Highcharts.Chart({
              colors: ["#C6CA53"],
              chart: {
                renderTo: $("#preview .chart")[0],
                type: "column",
                spacingRight: 40
              },
              credits: { enabled: false },
              title: {
                text: "<span class='code-highlight'>" + cg.question.original_code + "</span> - " + cg.question.text,
                useHTML: true,
                style: t.style1
              },
              subtitle: {
                text: gon.total_responses_out_of.replace("X", num).replace("XX", cg.orig_data.length),
                useHTML: true,
                style: t.style2
              },
              xAxis: {
                title: { text: cq.titles[$("html").attr("lang")] },
                labels: {
                  align: "right",
                  x:-10
                },
                startOnTick: true,
                endOnTick: true,
                categories: formatLabel(cm)
              },
              yAxis: { title: null },
              plotOptions: {
                column: {
                  groupPadding: 0,
                  pointPadding: 0,
                  borderWidth: 0
                }
              },
              series: [{
                data: cd.slice()
              }],
              tooltip: {
                formatter: function () {
                  return this.y + " (" + Math.round10(this.y*100/sum, -2) + "%)";
                }
              },
              legend: { enabled: false }
            }, function () {
              var box = this.plotBox;
              var label = this.renderer.label(cm[4], (box.x+box.width) - 7, (box.y + box.height) + 5)
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
              $preview.css({top: $(window).height() - $preview.height() - 10 });
            });
          }
          else {
            var ss = 0;
            cd.slice().forEach(function(ddd){ ss+=ddd; });
            console.log("old", ss );
            chart = $preview.find(".chart").highcharts();
            chart.xAxis[0].setCategories(formatLabel(cm), true, true);
            chart.series[0].setData(cd.slice(), false, true);
            $("#preview .chart .histogramm-last-label").remove();
            var box = chart.plotBox;
            var label = chart.renderer.label(cm[4], (box.x+box.width) - 7, (box.y + box.height) + 5)
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
          }
        },
          bar = function () {
            var sum = 0,
              keys = [],
              cd_keys = [],
              cd_values = [];
            Object.keys(cd).forEach(function (key) {
              console.log(+cd[key]);
              if(isN(key) && +key >= 0) {
                sum+=+cd[key];
                keys.push(key);
                cd_keys.push(cg.question.answers.filter(function (ans) { return ans.value === key; })[0].text);
                cd_values.push(cd[key]);
              }
            });
            var num = 0;
            cg.orig_data.forEach(function (n){
              if(isN(n) && +n >= 0) {
                ++num;
              }
            });
            console.log(cd_keys, cd_values, sum);
            console.log("drawing bar");
            if(t.closed || nc) {
              console.log("new");
              chart = new Highcharts.Chart({
                colors: ["#C6CA53"],
                chart: {
                  renderTo: $("#preview .chart")[0],
                  type: "column",
                  spacingRight: 40,
                  inverted: true
                },
                title: {
                  text: "<span class='code-highlight'>" + cg.question.original_code + "</span> - " + cg.question.text,
                  useHTML: true,
                  style: t.style1
                },
                subtitle: {
                  text: gon.total_responses_out_of.replace("X", num).replace("XX", cg.orig_data.length),
                  useHTML: true,
                  style: t.style2
                },
                credits: { enabled: false },
                xAxis: {
                  categories: cd_keys
                },
                yAxis: { title:null },
                series: [{
                  data: cd_values
                }],
                tooltip: {
                  formatter: function () {
                    return this.y + " (" + Math.round10(this.y*100/sum, -2) + "%)";
                  }
                },
                legend: { enabled: false }

              }, function () {
                  $preview.css({top: $(window).height() - $preview.height() - 10 });
                });
            }
            else {
              console.log("old");
            }
          };


        function formatLabel (meta) {
          var v = [];
          for(var i = 0; i < meta[2]; ++i) {
            v.push(Math.floor(meta[3]+i*meta[5]));
          }
          return v;
        }

        if(cq.type === 1) {
          bar();
        } else if(cq.type === 2) {
          histogramm();
        }
        if(t.closed) {
          t.closed = false;
        }
      },
      prepaire_data: function (code) {
         console.log("prepaire_data");
        var t = this,
          meta = get_code_meta(code),
          code_meta = meta.data,
          data_type = code_meta[0],
          sub_id = code_meta.join(";");

        cq = { code: code, sub_id: sub_id, type: data_type, meta: code_meta, titles: (data_type === 2 ? meta.titles : []) };

        if(cache.hasOwnProperty(code) && cache[code].hasOwnProperty("data")) {
           console.log("here1");
          if(data_type === 2) {
            console.log("here2");
            code_meta.push((code_meta[4] - code_meta[3])/code_meta[2]);
            if(!cache[code]["data"].hasOwnProperty(sub_id)) {
              console.log("here3");
              cache[code]["data"][sub_id] = { fd: get_frequency_data(code_meta, cache[code].general.orig_data) };
            }
            console.log("here4", cache[code]["data"][sub_id].fd);
            t.render_chart();
            return;
          }
          else if(cache[code]["data"].hasOwnProperty(sub_id)) {
            console.log("here5");
            t.render_chart();
            return;
          }
        }
        console.log("remote");
        cache[code] = { code: code, general: {}, data: {}};

        if(data_type === 2) {
          code_meta.push((code_meta[4] - code_meta[3])/code_meta[2]);
        }

        $.ajax({
          type: "GET",
          dataType: "json",
          data: { dataset_id: dataset_id, question_code: code },
          url: view_chart_path,
          success: function (d) {
             console.log(d);
            cache[code].general = { dataset: d.dataset, orig_data: d.data, formatted_data: d.data, question: d.question };
            cache[code].data[sub_id] = { fd: d.frequency_data };
            if(data_type === 2)
            {
              cache[code].data[sub_id]["dfm"]= d.frequency_data_meta;
            }
            t.render_chart();
          }
        });
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
        {"data":null,
          render: function (data, type, full) {
            return "<div class='btn btn-default view-chart' "+(full.data_type === 0 ? " disabled" : "")+">View</div>";
          }
        },
        {"data":"code"},
        {"data":"question", "width": "100%"},
        {"data":"data_type",
          render: function (data, type, full) {
            return "<input class='numerical' type='radio' value='1' name='question["+full.code +"][data_type]'" + (data == 1 ? " checked": "") + " data-o='"+data+"' "+(full.has_answers ? "" : " disabled title='"+ "Question has no answers so it can be viewed as Bar chart"+"'") + ">";
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
      var t = $(this), tr = t.closest("tr");

      tr.attr("disabled", "disabled");
      t.parent().addClass("row-loader");

      preview.show($(this).closest("tr").attr("id"));

      tr.removeAttr("disabled", "disabled");
      t.parent().removeClass("row-loader");
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

      if(t.attr("name") === "question["+code+"][data_type]") {
        tr.find(".view-chart").removeAttr("disabled");
      }
      if(t.hasClass("numerical")) {
        if(new_value === 2) {
          prepare_numerical_fields(code);
          tr.find(".conditional, .conditional input").removeAttr("disabled");
          tr.find(".locale-picker").removeAttr("disabled");
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
          dirty_rows[code].fields.splice(index, 1);
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
  function set_code_meta (code, meta) {
    var tr = mass_change.find("tr#" + code),
      str = "[name='question["+code+"][numerical]";

    tr.find(str+"[type]']").val(meta[1]);
    tr.find(str+"[size]']").val(meta[2]);
    tr.find(str+"[min]']").val(meta[3]);
    tr.find(str+"[max]']").val(meta[4]);
  }
  function prepare_numerical_fields (code) {
     console.log("prepare_numerical_fields");
    mass_change.find("tr#" + code).attr("disabled", "disabled").find(".view-chart").parent().addClass("row-loader");

    if(cache.hasOwnProperty(code) && cache[code].hasOwnProperty("general") && cache[code]["general"].hasOwnProperty("orig_data")) {
       console.log("Has General");
      if(cache[code].hasOwnProperty("data") && cache[code].data.hasOwnProperty("default")) {
        console.log("Has Default for numerical");
        set_code_meta(code, cache[code]["data"]["default"].fdm);
        mass_change.find("tr#" + code).removeAttr("disabled", "disabled").find(".view-chart").parent().removeClass("row-loader");
      }
      else {
        console.log("Has No Default for numerical");
        prepare_numerical_fields_callback();
      }
    }
    else {
      console.log("Has No Default for numerical, ajax");
      cache[code] = { code: code, general: {}, data: {}};
      $.ajax({
        type: "GET",
        dataType: "json",
        data: { dataset_id: dataset_id, question_code: code },
        url: view_chart_path,
        success: function (d) {
          cache[code].general = { dataset: d.dataset, orig_data: d.data, formatted_data: d.data, question: d.question };
          prepare_numerical_fields_callback();
        }
      });
    }

    function prepare_numerical_fields_callback () {
      var formatted = cache[code].general.formatted_data, // formatted formatted_data
        min = Number.MAX_VALUE,
        max = Number.MIN_VALUE,
        isFloat,
        question = cache[code].general.question,
        predefined_answers = question.answers.map(function (d){ return d.value; }),
        num = [2, 0, 0, 0, 0],
        predefinedData = [];
      formatted.forEach(function (d, i) {
        if(isN(d) && predefined_answers.indexOf(d) === -1) {
          formatted[i] = +d;
          if(num[1] === 1 && !isInteger(formatted[i])) {
            num[1] = 1;
          }
          if(formatted[i] < min) {
            min = formatted[i];
          }
          if(formatted[i] > max) {
            max = formatted[i];
          }
        }
        else {
          predefinedData.push(i);
        }
      });
      predefinedData.forEach(function (d){
        formatted.splice(d, 1);
      });

      if(min === Number.MAX_VALUE) {
        min = 0;
      }
      if(max === Number.MIN_VALUE) {
        max = min + 1;
      }

      var tmp = Math.round(max-min);
      num[2] = tmp > 8 ? 8 : tmp;
      num[3] = min;
      num[4] = max;
      var sub_id = num.join(";");

      num.push((num[4] - num[3])/num[2]);
      cache[code].data[sub_id] = { fd: replicate(num[2], 0), fdm: num };
      cache[code].data["default"] = { fd: replicate(num[2], 0), fdm: num };
      var fd = cache[code].data[sub_id].fd,
        fd2 = cache[code].data["default"].fd;

      formatted.forEach(function (d){
        if(d >= num[3] && d <= num[4]) {
          fd[Math.floor((d-num[3])/num[5])] += 1;
          fd2[Math.floor((d-num[3])/num[5])] += 1;
        }
      });

      set_code_meta(code, num);
      mass_change.find("tr#" + code).removeAttr("disabled", "disabled").find(".view-chart").parent().removeClass("row-loader");
    }
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
  init();
});




