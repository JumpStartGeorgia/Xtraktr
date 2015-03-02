var datatable;
$(document).ready(function(){

  // datatable for exclude questions page
  datatable = $('#time-series-questions').dataTable({
    "dom": '<"top"f>t<"bottom"lpi><"clear">',
    "columnDefs": [
      { orderable: false, targets: [0,5] }
    ],
    "order": [[1, 'asc']],
    "language": {
      "url": gon.datatable_i18n_url
    }
  });


});