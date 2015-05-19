$(document).ready(function(){

  // resize the container .highlight to fit the iframe
  $('#highlights .highlight iframe').load(function(){
    var parent = $(this).parent('.highlight');
    $(parent).height($(this).contents().height() + $(parent).find('h3').contents().height());
  });


  // if highlights are present, load them
  if (gon.highlight_ids){
    var data = {ids: gon.highlight_ids.join(',')};
    if (gon.highlight_show_title){
      data.show_title = true;
    }
    if (gon.highlight_show_links){
      data.show_links = true;
    }
    $.ajax({
      type: "POST",
      url: gon.generate_highlights_url,
      data: data,
      dataType: 'json',
      success: function (data)
      {      
        xxx = data;
        console.log(data);
        if (data != undefined && data.html != undefined && data.js != undefined){
          console.log('data exists!');
          // add the html
          $('#highlights').append(data.html);

          // create the charts
          load_highlights(data.js);
        }
      }
    });
  }

});
var xxx;