var datatable;
var is_dirty = false;

$(document).ready(function(){

  var select = $('select.selectpicker-sort');

  // move to
  select.selectpicker();

  // when select item, move questions
  select.change(function(){


  });


  // if data-state = all, select all questions that match the current filter
  // - if not filter -> then all questions are selected
  // else, desfelect all questions that match the current filter
  // - if not filter -> then all questions are deselected
  $('a.btn-select-all').click(function(){
    if ($(this).attr('data-state') == 'all'){
      $(datatable.$('tr', {"filter": "applied"})).find('td :checkbox').each(function () {
        $(this).prop('checked', true);
      });
      $(this).attr('data-state', 'none');
    }else{
      $(datatable.$('tr', {"filter": "applied"})).find('td :checkbox').each(function () {
        $(this).prop('checked', false);
      });
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

  datatable = $('#dataset-sort').DataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "data": gon.datatable_json,
    // "deferRender": true,
    "columns": [
      {"data":"checkbox", "orderDataType": "dom-checkbox"},
      {"data":"sort_order"},
      {"data":"type"},
      {"data":"name"},
      {"data":"link"}
    ],
    "columnDefs": [
      { className: "text-center", "targets": [ 0, -1 ] }
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
  $('#dataset-sort tfoot input').on('keyup click', function(){
    datatable.column($(this).closest('td').index()).search(this.value, true, false).draw();
  });
  $('#dataset-sort tfoot select').on('change', function(){
    datatable.column($(this).closest('td').index()).search(this.value, true, false).draw();
  });

  // when someone changes something, record that the form is dirty
  $('form input.sort-order').change(function () {
    is_dirty = true;
  });

  // when click on button to view groups items and form is dirty, tell user
  $('a.btn-view-group').click(function(){
    if (is_dirty == true){
      
    }
  });
});
