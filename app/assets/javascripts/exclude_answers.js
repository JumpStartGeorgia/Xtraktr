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
    var form_data = datatable.$('input').serialize();

    $.ajax({
        type: "POST",
        dataType: 'script',
        data: form_data,
        url: $(this).attr('action')
    });

    return false;
  });

  // datatable for exclude answers page
  var datatable = $('#dataset-exclude-answers').dataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "columns": [
      { "orderDataType": "dom-checkbox" },
      null,
      null,
      null
    ],
    "order": [[1, 'asc']],
    "language": {
      "url": gon.datatable_i18n_url,
      "search": "_INPUT_",
      "searchPlaceholder": gon.datatable_search,
      "paginate": {
          "first": " ",
          "previous": " ",
          "next": " ",
          "last": " "
      }
    },
    "pagingType": "full_numbers"
  });


  // if data-state = all, select all questions that match the current filter
  // - if not filter -> then all questions are selected
  // else, desfelect all questions that match the current filter
  // - if not filter -> then all questions are deselected
  $('a.btn-select-all').click(function(){
    if ($(this).attr('data-state') == 'all'){
      $(datatable.$('tr', {"filter": "applied"})).find(':checkbox').each(function () {
        $(this).prop('checked', true);
      });
      $(this).attr('data-state', 'none');
    }else{
      $(datatable.$('tr', {"filter": "applied"})).find(':checkbox').each(function () {
        $(this).prop('checked', false);
      });
      $(this).attr('data-state', 'all');
    }

    return false;
  });

});
