/*global  $*/
function filter () {
  var filters = $(".filters"),
    q = filters.find(".search input").val(),
    sort = filters.find(".sort .dropdown-menu li.selected").attr("data-value"),
    category = filters.find(".category .dropdown-menu li.selected").attr("data-value"),
    url = filters.attr("data-path"),
    data = { sort: sort };

  if (q !== "") {
    data["q"] = q;
  }
  if (category !== "none") {
    data["category"] = category;
  }
  if(!$("body .cssloader").length) {
    $("body").append(cssloader());
  } 
  else {
    $("body .cssloader").show();
  }
  $.ajax({
    url: url,
    data: data,
    dataType: "json"
  }).done(function (d) {
    $(".list").html(d.d);
  }).always(function () {
    $(".cssloader").fadeOut(500, function () {  console.log(this);/*$(this).remove();*/ });
  });
}




function cssloader () {
  return '<div class="cssloader"><svg version="1.1" width="200px" height="200px" viewBox="0 0 200 200" enable-background="new 0 0 200 200" xml:space="preserve"><g><path class="circle1" d="M138.768,100c0,21.411-17.356,38.768-38.768,38.768c-21.411,0-38.768-17.356-38.768-38.768c0-21.411,17.357-38.768,38.768-38.768"/><path class="circle2" d="M132.605,100c0,18.008-14.598,32.605-32.605,32.605c-18.007,0-32.605-14.598-32.605-32.605c0-18.007,14.598-32.605,32.605-32.605"/><path class="circle3" d="M126.502,100c0,14.638-11.864,26.502-26.502,26.502c-14.636,0-26.501-11.864-26.501-26.502c0-14.636,11.865-26.501,26.501-26.501"/><path  class="circle4" d="M120.494,100c0,11.32-9.174,20.494-20.494,20.494c-11.319,0-20.495-9.174-20.495-20.494c0-11.319,9.176-20.495,20.495-20.495"/></g></svg></div>';
}

$(document).ready(function () {
  $(".category[data-filter=category] .dropdown-menu li").click(function () {
    var t = $(this),
      p = t.parent();
    p.find("li").removeClass("selected");
    t.addClass("selected");
    p.parent().find(".dropdown-toggle").text(t.text());
    filter();
  });

  $(".search .go").click(function () { filter(); });

  $(document).on("keyup.dataset_search", ".search input", function (e) {
    if (e.keyCode === 13) {
      $(".search .go").trigger("click");
    }
  });

  $(".sort .dropdown-menu li").click(function () {
    var t = $(this),
      p = t.parent();
    p.find("li").removeClass("selected");
    t.addClass("selected");
    p.parent().find(".dropdown-toggle").text(t.text());
    filter();
  });

});