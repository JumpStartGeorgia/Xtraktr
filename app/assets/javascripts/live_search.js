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
    $("#codebook > ul > li").each(function(){
      // determine what text to search in
      var filter_selector = $(this).find('.details .default-search');
      if (filter_by == 'q'){
        filter_selector = $(this).find('.question');
      }else if (filter_by == 'code'){
        filter_selector = $(this).find('.question-code');
      }else if (filter_by == 'ans'){
        filter_selector = $(this).find('.answers ul');
      }

      // If the list item does not contain the text phrase fade it out
      if ($(filter_selector).text().search(new RegExp(filter, "i")) < 0) {
        $(this).fadeOut();

      // Show the list item if the phrase matches
      } else {
        $(filter_selector).highlight(filter);
        $(this).fadeIn();
      }
    });
  }else{
    $("#codebook > ul > li").fadeIn();
  }  
}

$(document).ready(function(){
  // taken from: http://www.designchemical.com/blog/index.php/jquery/live-text-search-function-using-jquery/
  $("#codebook input#filter").keyup(debounce(function() {
    run_search();
  }, 250));

  // re-run search when filter option changes
  $('#codebook input[type="radio"]').change(function(){
    // if search text exists, run search
    if ($('#codebook input#filter').val().length > 0){
      run_search();
    }
  });
});

