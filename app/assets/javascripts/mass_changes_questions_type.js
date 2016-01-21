/*global  $, gon, console, Highcharts, jQuery, debounce, isN, replicate, replicate2, isInteger */
/*eslint no-console: 0, no-unused-vars: 0*/
//= require jquery.ui.draggable

$(document).ready(function (){

  var cache = { }, // code and all data with frequency_data for each numerical so it will be frequency_data: { "type;size;min;max": grouped data}
    cq = null, // current question
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

      /**
      * Prepaire preview window and bind all parts
      */
      init: function () {
        Highcharts.setOptions({
          lang: { thousandsSep: "," },
          colors: ["#00adee"],
          credits: { enabled: false }
        });
        this.selector = $("#preview");
        this.bind();
      },

      /**
      * Bind preview window close button, ESC button and make it draggable
      */
      bind: function () {
        var _t = this;
        if($( window ).width() > 992) {
          _t.selector.draggable({ handle: ".header > .move", cursor: "move" }); // make draggable

          _t.selector.find(".close" ).click(function () { // callback on close button click
            var t = $(this),
              p = t.closest("#preview");
            p.hide();
            p.find(".chart").highcharts().destroy();
            _t.closed = true;
          });

          $(document).keyup(function (e) { // callback on ESC click if preview window is open
            if (e.keyCode == 27 && !_t.closed) { // escape key maps to keycode `27`
              _t.selector.hide();
              _t.selector.find(".chart").highcharts().destroy();
              _t.closed = true;
              e.preventDefault();
            }
          });
        }
      },

      /**
      * Trigger building bar or histogram based on code, but only if it is visible
      * @param {string} code - Question code to show
      * @param {boolean} only_if_opened - with closed property allows to control when to shows preview
      */
      show: function (code, only_if_opened) {
        if(typeof only_if_opened !== "boolean") { only_if_opened = false; }
        if(only_if_opened && this.closed) { return; }
        if($("tr#" + code_format(code)).find("input.numerical:checked").val() !== undefined) {
          this.prepaire_data(code);
        }
        else {
          this.code = null;
          this.selector.find(".chart").html("<div class='no_preview'>" + gon.no_preview + "</div>").show();
        }
      },

      /**
      * Build bar or histogramm based and prepaired data
      */
      render_chart: function () {
        var t = this,
          nc = false,
          code = cq.code,
          sub_id = cq.sub_id,
          type = cq.type,
          ch_code = cache[code];

        if(preview.code !== code) { // if code is new then chart should be rendered from scratch, else just update labels and data
          nc = true;
          preview.code = code;
        }
        var cd = ch_code.data[sub_id].fd, // current data
          cm = cq.meta,             // current meta data
          cg = ch_code.general, // current general data
          ct = ch_code.data[sub_id].fdt, // current data total
          $preview = $("#preview"),
          chart,
          range = type == 1 ? null : getRanges(cm);
        $preview.show();

        var histogramm = function () {
          var sum = cd.reduce(function (a, b){return a+b;});
          if(t.closed || nc) {
            chart = new Highcharts.Chart({
              chart: {
                renderTo: $("#preview .chart")[0],
                type: "column",
                spacingRight: 40
              },
              title: {
                text: "<span class='code-highlight'>" + cg.question.original_code + "</span> - " + cg.question.text,
                useHTML: true,
                style: t.style1
              },
              subtitle: {
                text: gon.total_responses_out_of.replace("X", Highcharts.numberFormat(ct, 0)).replace("XX", Highcharts.numberFormat(cg.orig_data.length, 0)),
                useHTML: true,
                style: t.style2
              },
              xAxis: {
                title: { text: cq.titles[$("html").attr("lang")] },
                tickPositioner: function () { return formatLabel(cq.meta); },
                startOnTick: true,
                endOnTick: true
              },
              yAxis: { title: null },
              plotOptions: {
                column: {
                  groupPadding: 0,
                  pointPadding: 0,
                  borderWidth: 0,
                  pointPlacement: "between"
                }
              },
              series: [{ data: cd.map(function (d, i){ return { x:cm[5] +cm[2]*i, y: d[0], percent: d[1], tip: range[i] }; }) }],
              tooltip: {
                backgroundColor: "#fff",
                formatter: function () {
                  return "<b>" + this.point.tip + ":</b><br/>" + Highcharts.numberFormat(this.y, 0) + " (" + this.point.percent + "%)";
                }
              },
              legend: { enabled: false }
            }, function () {
              $preview.css({top: $(window).height() - $preview.height() - 10 });
            });
          }
          else {
            chart = $preview.find(".chart").highcharts();
            chart.xAxis[0].setTitle({ text: cq.titles[$("html").attr("lang")] });
            chart.series[0].setData(cd.map(function (d, i){ return { x:cm[5] +cm[2]*i, y: d[0], percent: d[1] }; }), false, true);
            chart.isDirtyBox = true;
            chart.redraw();
          }
        },
          bar = function () {
            var num = 0,
              keys = [],
              cd_keys = [],
              cd_values = [];
            Object.keys(cd).forEach(function (key) {
              num+=+cd[key][0];
              cd_keys.push(cg.question.answers.filter(function (ans) { return ans.value === key; })[0].text);
              cd_values.push({y: cd[key][1], count: cd[key][0]});
            });
            if(t.closed || nc) {
              chart = new Highcharts.Chart({
           
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
                  text: gon.total_responses_out_of.replace("X", Highcharts.numberFormat(num, 0)).replace("XX", Highcharts.numberFormat(cg.orig_data.length, 0)),
                  useHTML: true,
                  style: t.style2
                },
                xAxis: {
                  categories: cd_keys,
                  labels: {
                    style: { "color": "#3c4352", "fontSize": "14px", "fontFamily":"'sourcesans_pro', 'sans-serif'", "fontWeight": "normal", "textAlign": "right" },
                    step: 1
                  }
                },
                series: [{ data: cd_values }],
                yAxis: {
                  floor: 0,
                  ceiling: 100,
                  title: { text: gon.percent }
                },
                tooltip: {
                  backgroundColor: "#fff",
                  formatter: function () {
                    return Highcharts.numberFormat(this.point.options.count, 0) + " (" + this.y + "%)";
                  }
                },
                legend: { enabled: false }
              },
              function () {
                $preview.css({top: $(window).height() - $preview.height() - 10 });
              });
            }
          };

        function formatLabel (meta) {
          var v = [];
          for(var i = 0; i <= meta[7]; ++i) {
            v.push(meta[5]+i*meta[2]);
          }
          return v;
        }
        function getRanges (m) { // numerical meta
          var rng = [], start, endd, minus, isInt;
          cd.forEach(function (d, i) {
            start = m[5] + m[2] * i;
            isInt = m[1] == 0;
            start = isInt ? parseInt(start) : parseFloat(start);
            minus = isInt ? 1 : (m[2].toString().indexOf(".") !== -1 ? parseFloat("0." + "0"*(m[2].toString().split(".")[1].length-1) + "1") : 0.1);

            if(cd.length-1 == i) { minus = 0; }
            endd = start + m[2] - minus;
            rng.push(start + " - " + (isInt ? parseInt(endd) : parseFloat(endd)));
          });
          return rng;
        }
        if(type === 1) { bar(); }
        else if(type === 2) { histogramm(); }
        if(t.closed) { t.closed = false; }
      },

      /**
      * Check if data is missing and if yes get it remotely else from cache
      * @param {string} code - Question code that was updated
      */
      prepaire_data: function (code) {
        var t = this,
          meta = get_code_meta(code),
          code_meta = meta.data,
          data_type = code_meta[0],
          sub_id = code_meta.join(";");

        cq = { code: code, sub_id: sub_id, type: data_type, meta: code_meta, titles: (data_type === 2 ? meta.titles : []) };

        if(isset(cache, code + ".data")) { // if question code has data
          if(!isset(cache[code], "data." + sub_id)) {
            cache[code]["data"][sub_id] = get_frequency_data(code, code_meta, data_type);
          }
          t.render_chart();
          return;
        }
        cache[code] = { code: code, general: {}, data: {}}; // if there is no locale info then get it remotely

        var to_send = { dataset_id: dataset_id, question_code: code, access_token: gon.app_api_key };
        if (typeof gon.private_user !== "undefined"){ to_send["private_user_id"] = gon.private_user; }

        $.ajax({
          type: "GET",
          dataType: "json",
          data: to_send,
          url: view_chart_path,
          success: function (d) {
            cache[code].general = { dataset: d.dataset, orig_data: d.data.slice(), formatted_data: d.data.slice(), question: d.question };
            if(data_type === d.question.data_type) {
              if(d.frequency_data !== null) {
                cache[code].data[sub_id] = { fd: d.frequency_data };
                if(data_type === 2) {
                  cache[code].data[sub_id]["dfm"] = d.frequency_data_meta;
                  var total = 0;
                  d.frequency_data.forEach(function (d) { total+=d[0]; });
                  cache[code].data[sub_id]["fdt"] = total;
                }
              }
              else {
                console.log("Frequency data should be ready on server, something went wrong");
              }
            }
            else {
              cache[code]["data"][sub_id] = get_frequency_data(code, code_meta, data_type);
            }
            t.render_chart();
          }
        });
      }
    };

  /**
  * Initialize calls other init parts
  */
  function init () {
    init_datatable();
    init_binds();
    preview.init(); // preview box initialize and prepaire to be called
    init_locale_picker();
  }

  /**
  * Initialize datatable
  */
  function init_datatable () {

    $.fn.dataTable.ext.order["dom-radio"] = function ( settings, col ) { // for radio column to be sortable
      return this.api().column( col, {order:"index"} ).nodes().map( function (td) {
        return $("input[type='radio']", td).prop("checked") ? "1" : "0";
      });
    };

    datatable = $("#mass_change").dataTable({ // initialize datatable with all appropriate options data comes from server
      "dom": "<'top'fli>t<'bottom'p><'clear'>",
      //responsive: true,
      "data": gon.datatable_json,
      createdRow: function (row, data, index) {
        row.id = data.code;
      },
      "columns": [
        {"data":null,
          render: function (data, type, full) {
            var tmp = full.data_type === 0;
            return "<div title='" + gon[tmp ? "view_disabled_title" : "view_active_title"] + "'><div class='btn btn-default view-chart' "+(tmp ? " disabled" : "")+">"+gon.view+"</div>";
          },
          "orderable": false
        },
        {"data":"ocode" },
        {"data":"question" },
        {"data":"data_type",
          render: function (data, type, full) {
            return "<div"+(full.has_answers ? "" : " title='"+ gon.no_answer+"'")+"><input class='numerical' type='radio' value='1' name='question["+full.code +"][data_type]'" + (data == 1 ? " checked": "") + " data-o='"+data+"' "+(full.has_answers ? "" : " disabled") + "></div>";
          },
          class: "c",
          "orderDataType": "dom-radio",
          "width": "120px"
        },
        {"data":"data_type",
          render: function (data, type, full) {
            return "<div"+(full.has_data_without_answers ? "" : " title='"+ gon.no_data+"'")+"><input class='numerical' type='radio' value='2' name='question["+full.code +"][data_type]'" + (data == 2 ? " checked": "") + " data-o='"+data+"' "+(full.has_data_without_answers ? "" : " disabled") +"></div>";
          },
          class: "c",
          "orderDataType": "dom-radio",
          "width": "120px"
        },
        {"data":"num.title",
          render: function (data, type, full) {
            return "<div class='conditional locale-box' name='question["+full.code +"][numerical][title]' data-o='' "+(full.data_type !== 2 ? " disabled" : "")+">"+
            "<div class='locale-picker' "+(full.data_type !== 2 ? " disabled" : "")+"><div class='locale-toggle' title='"+gon.locale_picker_data[data[0][0]][0]+"'>"+data[0][0]+"</div><ul>" +
            data.map(function (d, i) { return "<li class='"+[(i+1>6 ? "btop" : ""), (data.length > 5 && i+1 > data.length-data.length%6 ? "bbottom" : "")].join(" ") +"' data-key='"+d[0]+"' data-value='"+d[1]+"' data-orig-value='"+d[1]+"' title='"+gon.locale_picker_data[d[0]][0]+"'>" + d[0] + "</li>"; }).join("") +
            "<li class='reset' title='"+gon.locale_picker_data.reset+"'></li></ul></div>" +
            "<input type='text' class='title' value='"+data[0][1]+
            "' data-locale='"+ data[0][0] +"'" + (full.data_type !== 2 ? " disabled" : "") + "></div>";
          },
          class: "c",
          "orderable": false,
          "width": "120px"
        },
        {"data":"num.type",
          render: function (data, type, full) {
            return "<select class='conditional' name='question["+full.code +"][numerical][type]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + "><option value='0'" + (data == 0 ? "selected": "") + ">"+gon.integer+"</option>" +
              "<option value='1'" + (data == "1" ? "selected": "") + ">"+gon.decimal+"</option></select>";
          },
          class: "c",
          "width": "90px",
          "orderable": false
        },
        {"data":"num.width",
          render: function (data, type, full) {
            return "<input class='conditional r' type='number' value='"+data+"' name='question["+full.code +"][numerical][width]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + ">";
          },
          "width": "90px",
          "orderable": false
        },
        {"data":"num.min",
          render: function (data, type, full){
            return "<input class='conditional r' type='number' value='"+data+"' name='question["+full.code +"][numerical][min]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + ">";
          },
          "width": "90px",
          "orderable": false
        },
        {"data":"num.max",
          render: function (data, type, full){
            return "<input class='conditional r' type='number' value='"+data+"' name='question["+full.code +"][numerical][max]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + ">";
          },
          "width": "90px",
          "orderable": false
        }
      ],
      "ordering": true,
      // "sorting": [],
      "order": [[1, "asc"]],
      "language": {
        "url": gon.datatable_i18n_url,
        "searchPlaceholder": gon.datatable_search
      },
      "pagingType": "full_numbers",
      "orderClasses": false
      // ,search: {
      //   search: "age"
      // },
      // displayStart: 20
    });
  }

  /**
  * Initialize all binds
  */
  function init_binds () {
    form.submit( function (e) { // callback on save button click
      e.preventDefault();
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
              set_code_original_values(d.toLowerCase());
            });
            dirty_rows = {};
          }
        });
      });
      var tr;
      function set_code_original_values (d) {
        tr = datatable.$("tr#" + code_format(d));
        var str = "[name='question["+d+"]",
          dao = "data-o",
          cd = current_data[d].data;

        tr.find(str+"[data_type]']").attr("data-o", cd[0]);

        if(cd[0] === 2) {
          str += "[numerical]";
          Object.keys(current_data[d].titles).forEach(function (k) {
            tr.find(str+"[title]'] .locale-picker ul li[data-key='" + k + "']").attr("data-orig-value", current_data[d].titles[k]);
          });

          // titles should be fixed
          tr.find(str+"[type]']").attr(dao, cd[1]);
          tr.find(str+"[width]']").attr(dao, cd[2]).attr("value", cd[2]);
          tr.find(str+"[min]']").attr(dao, cd[3]).attr("value", cd[3]);
          tr.find(str+"[max]']").attr(dao, cd[4]).attr("value", cd[4]);
        }
      }
      return false;
    });

    $(datatable).on("click", "tr", function (e, programmatic) { // callback on table row(tr) click
      if(programmatic) { return; }
      var tr = $(this),
        code = tr.attr("id"),
        t = $(e.target);

      if (!tr.hasClass("selected")) {
        datatable.$("tr.selected").removeClass("selected");
        tr.toggleClass("selected");
      }

      if(t.hasClass("view-chart")) { // callback on view button click that shows preview if possible
        tr.attr("disabled", "disabled");
        t.parent().addClass("row-loader");

        preview.show(code);

        tr.removeAttr("disabled", "disabled");
        t.parent().removeClass("row-loader");
      }
      else if(t.hasClass("numerical")) {
        var checked = (t.attr("checked") === "checked");

        tr.find("input[type='radio']").removeAttr("checked").prop("checked", false);
        if(checked) { // so when radio is alreay checked
          var td = t.closest("td"),
            old_value = +t.attr("data-o"),
            new_value = 0;//+t.val();
          tr.find(".view-chart").attr("disabled", true);

          update_dirty_rows(code, td.index(), old_value, new_value); // update dirty_rows tracking system for changes
          if(old_value === 2) { // if numerical
            tr.find(".conditional, .conditional input").attr("disabled", "disabled");
            tr.find(".locale-picker").attr("disabled", "disabled");
          }
          preview.show(code, true);
        }
        t.attr("checked", !checked).prop("checked", !checked);
      }
      else if (t.get(0).nodeName !== "INPUT" && t.get(0).nodeName !== "SELECT") {
        preview.show(code, true);
      }
    });

    $(datatable).on("change", "input, select", function (e) { // callback for input fields change
      e.stopPropagation();
      e.stopImmediatePropagation();
      var t = $(this),
        td = t.closest("td"),
        tr = td.closest("tr"),
        code = tr.attr("id"), old_value, new_value;

      if(t.hasClass("title")) { // if has title then it is locale picker and need different way to get value
        old_value = t.closest(".locale-box").find(".locale-picker ul li[data-key='"+t.attr("data-locale")+"']").attr("data-orig-value") ;
        new_value = t.val();
      }
      else { // other input
        old_value = t.attr("data-o"),
        new_value = +t.val();
      }

      if(t.attr("name") === "question["+code+"][data_type]") { // if data type was changed then activate view button
        tr.find(".view-chart").removeAttr("disabled");
      }

      update_dirty_rows(code, td.index(), old_value, new_value); // update dirty_rows tracking system for changes
      if(t.hasClass("numerical")) { // if input of data_type
        if(new_value === 2) { // if numerical
          tr.find(".conditional, .conditional input").removeAttr("disabled");
          tr.find(".locale-picker").removeAttr("disabled");
          prepare_numerical_fields(code, function () { // prepaire data and then preview if window is open
            preview.show(code, true);
          });
        }
        else {
          tr.find(".conditional, .conditional input").attr("disabled", "disabled");
          preview.show(code, true);
        }
      }
      else {
        preview.show(code, true);
      }
    });

    $("a.btn-select-all").click(function (){ // callback on all checkbox click in header of table for categorical type it will switch all questions to be categorical
      var t = $(this),
        state_all = t.attr("data-state") == "all";

      $(datatable.$("tr", {"filter": "applied"})).find("td input.numerical[value='1']").prop("checked", state_all).trigger("change");

      t.attr("data-state", state_all ? "none" : "all" );
      return false;
    });
  }

  /**
  * Bind document events for locale-picker input
  */
  function init_locale_picker () {
    $(document).on("click", ".locale-picker:not([disabled]) .locale-toggle", function (){ // toggle to switch between language is first block with currently selected language
      var t = $(this),
        key = t.text(),
        p = t.parent(),
        ul = p.find("ul"),
        box = p.parent(),
        input = box.find("input"),
        has = box.hasClass("active");

      $(".locale-box.active").removeClass("active");
      if(!has) {
        ul.find("li").show();
        ul.find("li[data-key='" + key + "']").hide(),
        box.addClass("active");
      }
    });
    $(document).on("click", ".locale-picker ul li", function () { // on opened menu click event
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
    });

    $(document).on("click", function (e) { // if clicking outside when locale menu is opened close it
      if(!$(e.target).closest(".locale-picker").length) { $(".locale-box.active").removeClass("active"); }
    });
  }

  /**
  * Update array of dirty rows which controls if anything was changed in the table
  * @param {string} code - Question code that was updated
  * @param {integer} field_index - Index of input that was changed, calculated by index of parent td
  * @param {string} old_value - Original value of input
  * @param {string} new_value - Updated value of input
  */
  function update_dirty_rows (code, field_index, old_value, new_value) {
    if(old_value != new_value) // if original input value is different than new input value then update dirty rows
    {
      if(dirty_rows.hasOwnProperty(code)) { // if any changes were done to question code already
        if(dirty_rows[code].fields.indexOf(field_index) === -1) { // only do when this input is not under control already
          ++dirty_rows[code].count;
          dirty_rows[code].fields.push(field_index);
        }
      }
      else {
        dirty_rows[code] = { count:1, fields: [field_index] }; // if no changes were done to queston code
      }
    }
    else { // if original value equal to new value then remove from dirty rows
      if(dirty_rows.hasOwnProperty(code)) // tests if question code is dirty rows
      {
        var index = dirty_rows[code].fields.indexOf(field_index);
        if(index !== -1 && dirty_rows[code].count !== 1) { // if not last field for this code then decrease count and remove field_index
          --dirty_rows[code].count;
          dirty_rows[code].fields.splice(index, 1);
        }
        else { delete dirty_rows[code]; } // if last field than remove whole question code from dirty rows
      }
      // else { delete dirty_rows[code]; }
    }
  }

  /**
  * For provided question code return array of selected options
  * @param {string} code - Question code that was updated
  * @returns {array} - based on question data type return selected values
  * @desc If question is categorical then return just {data: [data_type]}, else (numerical) { data: [data_type, type, width, min, max, min_range, max_range, size], titles: { lang_key: text}}
  */
  function get_code_meta (code) {
    var tr = datatable.$("tr#" + code_format(code)),
      tmp = "[name='question["+code+"][numerical]",
      data_type = tr.find("[name='question["+code+"][data_type]']:checked").val(),
      titles = {},
      out;
    if(data_type === undefined) { data_type = 0; }
    data_type = +data_type;

    if(data_type === 0) { // unknown
      return { data: [0] };
    }
    if(data_type === 1) { // categorical
      return { data: [1] };
    }
    else if(data_type === 2) { // numerical
      var input = tr.find(".locale-box input"),
        input_key = input.attr("data-locale");
      titles[input_key] = input.val();
      tr.find(".locale-picker ul li:not(.reset)").each(function (i, d) {
        var dd = $(d);
        if(dd.attr("data-key") !== input_key && dd.attr("data-orig-value") !== dd.attr("data-value")) { // if language is not currently selected and text for it is changed
          titles[dd.attr("data-key")] = dd.attr("data-value");
        }
      });

      out = [data_type,
        tr.find(tmp + "[type]']").val(),
        tr.find(tmp + "[width]']").val(),
        tr.find(tmp + "[min]']").val(),
        tr.find(tmp + "[max]']").val() ].map(function (d){ return d=+d; });         
      out.push(Math.floor(out[3]/out[2]) * out[2]); // calculating  min_range = floor(min/width) * width
      out.push(Math.ceil(out[4]/out[2]) * out[2]);  // calculating  max_range = ceil(max/width) * width
      out.push((out[6]-out[5])/out[2]);             // calculating  size = (max_range-min_range)/width

      return { data: out, titles: titles };
    }
  }

  /**
  * For provided question code and meta data set numerical input values
  * @param {string} code - Question code that was updated
  * @param {array} meta - Meta data for this question code
  */
  function set_code_meta (code, meta) {
    var tr = datatable.$("tr#" + code_format(code)),
      str = "[name='question["+code+"][numerical]";

    tr.find(str+"[type]']").val(meta[1]);
    tr.find(str+"[width]']").val(meta[2]);
    tr.find(str+"[min]']").val(meta[3]);
    tr.find(str+"[max]']").val(meta[4]);

    var ul = tr.find(str+"[title]'] .locale-picker ul");
    ul.find("li:first-child").trigger("click", [true]);
    ul.find("li:last-child").trigger("click", [true]);
  }

  /**
  * For provided numerical question code get cached or remote data
  * @param {string} code - Question code that was updated
  * @param {callback} callback - function that is called when data is ready
  */
  function prepare_numerical_fields (code, callback) {
    row_loader(code, true);

    if(isset(cache, code + ".general.orig_data")) {
      if(isset(cache[code], "data.default")) {
        set_code_meta(code, cache[code]["data"]["default"].fdm);
        row_loader(code, false);
      }
      else {
        prepare_numerical_fields_callback();
        callback();
      }
    }
    else {
      var to_send = { dataset_id: dataset_id, question_code: code, access_token: gon.app_api_key };
      if (typeof gon.private_user !== "undefined"){ to_send["private_user_id"] = gon.private_user; }

      cache[code] = { code: code, general: {}, data: {}};
      $.ajax({
        type: "GET",
        dataType: "json",
        data: to_send,
        url: view_chart_path,
        success: function (d) {
          cache[code].general = { dataset: d.dataset, orig_data: d.data.slice(), formatted_data: d.data.slice(), question: d.question };
          prepare_numerical_fields_callback();
          callback();
        }
      });
    }

    /**
    * Based on data for numerical question code prepare default frequency and meta data
    */
    function prepare_numerical_fields_callback () {
      var formatted = cache[code].general.formatted_data, // formatted formatted_data
        min = Number.MAX_VALUE,
        max = Number.MIN_VALUE,
        DEFAULT_WIDTH = 10,
        isFloat,
        question = cache[code].general.question,
        predefined_answers = question.hasOwnProperty("answers") ? question.answers.map(function (d){ return d.value; }) : [],
        num = [2, 0, DEFAULT_WIDTH, 0, 0, 0, 0, 0],
        predefinedData = [];
      formatted.forEach(function (d, i) {
        if(isN(d) && predefined_answers.indexOf(d) === -1) { // only numbers and that are not predefined answer allowed

          formatted[i] = +d;
          if(num[1] !== 1 && !isInteger(formatted[i])) { num[1] = 1; } // if any number is float then change type
          if(formatted[i] < min) { min = formatted[i]; }
          if(formatted[i] > max) { max = formatted[i]; }
        }
        else {
          predefinedData.push(i); // if predefined answer or anything except number
        }
      });
      predefinedData.forEach(function (d, i) { // delete data that is predefined or not number
        formatted.splice(d-i, 1); // minus i because formatted will be changed by splice, and it will be changed by minus one at a time or each i times
      });
      if(min === Number.MAX_VALUE) { min = 0; } // no min value then default to 0
      if(max === Number.MIN_VALUE || min === max) { max = min + 1; } // if no max then min + 1
      if(max-min<10) { num[2] = 1; }
      num[3] = min;
      num[4] = max;

      var range = num[4] - num[3];
      num[2] = range > DEFAULT_WIDTH ? Math.ceil(range/DEFAULT_WIDTH) : 1;

      num[5] = Math.floor(num[3] / num[2]) * num[2]; // min_range = floor(min/width) * width
      num[6] = Math.ceil(num[4] / num[2]) * num[2];  // max_range = ceil(max/width) * width
      num[7] = (num[6] - num[5]) / num[2];           // size = (max_range - min_range) / width
      // if(num[7] == 0) { num[7] = 1; }
      var sub_id = num.join(";");
      cache[code].data[sub_id] = { fd: replicate2(num[7], 0) }; // create empty arrays for fd(two dimensional [count,percent]) and fill with 0
      cache[code].data["default"] = { fd: replicate2(num[7], 0)}; // create empty arrays for fd(two dimensional [count,percent]) and fill with 0

      var fd = cache[code].data[sub_id].fd,
        fd2 = cache[code].data["default"].fd;
      formatted.forEach(function (d){
        if(d >= num[3] && d <= num[4]) { // only greater min and less max are allowed
          var ind = d === num[5] ? 0 : Math.floor((d-num[5])/num[2]-0.00001); // index for group
          fd[ind][0] += 1; // count calculating, count is first
          fd2[ind][0] += 1; // same as above
        }
      });

      var total = 0;
      fd.forEach(function (d) { total+=d[0]; });

      cache[code].data[sub_id]["fdm"] = num; // saving meta data
      cache[code].data["default"]["fdm"] = num;

      cache[code].data[sub_id]["fdt"] = total; // saving total in separate property
      cache[code].data["default"]["fdt"] = total;

      fd.forEach(function (d, i) {
        fd[i][1] = Math.round10(d[0]/total*100, -2); // calculating percent for each group based on total
      });
      set_code_meta(code, num);
      row_loader(code, false);
    }
  }

  /**
  * By providing step, start, end values creates array of ticks for this range
  * @param {integer} step - Step to move through the range
  * @param {integer} min - Start tick of the range
  * @param {integer} max - End tick of the range
  * @returns {array} - array of ticks for the range
  */
  function get_range_map (step, min, max) {
    var range_map = [min],
      prev_ticker = min,
      ticker = min+step;

    while(Math.round(ticker)<max) {
      range_map.push(Math.round(ticker));
      prev_ticker = ticker;
      ticker=ticker+step;
    }
    if(prev_ticker != max) {
      range_map.push(max);
    }
    return range_map;
  }
    /**
  * By providing numerical question code and meta will fill { fd: frequency_data, fdm: frequency_data_meta, fdt: frequency_data_total }
  * That is used to create histogram
  * @param {string} code - Numerical question code
  * @param {array} meta - Meta data for question
  * @returns {array} - array of ticks for the range
  */
  function get_frequency_data (code, meta, data_type) {
    var raw_data = cache[code].general.orig_data,
      frequency_data,
      total = 0;
    if(data_type === 1) {
      var cnt,
        answers = isset(cache[code], "general.question.answers") ? cache[code].general.question.answers.map(function (d){ return d.value; }) : [];

      frequency_data = {};

      answers.forEach(function (answer) {
        frequency_data[answer] = [raw_data.filter(function (d) { return d === answer; }).length, 0];
      });

      answers.forEach(function (d) { total+=frequency_data[d][0]; });
      answers.forEach(function (d, i) {
        frequency_data[d][1] = Math.round10(parseFloat(frequency_data[d][0])/total*100, -2); // calculating percent for each group based on total
      });

      return { fd: frequency_data, fdt: total };
    }
    else if(data_type === 2) {
      var ind,
        predefined_answers = isset(cache[code], "general.question.answers") ? cache[code].general.question.answers.map(function (d){ return d.value; }) : [];

      frequency_data = replicate2(meta[7], 0);

      if(Array.isArray(raw_data)) { // if data is there
        raw_data.forEach(function (raw_d) { // calculate each groups count
          var d = raw_d;
          if(isN(d) && predefined_answers.indexOf(d) === -1) { // only numbers and that are not predefined answer allowed
            if(meta[1] == 0) { d = parseInt(d); } // if numerical type is integer then parse to int
            else if(meta[1] == 1) { d = parseFloat(d); } // else parse to float

            if(d >= meta[3] && d <= meta[4]) {  // only greater min and less max are allowed
              ind = d === meta[5] ? 0 : Math.floor((d-meta[5])/meta[2]-0.00001); // index for group
              frequency_data[ind][0] += 1; // count calculating, count is first
            }
          }
        });
        frequency_data.forEach(function (d) { total+=d[0]; });
        frequency_data.forEach(function (d, i) {
          frequency_data[i][1] = Math.round10(d[0]/total*100, -2); // calculating percent for each group based on total
        });
      }
      return { fd: frequency_data, fdm: meta, fdt: total };
    }
  }

  /**
  * Nested check if object has property
  * @param {object} obj - Object that should be tested for property existence
  * @param {string} args - dot separated property names in top to bottom order level1.level2. ... levelN
  */
  function isset (obj, args) {
    args = args.split(".");
    for (var i = 0; i < args.length; i++) {
      if (!obj || !obj.hasOwnProperty(args[i])) {
        return false;
      }
      obj = obj[args[i]];
    }
    return true;
  }

  /**
  * Turn on off row loader for table (loader image will appear inside row)
  * @param {string} code - Question code to find correct row
  * @param {boolean} start - State for loader if true then show else hiding
  */
  function row_loader (code, start) {
    var tr = datatable.$("tr#" + code_format(code));

    if(start) {
      tr.attr("disabled", "disabled");
    }
    else {
      tr.removeAttr("disabled", "disabled");
    }
    tr.find(".view-chart").parent().toggleClass("row-loader", start); // show row loader
  }
  function code_format (code) {
    return code.replace(/\|/g, "\\|");
  }
  init();
});