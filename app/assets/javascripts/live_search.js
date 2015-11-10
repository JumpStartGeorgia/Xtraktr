var group_ids = [];
var codebook, li_items, li_length;

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
  // Retrieve the input field text
  var filter = $('#codebook input#filter').val();
  var filter_by = $('#codebook input[type="radio"]:checked').val();
  var regexp = new RegExp(filter, "i");
  var filter_selector;

  // remove all highlights
  codebook.removeHighlight();

  // Loop through the list
  if (filter != undefined && filter != ''){
    var i=0;
    var ths;
    for (i; i < li_length; i++){
      ths = li_items[i];
      // determine what text to search in
      filter_selector = $('.details .default-search', ths);
      if (filter_by != ''){
        if (filter_by == 'q'){
          filter_selector = $('.question', ths);
        }else if (filter_by == 'code'){
          filter_selector = $('.question-code', ths);
        }else if (filter_by == 'ans'){
          filter_selector = $('.answers ul', ths);
        }
      }

      // If the list item does not contain the text phrase, hide it
      if (filter_selector.text().search(regexp) < 0) {
        $(ths).css({'display':'none'});

      // Show the list item when the phrase matches
      } else {
        filter_selector.highlight(filter);
        $(ths).css({'display':'list-item'});
      }      
    }


    // show group header if questions in group are showing
    // - get list of groups that need to be shown from visible questions
    var search_group_ids = [];
    // cannot use :visible selector for li might be nested in another li that is no visible
    // so have to look by using list-item
    $('li.question-item[style*="list-item"] .question-link', codebook).each(function(){
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
    $('li.group-item', codebook).each(function(){
      if (search_group_ids.indexOf($(this).data('id')) == -1){
        $(this).hide();
      }else{
        $(this).show();
      }
    });

    // - show correct jumpto options
    $('select.selectpicker-group option', codebook).each(function(){
      if (search_group_ids.indexOf($(this).attr('value')) == -1){
        $(this).prop('disabled', true);
      }else{
        $(this).prop('disabled', false);
      }
    });
    $('select.selectpicker-group', codebook).selectpicker('refresh');

  }else{
    $("li.question-item, li.group-item", codebook).show();
    $('select.selectpicker-group option', codebook).prop('disabled', false);
    $('select.selectpicker-group', codebook).selectpicker('refresh');
  }  
}

$(document).ready(function(){
  codebook = $("#codebook");
  li_items = $("li.question-item", codebook);
  li_length = li_items.length;

  $("input#filter", codebook).keyup(debounce(function() {
    run_search();
  }, 500));

  // re-run search when filter option changes
  $('input[type="radio"]', codebook).change(function(){
    // if search text exists, run search
    if ($('input#filter', codebook).val().length > 0){
      run_search();
    }
  });

  // group jumpto 
  $('select.selectpicker-group', codebook).selectpicker();

  // get unique list of group ids
  // - used during search so knows which groups to turn on and off
  $('select.selectpicker-group option', codebook).map(function(){
    if ($(this).attr('value') != ''){
      return group_ids.push($(this).attr('value'));
    }
  })

  // when select group, go to it
   console.log(codebook);
  $('select.selectpicker-group', codebook).change(function(){
     console.log("here",$('.group-item[data-id="' + $(this).val() + '"]', codebook).offset().top, $('nav.navbar').height() );
    $('html, body').animate({ scrollTop: $('.group-item[data-id="' + $(this).val() + '"]', codebook).offset().top - $('nav.navbar').height() }, 1500);
    // reset select to default value
    $(this).selectpicker('val', '');
  });
  // when click on group under question link, go to it
  $('.question-link-groups .question-link-group', codebook).click(function(){
    $('body, html').animate({ scrollTop: $('.group-item[data-id="' + $(this).data('id') + '"]', codebook).offset().top - $('nav.navbar').height() }, 1500);
  });

  $(document).on("click", ".view-all label", function (){
    var t = $(this),
      p = t.parent();
    p.toggleClass("active");
    t.text(t.attr("data-show-" + (p.hasClass("active") ? "less" : "more")));
  });
});

