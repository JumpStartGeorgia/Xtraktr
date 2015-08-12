//= require jquery.ui.sortable


var datatable, table_id, list_id, hidden_id, select_id, move_start_index, move_end_index;
var is_dirty = false;

  // make sure the correct row is highlight from the drop down
  function highlight_move_after_row(){
    var id = $('option:selected', select_id).val();

    // remove previous selection
    $('tbody tr', table_id).removeClass('move-after');

    if (id != ''){
      // add class to selected item
      $('tbody tr > td > input[value="' + id + '"]', table_id).closest('tr').addClass('move-after');
    }

  }


$(document).ready(function(){

  select_id = $('select#move-to');
  select_id.selectpicker();

  form_id = $('form');
  table_id = $('#dataset-sort');
  list_id = $('.bootstrap-select .dropdown-menu.inner');
  hidden_id = $('#hidden-inputs');


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


  /* Create an array with the values of all the checkboxes in a column */
  // take from: http://www.datatables.net/examples/plug-ins/dom_sort.html
  $.fn.dataTable.ext.order['dom-checkbox'] = function  ( settings, col )
  {
    return this.api().column( col, {order:'index'} ).nodes().map( function ( td, i ) {
      return $('input[type="checkbox"]', td).prop('checked') ? '1' : '0';
    });
  }

  datatable = table_id.DataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "data": gon.datatable_json,
    // "deferRender": true,
    "columns": [
      {"data":"checkbox"},
      {"data":"type"},
      {"data":"name"},
      {"data":"link"}
    ],
    "columnDefs": [
      { className: "text-center", "targets": [ 0, -1 ] }
    ],
    "sort": false, // do not allow sorting
    "language": {
      "url": gon.datatable_i18n_url,
      "searchPlaceholder": gon.datatable_search
    },
    "pagingType": "full_numbers",
    "orderClasses": false
  });

  // search boxes in footer
  $('tfoot input', table_id).on('keyup click', function(){
    datatable.column($(this).closest('td').index()).search(this.value, true, false).draw();
  });
  $('tfoot select', table_id).on('change', function(){
    datatable.column($(this).closest('td').index()).search(this.value, true, false).draw();
  });


  // when the table re-draws, make sure the correct row is highlighted from the drop down
  table_id.on( 'draw.dt', function () {
    highlight_move_after_row();
  });

  // when select changes, highlight the row they selected
  select_id.change(function(){
    highlight_move_after_row();
  });

  // when checkbox state changes, update the drop down to make sure the correct items are showing
  // - have to adjust table index to account for pagination so select correct item in drop down
  table_id.on('change', ':checkbox', function(){
    console.log("---------");
    var row_index = $(this).closest('tr').index();
    var select_index = datatable.page.info().start + row_index;


    console.log("index = " + select_index);
    if($(this).is(':checked')){
      console.log("- hiding");
      $('li:eq(' + select_index + ')', list_id).hide();
      $(this).closest('tr').addClass('to-move');
    }else{
      console.log("- showing");
      $('li:eq(' + select_index + ')', list_id).show();
      $(this).closest('tr').removeClass('to-move');
    }
  });

  // when move items submit btn clicked,
  // - move the selected items in the drop down, table and the hidden inputs
  // - then deselect the selected items
  $('.move-items-submit').click(function(){
    var base_index;
    var i=0;
    var value = select_id.val();
    var items_to_move = $(datatable.$('tr')).find('td :checkbox:checked');
    var items_to_move_length = items_to_move.length;
    var items_to_move_ids = [];
    var items_to_move_indexes = [];
    var select_items =[];
    var json_items = [];
    var hidden_items = [];
    // get the ids of the select items
    for (i;i<items_to_move_length;i++){
      items_to_move_ids.push($(items_to_move[i]).val());
      items_to_move_indexes.push($('div[data-id="' + items_to_move_ids[i] + '"]', hidden_id).index());
    }

    i = 0;

    // pull out all records that need to be moved
    for (i;i<items_to_move_length;i++){
      // select
      select_items.push($($('option', select_id)[items_to_move_indexes[i] + 1 - i]).remove());

      // json data
      json_items.push(gon.datatable_json.splice(items_to_move_indexes[i]-i,1)[0]);

      // hidden
      hidden_items.push($($('div', hidden_id)[items_to_move_indexes[i] - i]).remove());
    }

    // then insert them all in after the base index
    i = 0;
    base_index = $('option:selected', select_id).index()-1;
    for (i;i<items_to_move_length;i++){
      // select
      $(select_items[i]).insertAfter($('option:eq(' + (base_index + 1 + i) + ')', select_id));

      // json data
      gon.datatable_json.splice((base_index+1+i), 0, json_items[i]);

      // hidden
      $(hidden_items[i]).insertAfter($('div:eq(' + (base_index + i) + ')', hidden_id));
    }

    // reset the select value and refresh the selectpicker
    select_id.val('');
    select_id.selectpicker('refresh');
    // redraw the table, keeping the current pagination
    datatable.clear();
    datatable.rows.add(gon.datatable_json);
    datatable.draw(false);

    console.log('selected value was ' + value);
    // if the selected value is showing the table, highlight it
    var tr = $('tbody tr > td > input[value="' + value + '"]').closest('tr');
    if (tr.length == 1){
      tr.addClass('move-after');
      // add to-move for the rows following the move after
      // if the row is showing
      var i=0;
      var index;
      for(i;i<items_to_move_length;i++){
        index = tr.index() + 1 + i;
        if (index < datatable.page.info().length){
          $('tbody tr:eq(' + index + ')', table_id).addClass('to-move');
        }
      }
    }

    // now turn off
    setTimeout(function(){
      $('tbody tr').removeClass('move-after').removeClass('to-move');
    }, 2000);


  });




  // // when someone changes something, record that the form is dirty
  // $('form input.sort-order').change(function () {
  //   is_dirty = true;
  // });

  // // when click on button to view groups items and form is dirty, tell user
  // $('a.btn-view-group').click(function(){
  //   if (is_dirty == true){

  //   }
  // });


  // catch form submit and set the sort order = to index value
  form_id.submit(function() {
    var hidden_fields = $('#hidden-inputs > div');
    var hidden_length = hidden_fields.length;
    var i=0;
    for (i;i<hidden_length;i++){
      $('.input-sort-order', $(hidden_fields[i])).val(i);
    }

    $.ajax({
      type: "POST",
      dataType: 'script',
      data: $(this).serialize(),
      url: $(this).attr('action')
    });

    return false;
  });


  // make rows drag/drop
  $('tbody', table_id).sortable({
    cursor: "move",
    // record the start index
    start: function(e, ui){
      console.log('-----------');
      console.log('start!');
      move_start_index = $(ui.item).index();
      console.log('start at ' + move_start_index);
      $(ui.item).addClass('to-move');
    },
    // if the sorting stops, turn off the highlight
    deactivate: function(e,ui){
      $(ui.item).removeClass('to-move');
    },
    // record the end index and then update all of the other items to match
    update: function(e,ui){
      console.log('update');
      move_end_index = $(ui.item).index();
      console.log('end at ' + move_end_index);
      console.log('-----------');

      // adjust indexes based on pagination values
      var page = datatable.page.info();
      if (page.start != 0){
        move_start_index += page.start;
        move_end_index += page.start;
      }
      console.log('start index after adjustment ' + move_start_index);
      console.log('end index after adjustment ' + move_end_index);

      // -- drop down
      if (move_end_index == 0){
        $('option:eq(' + (move_start_index + 1) + ')', select_id).insertBefore($('option:eq(1)', select_id));
      }else if (move_end_index < move_start_index){
        // when moving up, use insertbefore
        $('option:eq(' + (move_start_index+1) + ')', select_id).insertBefore($('option:eq(' + (move_end_index + 1)  + ')', select_id));
      }else{
        // when moving down, use insertafter
        $('option:eq(' + (move_start_index + 1) + ')', select_id).insertAfter($('option:eq(' + (move_end_index + 1)  + ')', select_id));
      }

      // -- table row
      gon.datatable_json.splice((move_end_index), 0, gon.datatable_json.splice(move_start_index,1)[0]);

      // -- hidden inputs
      if (move_end_index == 0){
        $('div:eq(' + move_start_index + ')', hidden_id).insertBefore($('div:eq(' + move_end_index + ')', hidden_id));
      }else if (move_end_index < move_start_index){
        // when moving down, use insertbefore
        $('div:eq(' + move_start_index + ')', hidden_id).insertBefore($('div:eq(' + move_end_index + ')', hidden_id));
      }else{
        // when moving down, use insertafter
        $('div:eq(' + move_start_index + ')', hidden_id).insertAfter($('div:eq(' + move_end_index + ')', hidden_id));
      }

      // reset the select value and refresh the selectpicker
      select_id.val('');
      select_id.selectpicker('refresh');
      // redraw the table, keeping the current pagination
      datatable.clear();
      datatable.rows.add(gon.datatable_json);
      datatable.draw(false);

      // highlight row that was moved so user can see what they did
      $('tbody tr:eq(' + (move_end_index-page.start) + ')', table_id).addClass('to-move');
      // now turn off
      setTimeout(function(){
        $('tbody tr').removeClass('move-after').removeClass('to-move');
      }, 2000);

    }
  });

});
