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

  // start gathered at
  $("input#dataset_start_gathered_at").datepicker({
    dateFormat: 'yy-mm-dd',
    onSelect: customRange
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
    onSelect: customRange
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
    dateFormat: 'yy-mm-dd'
  });
  if (gon.released_at !== undefined && gon.released_at.length > 0)
  {
    $("input#dataset_released_at").datepicker("setDate", new Date(gon.released_at));
  }

});