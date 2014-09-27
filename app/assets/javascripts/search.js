
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
    /*,
    

    "sDom": "<'row'<'col-sm-6'l><'col-sm-6'f>r>t<'row'<'col-sm-6'i><'col-sm-6'p>>",    
    "sPaginationType": "bootstrap",
    "bJQueryUI": true,
    "bProcessing": true,
    "bServerSide": true,
    "bDestroy": true,
    "bAutoWidth": false,
    "sAjaxSource": $('#users-datatable').data('source'),
    "oLanguage": {
      "sUrl": gon.datatable_i18n_url
    },
    "aaSorting": [[2, 'desc']]
    */
  });


});
