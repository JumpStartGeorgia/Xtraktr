$(document).ready(function(){
  $.extend( $.fn.dataTableExt.oStdClasses, {
      "sWrapper": "dataTables_wrapper form-inline"
  });

  $('#users-datatable').dataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "processing": true,
    "serverSide": true,
    "ajax": $('#users-datatable').data('source'),
    "order": [[3, 'desc']],
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
    "columnDefs": [
      { orderable: false, targets: [-1] }
    ],
    "pagingType": "full_numbers"
  });


  $('#dataset-datatable').dataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "processing": true,
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
    "columnDefs": [
      { orderable: false, "targets": [5,7] }
    ],
    "pagingType": "full_numbers"
  });

  $('#time-series-datatable').dataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "processing": true,
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
    "columnDefs": [
      { orderable: false, "targets": [1,5] }
    ],
    "pagingType": "full_numbers"
  });

  $('#shapeset-datatable').dataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "processing": true,
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
    "columnDefs": [
      { orderable: false, "targets": [5] }
    ],
    "pagingType": "full_numbers"
  });

  $('#highlights-datatable').dataTable({
    "dom": '<"top"fli>t<"bottom"p><"clear">',
    "processing": true,
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
    "columnDefs": [
      { orderable: false, "targets": [-1] }
    ],
    "pagingType": "full_numbers"
  });


});
