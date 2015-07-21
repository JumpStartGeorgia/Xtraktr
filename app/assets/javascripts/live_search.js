var group_ids = [];

jQuery.fn.unique_items = function()
{
  var n = {},r=[];
  for(var i = 0; i < this.length; i++) 
  {
    if (!n[this[i]]) 
    {
      n[this[i]] = true; 
      r.push(this[i]); 
    }
  }
  return r;
}

/*
highlight v5
Highlights arbitrary terms.
<http://johannburkard.de/blog/programming/javascript/highlight-javascript-text-higlighting-jquery-plugin.html>
*/

jQuery.fn.highlight = function(pat) {
 function innerHighlight(node, pat) {
  var skip = 0;
  if (node.nodeType == 3) {
   var pos = node.data.toUpperCase().indexOf(pat);
   pos -= (node.data.substr(0, pos).toUpperCase().length - node.data.substr(0, pos).length);
   if (pos >= 0) {
    var spannode = document.createElement('span');
    spannode.className = 'highlight';
    var middlebit = node.splitText(pos);
    var endbit = middlebit.splitText(pat.length);
    var middleclone = middlebit.cloneNode(true);
    spannode.appendChild(middleclone);
    middlebit.parentNode.replaceChild(spannode, middlebit);
    skip = 1;
   }
  }
  else if (node.nodeType == 1 && node.childNodes && !/(script|style)/i.test(node.tagName)) {
   for (var i = 0; i < node.childNodes.length; ++i) {
    i += innerHighlight(node.childNodes[i], pat);
   }
  }
  return skip;
 }
 return this.length && pat && pat.length ? this.each(function() {
  innerHighlight(this, pat.toUpperCase());
 }) : this;
};

jQuery.fn.removeHighlight = function() {
 return this.find("span.highlight").each(function() {
  this.parentNode.firstChild.nodeName;
  with (this.parentNode) {
   replaceChild(this.firstChild, this);
   normalize();
  }
 }).end();
};

function run_search(){
    // Retrieve the input field text and reset the count to zero
  var filter = $('#codebook input#filter').val();
  var filter_by = $('#codebook input[type="radio"]:checked').val();
  // remove all highlights
  $("#codebook").removeHighlight();

  // Loop through the comment list
  if (filter != undefined && filter != ''){
    $("#codebook li.question-item").each(function(){
      // determine what text to search in
      var filter_selector = $(this).find('.details .default-search');
      if (filter_by == 'q'){
        filter_selector = $(this).find('.question');
      }else if (filter_by == 'code'){
        filter_selector = $(this).find('.question-code');
      }else if (filter_by == 'ans'){
        filter_selector = $(this).find('.answers ul');
      }

      // If the list item does not contain the text phrase, hide it
      if ($(filter_selector).text().search(new RegExp(filter, "i")) < 0) {
        $(this).hide();

      // Show the list item if the phrase matches
      } else {
        $(filter_selector).highlight(filter);
        $(this).show();
      }
    });

    // show group header if questions in group are showing
    // - get list of groups that need to be shown from visible questions
    var search_group_ids = [];
    // cannot use :visible selector for li might be nested in another li that is no visible
    // so have to look by using list-item
    $('#codebook li.question-item[style*="list-item"] .question-link').each(function(){
      if ($(this).data('group') != ''){
        search_group_ids.push($(this).data('group'));
      }
      if ($(this).data('subgroup') != ''){
        search_group_ids.push($(this).data('subgroup'));
      }
    });
    // - get unique list of group ids to show
    search_group_ids = $(search_group_ids).unique_items();

    // - show correct groups
    $('#codebook li.group-item').each(function(){
      if (search_group_ids.indexOf($(this).data('id')) == -1){
        $(this).hide();
      }else{
        $(this).show();
      }
    });
    // - show correct jumpto options
    $('#codebook select.selectpicker-group option').each(function(){
      if (search_group_ids.indexOf($(this).attr('value')) == -1){
        $(this).prop('disabled', true);
      }else{
        $(this).prop('disabled', false);
      }
    });
    $('#codebook select.selectpicker-group').selectpicker('refresh');

  }else{
    $("#codebook li.question-item, #codebook li.group-item").show();
    $('#codebook select.selectpicker-group option').prop('disabled', false);
    $('#codebook select.selectpicker-group').selectpicker('refresh');
  }  


}

$(document).ready(function(){
  $("#codebook input#filter").keyup(debounce(function() {
    run_search();
  }, 500));

  // re-run search when filter option changes
  $('#codebook input[type="radio"]').change(function(){
    // if search text exists, run search
    if ($('#codebook input#filter').val().length > 0){
      run_search();
    }
  });

  // group jumpto 
  $('#codebook select.selectpicker-group').selectpicker();

  // get unique list of group ids
  // - used during search so knows which groups to turn on and off
  $('#codebook select.selectpicker-group option').map(function(){
    if ($(this).attr('value') != ''){
      return group_ids.push($(this).attr('value'));
    }
  })

  // when select group, go to it
  $('#codebook select.selectpicker-group').change(function(){
    $('body').animate({ scrollTop: $('#codebook .group-item[data-id="' + $(this).val() + '"]').offset().top - $('nav.navbar').height() }, 1500);
    // reset select to default value
    $(this).selectpicker('val', '');
  });
  // when click on group under question link, go to it
  $('#codebook .question-link-groups .question-link-group').click(function(){
    $('body').animate({ scrollTop: $('#codebook .group-item[data-id="' + $(this).data('id') + '"]').offset().top - $('nav.navbar').height() }, 1500);
  });
});

