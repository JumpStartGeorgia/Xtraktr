var js_modal;
function modal (html, options) {
  if (typeof html === "undefined") { return; }
  if (typeof options === "undefined") { options = {}; }
  var opt = options,
    w = $(window).width(),
    h = $(window).height(),
    max_width = (w > 768 ? 768 : w) - 20,
    max_height = (h > 1024 ? 1024 : h - 60),
    css = {"max-width": max_width, "max-height": max_height},
    klass = "popup";
  if (typeof opt.position !== "undefined") {
    klass += " " + opt.position;
  }
  var popup = js_modal.find(".popup");
  popup.html(html).css(css).removeClass().addClass(klass);
  if (typeof opt.events !== "undefined" && Array.isArray(opt.events)) {
    opt.events.forEach(function (d) {
      popup.on(d.event, d.element, d.callback);
    });
  }
  if (typeof opt.before === "function") {
    opt.before(popup);
  }
  if(popup.find(".select2picker").length) {
    var tmp = popup.find(".select2picker");
    tmp.select2({ width:"auto", allowClear:true, placeholder: tmp.attr("placeholder"), dropdownCssClass: "select2picker-dropdown" });
  }
  js_modal_on();
}
function js_modal_on () {
  $(document).on("keyup.js_modal", function (e) {
    if (e.keyCode === 27) {// escape key maps to keycode `27`
      js_modal_off();
    }
  });
  $(document).on("click.js_modal", function (e) {
    if (!$(e.target).closest(".popup").length) {
      js_modal_off();
    }
  });
  js_modal.fadeIn(500);
}
function js_modal_off () {
  js_modal.fadeOut(500, function () {
    $(document).off("keyup.js_modal").off("click.js_modal");
    js_modal.find(".popup").empty();
    downloading = false;
  });
}



$(document).ready(function () {
  js_modal = $("#js_modal");
});