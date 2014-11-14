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
    var form_data = datatable.$('input').serialize();

    $.ajax({
        type: "POST",
        dataType: 'script',
        data: form_data,
        url: $(this).attr('action')
    });

    return false;
  });

  // datatable for exclude questions page
  datatable = $('#dataset-exclude-questions').dataTable({
    "dom": '<"top"f>t<"bottom"lpi><"clear">',
    "columns": [
      { "orderDataType": "dom-checkbox" },
      null,
      null
    ],
    "order": [[1, 'asc']],
    "language": {
      "url": gon.datatable_i18n_url
    }
  });


  // select all questions
  $('a.btn-select-all').click(function(){
//    $('#dataset-exclude-questions tr td input[type="checkbox"]').prop('checked', true);
    $(datatable.fnGetNodes()).find(':checkbox').each(function () {
      $(this).prop('checked', true);
    });
    return false;
  });

  // de-select all questions
  $('a.btn-select-none').click(function(){
//    $('#dataset-exclude-questions tr td input[type="checkbox"]').prop('checked', false);

    $(datatable.fnGetNodes()).find(':checkbox').each(function () {
      $(this).prop('checked', false);
    });


    return false;
  });

});
