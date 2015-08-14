var datatable, form_id;

$(document).ready(function(){
  form_id = $('form.time_series_group');

  if (form_id.length > 0){
    // show the description example if include in charts is true
    function show_description_ex(){
      if ($('input[name="time_series_group[include_in_charts]"]:checked', form_id).val() == 'true'){
        // add description text and show example
        var desc = $('input.main-description', form_id).val();
        if (desc == ''){
          desc = gon.insert_description_text;
        }
        $('#chart-description-ex').html($('#chart-description-ex').data('text').replace('[description]', desc));
        $('#chart-description-container').fadeIn();
      }else{
        // hide example
        $('#chart-description-container').fadeOut();
      }
    }

    // if chart title is true, show the example description
    $('input[name="time_series_group[include_in_charts]"]', form_id).change(function(){
      show_description_ex();
    });
    // show description ex when page loads if needed
    show_description_ex();

    // as the description changes, update the chart description example
    // only need this if the include in charts is true
    $("input.main-description", form_id).keyup(debounce(function() {
      if ($('form input[name="time_series_group[include_in_charts]"]:checked').val() == 'true'){
        var desc = $(this).val();
        if (desc == ''){
          desc = gon.insert_description_text;
        }
        $('#chart-description-ex').html($('#chart-description-ex').data('text').replace('[description]', desc));
      }
    }, 250));

    // selectpicker
    $('select.selectpicker-groups', form_id).select2({width:'element'});


    /* Create an array with the values of all the checkboxes in a column */
    // take from: http://www.datatables.net/examples/plug-ins/dom_sort.html
    $.fn.dataTable.ext.order['dom-checkbox'] = function  ( settings, col )
    {
      return this.api().column( col, {order:'index'} ).nodes().map( function ( td, i ) {
        return $('input[type="checkbox"]', td).prop('checked') ? '1' : '0';
      });
    }

    // if data-state = all, select all questions that match the current filter
    // - if not filter -> then all questions are selected
    // else, desfelect all questions that match the current filter
    // - if not filter -> then all questions are deselected
    $('a.btn-select-all').click(function(){
      var i=0;
      var rows = $(datatable.$('tr', {"filter": "applied"})).find('td :checkbox');
      var rows_length = rows.length;
      var state_all = $(this).attr('data-state') == 'all';
      for(i;i<rows_length;i++){
        $(rows[i]).prop('checked', state_all).trigger('change');
      }
      if (state_all){
        $(this).attr('data-state', 'none');
      }else{
        $(this).attr('data-state', 'all');
      }

      return false;
    });

    // get the questions for the selected parent group
    function get_group_questions(){
      var start = Date.now();

      // turn on the loader
      $('#group-questions .data-loader', form_id).fadeIn('fast');

      $.ajax({
        type: 'POST',
        url: gon.group_questions_path,
        data: {group_id: $('select#time_series_group_parent_id', form_id).val()},
        dataType: 'json'
      }).done(function (data) {
        var now = Date.now();

        // create checkbox
        var checked;
        $.each(data, function(question_index, question){
          if ($('#hidden-table-inputs input#assigned-question-' + question.id, form_id).length > 0 || question.selected == true){
            checked = "checked='checked'";
          }else{
            checked = "";
          }

          question.checkbox = "<input id='time_series_time_series_time_series_questions_attributes_" + question_index + "_id' name='time_series[time_series_questions_attributes][" + question_index + "][id]' type='hidden' value='" + question.id + "'><input class='question-selected-input' name='time_series[time_series_questions_attributes][" + question_index + "][selected]' type='checkbox' value='true' " + checked + ">";
        });


        // if table already exists, clear and reload data
        now = Date.now();
        if (datatable != undefined){
          datatable.clear();
          datatable.rows.add(data);
          datatable.draw();
        }else{
          // create datatable
          datatable = $('#time-series-group-questions').DataTable({
            "dom": '<"top"fli>t<"bottom"p><"clear">',
            "data": data,
            // "deferRender": true,
            "columns": [
              {"data":"checkbox", "orderDataType": "dom-checkbox"},
              {"data":"original_code"},
              {"data":"text"}
            ],
            "columnDefs": [
              { className: "text-center", "targets": [ 0 ] }
            ],
            "sorting": [],
            "language": {
              "url": gon.datatable_i18n_url,
              "searchPlaceholder": gon.datatable_search
            },
            "pagingType": "full_numbers",
            "orderClasses": false
          });

          // search boxes in footer
          $('#time-series-group-questions tfoot input').on('keyup click', function(){
              datatable.column($(this).closest('td').index()).search(this.value, true, false).draw();
          });
        }


      }).always(function () {
        // hide the loader
        $('#group-questions .data-loader', form_id).fadeOut('fast');
      });
    }

    // when the group changes, update the group questions
    $('select#time_series_group_parent_id', form_id).change(function(){
      get_group_questions();

      // update the explanation text
      if ($(this).val() == ''){
        $('#group-questions #group-question-explanation').html($('#group-questions #group-question-explanation').data('default'));
      }else{
        $('#group-questions #group-question-explanation').html($('#group-questions #group-question-explanation').data('subgroup').replace('[group]', $('form select#time_series_group_parent_id option:selected').text()));
      }
    });

    // when page loads get the group questions
    get_group_questions();


    // when form submits, get all checkboxes from datatable and then submit
    // - have to do this because loading data via js and so dom does not know about all inputs
    form_id.submit(function(){
      // show data loader
      $(this).find('> .data-loader').fadeIn('fast');

      // empty out what was there
      $('#hidden-table-inputs', this).empty();

      // get all inputs from table and add to form
      datatable.$('input').each(function(){
        $(this).clone().appendTo('#hidden-table-inputs', this);
      });

    });


  }


  // index page
  if ($('table#group-datatable').length > 0){
    // when link is clicked populate the modal and then show it
    $('a.questions').click(function(e){
      e.preventDefault();
      e.stopPropagation();
      var ths = $(this);
      var group = ths.closest('tr').find('td:eq(0)').text().trim();
      var subgroup = ths.closest('tr').find('td:eq(1)').text().trim();

      if (subgroup != ''){
        group += ' / ' + subgroup;
      }
      modal($('#questions-popup').html(),
        {
          position:'center',
          before: function(t)
          {
            t.find('.header').html(t.find('.header').data('title').replace('[group]', group));
            t.find('.text').html(ths.closest('td').find('.group-questions').html());
          }
        }
      );

    });


    // datatable
    datatable = $('#group-datatable').dataTable({
      "dom": '<"top"fli>t<"bottom"p><"clear">',
      "sorting": [],
      "columnDefs": [
        { orderable: false, "targets": [-2,-1] }
      ],
      "language": {
        "url": gon.datatable_i18n_url,
        "searchPlaceholder": gon.datatable_search
      },
      "pagingType": "full_numbers",
      "orderClasses": false
    });

  }
});
