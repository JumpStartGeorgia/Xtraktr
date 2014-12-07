var datatable;
$(document).ready(function(){

  // datatable for exclude questions page
  datatable = $('#dataset-questions').dataTable({
    "dom": '<"top"f>t<"bottom"lpi><"clear">',
    "aoColumnDefs": [
      { 'bSortable': false, 'aTargets': [ -1 ] }
     ],
    "language": {
      "url": gon.datatable_i18n_url
    }
  });


});
