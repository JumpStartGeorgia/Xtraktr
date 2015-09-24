/*global  $, gon, load_highlights */
/*eslint no-inner-declarations: 0 */
//= require masonry.pkgd.min
$(document).ready(function (){

  // resize the container .highlight to fit the iframe
  $("#highlights .highlight iframe").load(function (){
    var parent = $(this).parent(".highlight");
    $(parent).height($(this).contents().height() + $(parent).find("h3").contents().height());
  });

  // if highlights are present, load them
  if (gon.highlight_ids) {
    var data = {}, group_of_highlight_ids = [], i, j, isFirst = false, index = 0;

    if(gon.highlight_show_title) { data.show_title = true; }
    if(gon.highlight_show_links) { data.show_links = true; }
    if(gon.highlight_admin_link) { data.use_admin_link = true; }

    for(i = 0, j = -1; i < gon.highlight_ids.length; ++i) {
      if(i % 5 == 0) {
        group_of_highlight_ids.push([]);
        ++j;
      }
      group_of_highlight_ids[j].push(gon.highlight_ids[i]);
    }
    var group_of_highlight_ids_length = group_of_highlight_ids.length;
    highlights_serial_addition();
    var highlights = $("#highlights");
    function highlights_serial_addition () {
      data["ids"] = group_of_highlight_ids[index].join(",");
      $.ajax({
        type: "POST",
        url: gon.generate_highlights_url,
        data: data,
        dataType: "json",
        success: function (d)
        {
          if (d != undefined && d.html != undefined && d.js != undefined){

            highlights.append(d.html); // add the html
            load_highlights(d.js);  // create the charts

            if(!isFirst) {
              highlights.masonry({
                itemSelector: ".highlight",
                "gutter": 20
              });
              isFirst = true;
            }
            else {
              highlights.masonry("appended", highlights.find(group_of_highlight_ids[index].map(function (id) { return ".highlight-data[data-id='" + id + "']"; }).join(",")).parent());
            }

            if(index < group_of_highlight_ids_length-1) {
              ++index;
              highlights_serial_addition();
            }
            else {
              $(".highlights-loader").fadeOut();
            }
          }
        }
      });
    }
  }
});
