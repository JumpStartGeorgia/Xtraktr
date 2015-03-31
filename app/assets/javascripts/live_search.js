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



$(document).ready(function(){
  // taken from: http://www.designchemical.com/blog/index.php/jquery/live-text-search-function-using-jquery/
  $("#codebook input#filter").keyup(debounce(function() {
    // Retrieve the input field text and reset the count to zero
    var filter = $(this).val();

    // remove all highlights
    $("#codebook").removeHighlight();

    // Loop through the comment list
    $("#codebook > ul > li").each(function(){
      // If the list item does not contain the text phrase fade it out
      if ($(this).text().search(new RegExp(filter, "i")) < 0) {
        $(this).fadeOut();

      // Show the list item if the phrase matches and increase the count by 1
      } else {
        $(this).highlight(filter).show();
      }
    });
  }, 250));
});

