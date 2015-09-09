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
  $("body").append("<div class='loading'></div>");
  $.ajax({
    url: url,
    data: data,
    dataType: "json"
  }).done(function (d) {
    $(".list").html(d.d);
  }).always(function () {
    $(".loading").fadeOut(500, function () { $(this).remove(); });
  });
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