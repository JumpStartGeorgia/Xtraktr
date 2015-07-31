var datatable, table_id, list_id, hidden_id, select_id;
var is_dirty = false;

  // make sure the correct row is highlight from the drop down
  function highlight_move_after_row(){
    var index = $('option:selected', select_id).index()-1;
    var row_index = index - datatable.page.info().start;

    // remove previous selection
    $('tbody tr').removeClass('move-after');

    // add class to selected item
    // - is possible that row index is negative or greater than the number of rows on page -> ignore
    if (row_index > -1 && row_index < datatable.page.info().length){
      $('tbody tr:eq(' + row_index + ')').addClass('move-after');
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
    console.log('table is redrawing');
      
    highlight_move_after_row();
  });

  // when select changes, highlight the row they selected
  select_id.change(function(){
    console.log('form select change');

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
    var items_to_move = $(':checkbox:checked', table_id);
    var items_to_move_length = items_to_move.length;
    var row_index;
    var row_indexes = [];
    var index_before_offset = 0;
    var base_index_offset;


    console.log('-----------');
    for(i;i<items_to_move_length;i++){
      console.log(' -- ');

      // get base_index because it might have moved
      base_index = $('option:selected', select_id).index()-1;
      console.log('base = ' + base_index + '; ' + $('option:selected', select_id).text() + '; ' + $('option:selected', select_id).attr('value'));
      console.log($('tbody tr:eq(' + base_index + ')', table_id))

      // get index to the row this checkbox is in
      row_index = $(items_to_move[i]).closest('tr').index();

      // if the row index is < base index, need to decrease row index to account for base index being moved up
      // if row index > base index, need to add a base index offset
      if (row_index < base_index){
        row_index -= index_before_offset;
        row_indexes.push(base_index - index_before_offset + i);
        index_before_offset += 1;
        base_index_offset = 0;
      }else{
        base_index_offset = 1;
        row_indexes.push(base_index + base_index_offset + i);
      }


      console.log('row = ' + row_index + '; ' + $('option[value="' + $(items_to_move[i]).val() + '"]').text() + '; ' + $(items_to_move[i]).val());
      console.log($('tbody tr:eq(' + row_index + ')', table_id))

      // move it to after the base_index
      // -- drop down
      $('option:eq(' + (row_index + 1) + ')', select_id).insertAfter($('option:eq(' + (base_index + 1 + i) + ')', select_id));
      // use selectpicker refresh to redraw the list in the correct order - happens after this loop is done
      // $('li:eq(' + row_index + ')', list_id).insertAfter($('li:eq(' + (base_index + i) + ')', list_id));
      // -- table row
      //$('tbody tr:eq(' + row_index + ')', table_id).insertAfter($('tbody tr:eq(' + (base_index + i) + ')', table_id));
      console.log('gon base index = ');
      console.log(gon.datatable_json[base_index+base_index_offset+i]);
      console.log('gon move index = ');
      console.log(gon.datatable_json[row_index]);
      gon.datatable_json.splice((base_index+base_index_offset+i), 0, gon.datatable_json.splice(row_index,1)[0]);

      // -- hidden inputs
      $('div:eq(' + row_index + ')', hidden_id).insertAfter($('div:eq(' + (base_index + i) + ')', hidden_id));

      // // de-select
      // // - trigger checkbox change so list is updated
      // $(items_to_move[i]).prop('checked', false).trigger('change');
    }
    // reset the select value and refresh the selectpicker
    select_id.val('');
    select_id.selectpicker('refresh');
    // $('tbody tr').removeClass('move-after');
    // redraw the table, keeping the current pagination
    // datatable.rows().invalidate().draw(false);
    datatable.clear();
    datatable.rows.add(gon.datatable_json);
    datatable.draw(false);


    // re-highlight the table rows for a moment so user can see what happened
    row_index = $('option[value="' + value + '"]', select_id).index() - 1 - datatable.page.info().start;
    console.log('row index = ' + row_index + '; page length = ' + datatable.page.info().length);

    // add class to selected item
    // - is possible that row index is negative or greater than the number of rows on page -> ignore
    if (row_index > -1 && row_index < datatable.page.info().length){
      $('tbody tr:eq(' + row_index + ')', table_id).addClass('move-after');
    }
    var i=0;
    var row_indexes_length = row_indexes.length;
    console.log(row_indexes);
    for (i;i<row_indexes_length;i++){
      $('tbody tr:eq(' + row_indexes[i] + ')', table_id).addClass('to-move');
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


});
