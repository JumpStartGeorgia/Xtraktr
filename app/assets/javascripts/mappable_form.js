// get the first item in input that has the key with the provided value
function getFirstItem(input, key, value) {
  for(var i = 0; i < input.length; i++) {
    if(input[i][key] === value)
      return input[i];
  }
}
// update the list to match question answers to shape names
function update_mappable_matching_list(){
  var question = getFirstItem(gon.questions, 'id', $('select#question').val());
  var shapeset = getFirstItem(gon.shapesets, 'id', $('select#shapeset').val());

  var question_text = $('select#question option:selected').html();
  var shapeset_text = $('select#shapeset option:selected').html();

  // update the header/text
  $('#mappable-matching > h2').html($('#mappable-matching > h2').data('orig').replace('[question]', question_text).replace('[shapeset]', shapeset_text));
  $('#mappable-matching > p').html($('#mappable-matching >p ').data('orig').replace('[question]', question_text).replace('[shapeset]', shapeset_text));

  // create the html for mapping
  // ul li answer - select of shape sets
  var html = '';
  var selected = '';
  html += '<ul class="list-unstyled">';
  for(var i=0; i<question.answers.length;i++){
    html += '<li class="row">';
    html +=  '<div class="col-sm-6 match-dataset">';
    html +=    question.answers[i].text;
    html +=    '<input type="hidden" name="map[answer][]" value="' + question.answers[i].id + '"/>';
    html +=  '</div>';
    html +=  '<div class="col-sm-6 match-shapeset">';
    html +=    '<select name="map[shapeset][]" class="selectpicker-matching" data-width="100%" data-live-search="true" title="">';
    html +=      '<option value=""></option>';
    for(var j=0; j<shapeset.names.length;j++){
      // if the answer matches the shapeset name, mark it as selected by default
      selected = '';
      if (question.answers[i].text == shapeset.names[j]){
        selected='selected="selected"';
      }
      html +=    '<option value="' + shapeset.names[j] + '" ' + selected + '>' + shapeset.names[j] + '</option>';
    }
    html +=    '</select>';
    html +=  '</div>';
    html += '</li>';
  }
  html += '</ul>';

  $('#mappable-matching #mappable-matching-items').html(html);

  // turn the selectpicker on for the shape names
  $('select.selectpicker-matching').selectpicker();    

  // when page loads show which shapesets are not selected
  $('select.selectpicker-matching').each(function(){
    if ($(this).val() == ''){
      highlight_unselected_match(this);
    }
  });
}

function highlight_unselected_match(ths_select){
  console.log('select val = ' + $(ths_select).val());
  if ($(ths_select).val() == ''){
    console.log(' - adding class');
    $(ths_select).closest('.match-shapeset').addClass('no-match');
  }else{
    console.log(' - removing class');
    $(ths_select).closest('.match-shapeset').removeClass('no-match');
  }
}

$(document).ready(function() {

  if (gon.shapesets && gon.shapesets.length > 0 && gon.questions && gon.questions.length > 0){
    $('select.selectpicker-mappable').selectpicker();    

    // if selection changes, update the list for matching answers to shapes
    $('select.selectpicker-mappable').change(function(){
      update_mappable_matching_list();
    });

    // load the correct question answers and shapeset when the page loads
    update_mappable_matching_list();

  }else if (gon.mappable_form_edit){
    // turn the selectpicker on for the shape names
    $('select.selectpicker-matching').selectpicker();    

    // when page loads show which shapesets are not selected
    $('select.selectpicker-matching').each(function(){
      if ($(this).val() == ''){
        highlight_unselected_match(this);
      }
    });

  }

  // if shapeset is not selected for match, highlight it so easy to find
  $('form#frm-mappable-question').on('change', 'select.selectpicker-matching', function(){
    highlight_unselected_match(this);
  });

});