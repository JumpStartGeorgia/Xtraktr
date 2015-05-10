$(document).ready(function(){

  // resize the container .highlight to fit the iframe
  $('#highlights .highlight iframe').load(function(){
    var parent = $(this).parent('.highlight');
    $(parent).height($(this).contents().height() + $(parent).find('h3').contents().height());
  });


});
