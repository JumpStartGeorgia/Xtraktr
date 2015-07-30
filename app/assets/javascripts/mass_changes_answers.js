$(document).ready(function(){

  /* Create an array with the values of all the checkboxes in a column */
  // take from: http://www.datatables.net/examples/plug-ins/dom_sort.html
  $.fn.dataTable.ext.order['dom-checkbox'] = function  ( settings, col )
  {
    return this.api().column( col, {order:'index'} ).nodes().map( function ( td, i ) {
      return $('input[type="checkbox"]', td).prop('checked') ? '1' : '0';
    });
  }

  // catch form submit and pull out all form values from the datatable
  // the post will return will a status message
  $('form#frm-dataset-exclude-answers').submit( function() {
    $('.data-loader').fadeIn('fast');

    $.ajax({
        type: "POST",
        dataType: 'script',
        data: datatable.$('input').serialize(),
        url: $(this).attr('action')
    });

    return false;
  });

  // datatable
  datatable = $('#dataset-exclude-answers').dataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "data": gon.datatable_json,
    "columns": [
      {"data":"code"},
      {"data":"question", "width":"33%"},
      {"data":"answer", "width":"33%"},
      {"data":"exclude", "orderDataType": "dom-checkbox"},
      {"data":"can_exclude", "orderDataType": "dom-checkbox"}
    ],
    "sorting": [],
    // "order": [[0, 'asc']],
    "language": {
      "url": gon.datatable_i18n_url,
      "searchPlaceholder": gon.datatable_search
    },
    "pagingType": "full_numbers",
    "orderClasses": false
  });


  // if data-state = all, select all questions that match the current filter
  // - if not filter -> then all questions are selected
  // else, desfelect all questions that match the current filter
  // - if not filter -> then all questions are deselected
  $('a.btn-select-all').click(function(){
    type = $(this).attr('data-type');
    if ($(this).attr('data-state') == 'all'){
      $(datatable.$('tr', {"filter": "applied"})).find('td :checkbox.' + type + '-input').each(function () {
        $(this).prop('checked', true);
      });
      $(this).attr('data-state', 'none');
    }else{
      $(datatable.$('tr', {"filter": "applied"})).find('td :checkbox.' + type + '-input').each(function () {
        $(this).prop('checked', false);
      });
      $(this).attr('data-state', 'all');
    }

    return false;
  });

});
