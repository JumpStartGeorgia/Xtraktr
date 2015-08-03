var datatable;
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
  $('form#frm-dataset-exclude-questions').submit( function() {
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
  datatable = $('#dataset-exclude-questions').dataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "data": gon.datatable_json,
    "columns": [
      {"data":"code"},
      {"data":"text", "width":"40%"},
      {"data":"exclude", "orderDataType": "dom-checkbox"},
      {"data":"download", "orderDataType": "dom-checkbox"}
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

  // update tooltip for disabled inputs in table
  // $('#dataset-exclude-questions tbody tr td input[disabled="disabled"]').tooltip('fixTitle');
  $('#dataset-exclude-questions tbody tr td input[disabled="disabled"]').tooltip({
    selector: '[title]',
    container: 'body'
  });


  // if data-state = all, select all questions that match the current filter
  // - if not filter -> then all questions are selected
  // else, desfelect all questions that match the current filter
  // - if not filter -> then all questions are deselected
  $('a.btn-select-all').click(function(){
    var i=0;
    var type = $(this).attr('data-type');
    var rows = $(datatable.$('tr', {"filter": "applied"})).find('td :checkbox.' + type + '-input');
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

});
