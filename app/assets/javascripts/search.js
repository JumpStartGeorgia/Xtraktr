$(document).ready(function(){
  $.extend( $.fn.dataTableExt.oStdClasses, {
      "sWrapper": "dataTables_wrapper form-inline"
  });


  $('#users-datatable').dataTable({
    "serverSide": true,
    "ajax": $('#users-datatable').data('source'),
    "order": [[2, 'desc']],
    "language": {
      "url": gon.datatable_i18n_url
    }
  });


});
