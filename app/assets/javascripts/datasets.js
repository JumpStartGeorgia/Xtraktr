$(function() {
  // when start/end date changes, set the max/min date of the opposite date
  function customRange(dates) { 
    if (this.id == 'dataset_start_gathered_at') { 
      $('input#dataset_end_gathered_at').datepicker('option', 'minDate', dates || null); 
    } 
    else { 
      $('input#dataset_start_gathered_at').datepicker('option', 'maxDate', dates || null); 
    } 
  }

  // load the datepicker and selectpicker libraries for a report row
  function load_report_row(this_row){
    // datepicker
    var date_input = $(this_row).find("input.dataset-report-released-at");
    $(date_input).datepicker({
      dateFormat: 'yy-mm-dd',
      changeYear: true,
      changeMonth: true,
      yearRange: 'c-20:c+0'
    });
    if ($(date_input).val() != '')
    {
      $(date_input).datepicker("setDate", new Date($(date_input).val()));
    }


    // selectpicker
    $(this_row).find('select.selectpicker-report-language').select2({width:'element'});
  }


  // start gathered at
  $("input#dataset_start_gathered_at").datepicker({
    dateFormat: 'yy-mm-dd',
    onSelect: customRange,
    changeYear: true,
    changeMonth: true,
    yearRange: 'c-20:c+0'
  });
  if (gon.start_gathered_at !== undefined && gon.start_gathered_at.length > 0)
  {
    $("input#dataset_start_gathered_at").datepicker("setDate", new Date(gon.start_gathered_at));
  }
  if (gon.end_gathered_at !== undefined && gon.end_gathered_at.length > 0)
  {
    $('input#dataset_start_gathered_at').datepicker('option', 'maxDate', new Date(gon.end_gathered_at));
  }

  // end gathered at
  $("input#dataset_end_gathered_at").datepicker({
    dateFormat: 'yy-mm-dd',
    onSelect: customRange,
    changeYear: true,
    changeMonth: true,
    yearRange: 'c-20:c+0'
  });
  if (gon.end_gathered_at !== undefined && gon.end_gathered_at.length > 0)
  {
    $("input#dataset_end_gathered_at").datepicker("setDate", new Date(gon.end_gathered_at));
  }
  if (gon.start_gathered_at !== undefined && gon.start_gathered_at.length > 0)
  {
    $('input#dataset_end_gathered_at').datepicker('option', 'minDate', new Date(gon.start_gathered_at));
  }
     
  // released at
  $("input#dataset_released_at").datepicker({
    dateFormat: 'yy-mm-dd',
    changeYear: true,
    changeMonth: true,
    yearRange: 'c-20:c+0'
  });
  if (gon.released_at !== undefined && gon.released_at.length > 0)
  {
    $("input#dataset_released_at").datepicker("setDate", new Date(gon.released_at));
  }

  // when adding reports - add datepicker and selectpicker
  $('table#dataset-reports tbody').on('cocoon:before-insert', function(e, insertedItem) {
    load_report_row(insertedItem);
  });  

  // process all reports when page loads
  if ($('table#dataset-reports tbody tr').length > 0){
    $('table#dataset-reports tbody tr').each(function(){
      load_report_row(this);
    });
  }


});