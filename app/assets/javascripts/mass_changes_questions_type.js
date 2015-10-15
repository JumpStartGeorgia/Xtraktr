/*global  $, gon*/
$(document).ready(function (){

   console.log("mass_change_type");//, gon.datatable_json);
   gon.datatable_json.forEach(function(d,i) {
    if(typeof d.data_type === "undefined") {
      console.log(d.code);
      
    }
   });
  var datatable = null,
    data = {},
    form = $("#mass_change_form"),
    view_chart_path = form.attr("data-view-chart-path"),
    dataset_id = form.attr("data-id");

  // /* Create an array with the values of all the checkboxes in a column */
  // // take from: http://www.datatables.net/examples/plug-ins/dom_sort.html
  // $.fn.dataTable.ext.order["dom-checkbox"] = function (settings, col)
  // {
  //   return this.api().column( col, {order:"index"} ).nodes().map( function (td) {
  //     return $("input[type='checkbox']", td).prop("checked") ? "1" : "0";
  //   });
  // };

  // catch form submit and pull out all form values from the datatable
  // the post will return will a status message
  form.submit( function () {
    var tmpDataKeys = Object.keys(data),
      tmpData = {};

    if(!tmpDataKeys.length) { return; }
    var table = $("#mass_change"), tr;
    tmpDataKeys.forEach(function (d) {
      tr = table.find("tr#" + d);
      tmpData[d.toLowerCase()] = [
        tr.find("[name='question["+d+"][data_type]']:checked").val(),
        tr.find("[name='question["+d+"][numerical][type]']").val(),
        tr.find("[name='question["+d+"][numerical][size]']").val(),
        tr.find("[name='question["+d+"][numerical][min]']").val(),
        tr.find("[name='question["+d+"][numerical][max]']").val()
      ];
    });
     //console.log(tmpData);
    //  // get all values and put to tmpData array for question
    $(".data-loader").fadeIn("fast", function (){
      $.ajax({
        type: "POST",
        dataType: "script",
        data: { mass_data: tmpData },
        url: $(this).attr("action"),
        success: function (d) {
          tmpDataKeys.forEach(function (d) {
            tr = table.find("tr#" + d);
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
 // console.log(gon.datatable_json);
  // datatable
  datatable = $("#mass_change").dataTable({
    "dom": "<'top'fli>t<'bottom'p><'clear'>",
    "data": gon.datatable_json,
    createdRow: function(row, data, index) {
        row.id = data.code;
        // $(row).attr("data-orig", data.data_type + ";" + data.nm_type + ";" + data.nm_size + ";" + data.nm_min + ";" + data.nm_max);
    },
    "columns": [
      {"data":"code"},
      {"data":"question"},
      {"data":"data_type",
        render: function (data, type, full, meta) {
          return "<input class='numerical' type='radio' value='1' name='question["+full.code +"][data_type]'" + (data == 1 ? " checked": "") + " data-o='"+data+"'>";
        },
        class: "c"
      },
      {"data":"data_type",
        render: function (data, type, full, meta) {
          return "<input class='numerical' type='radio' value='2' name='question["+full.code +"][data_type]'" + (data == 2 ? " checked": "") + " data-o='"+data+"'>";
        },
        class: "c"
      },
      {"data":"nm_type",
        render: function (data, type, full, meta) {           
            return "<select class='conditional' name='question["+full.code +"][numerical][type]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + "><option value='0'" + (data == 0 ? "selected": "") + ">Integer</option>" + 
            "<option value='1'" + (data == "1" ? "selected": "") + ">Float</option></select>";
        },
        class: "c"
      },
      {"data":"nm_size",
        render: function (data, type, full, meta){           
          return "<input class='conditional r' type='number' value='"+data+"' name='question["+full.code +"][numerical][size]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + ">";
        }
      },
      {"data":"nm_min",
        render: function (data, type, full, meta){
          return "<input class='conditional r' type='number' value='"+data+"' name='question["+full.code +"][numerical][min]' data-o='"+data+"'" + (full.data_type !== 2 ? " disabled" : "") + ">";
        }        
      },
      {"data":"nm_max",
        render: function (data, type, full, meta){
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

  // update tooltip for disabled inputs in table
  // $("#mass_change tbody tr td input[disabled='disabled']").tooltip({
  //   selector: "[title]",
  //   container: "body"
  // });
  


  $(datatable).on("change", "input, select", function () {
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
  });

  $(datatable).on("click", ".view-chart", function() {
     console.log("Viewing some chart");
      $.ajax({
        type: "GET",
        dataType: "json",
        data: { dataset_id: dataset_id, question_code: $(this).closest("tr").attr("id") },
        url: view_chart_path,
        success: function (d) {
          preview(d.grouped_meta_data, d.grouped_data);
          
  //           $("body").tooltip({
  //   selector: "[chart]",
  //   container: "body"
  // });
           // console.log(d);
        }
      });
     // def self.dataset_question_data(dataset_id, question_code,  options={})
  });
  $("body").append("<div id='preview' class='preview'></div>");
  var preview = function(meta, data) {
    // data.push(0);
     console.log(meta,data);
    var t = $("#preview");
    t.show();

    var chart = new Highcharts.Chart({

        chart: {
            renderTo: 'preview',
            type: 'column',
            spacingRight: 40,
            events: {
              redraw: function(e) {
                 console.log("sdfsdf");
                 console.log(e, this);
              }
            }
        },

        xAxis: {
          // min:1,
          // max:100,
          // step:12,
          labels: {
            align: "right",
            x:-10
          },   
          startOnTick: true,
          endOnTick: true,
          tickAmount: meta.size+2,
          categories: formatLabel(meta.size, meta.step, meta.min),
          // tickmarkPlacement: 'between '   
        },
        //    labels: {
        //     items: [{
        //         html: "My custom label",
        //         style: {
        //             top: "100%",
        //             left: "100%"
        //         }

        //     }]
        // },
        plotOptions: {
            // series: {
            //   compare: 'value',
        
            // },
            column: {
                groupPadding: 0,
                pointPadding: 0,
                borderWidth: 0
            }
        },

        series: [{
            data: data
            // pointStart: meta.start
        }]

    }, function(e) { 
                   var label = this.renderer.label('1000000000',
                    (this.plotBox.x+this.plotBox.width) - 7 , (this.plotBox.y + this.plotBox.height) + 5)
                        // .attr({
                        //     // fill: "red",
                        //     // padding: 10,
                        //     // r: 5,
                        //     // zIndex: 8
                        // })
                        .css({
                            color:"#606060",
                            cursor:"default",
                            "font-size":"11px",
                            "fill":"#606060"
                        })
                        .add();
                        this.spacing[1] = 100;
                        
                        // console.log(label.width + 10 > 40);
                        // this.options.chart.spacingRight = label.width + 10 > 40 ? label.width + 10 : 40;
                        this.isDirtyBox = true;
                        this.redraw();
       console.log(this,e,label,this.options.chart.spacingRight);

    });
// chart.spacing = []
//    chart.options.chart.spacing = 100;
//                       // chart.isDirtyBox = true;
//     chart.redraw();
    // chart.highcharts().redraw();
    // chart.xAxis[0].update();
    function formatLabel(size, step, start) {
       console.log(size,step,start);
      var v = [];
      for(var i = 0; i < size; ++i) {
         console.log(i);
          // + (i == size-1 ? (" - " + meta.max) : "")
        v.push(Math.round(start+i*step));
      }
       console.log(v);
      return v;
    }
  }
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

});
