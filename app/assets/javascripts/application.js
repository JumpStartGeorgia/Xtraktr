// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require i18n
//= require i18n/translations
//= require jquery
//= require jquery_ujs
//= require jquery.ui.core
//= require jquery.ui.effect
//= require jquery.tipsy
//= require twitter/bootstrap
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/extras/dataTables.tableTools
//= require vendor

$(document).ready(function(){
	// set focus to first text box on page
	if (gon.highlight_first_form_field){
	  $(":input:visible:enabled:first").focus();
	}

	// workaround to get logout link in navbar to work
	$('body')
		.off('click.dropdown touchstart.dropdown.data-api', '.dropdown')
		.on('click.dropdown touchstart.dropdown.data-api', '.dropdown form', function (e) { e.stopPropagation() });


  // add nice tooltips for form help
  if ($('form div.help-inline,form div.help-block, form label abbr').length > 0){ 
    $('form div.help-inline,form div.help-block, form label abbr').tipsy({gravity: 'sw', fade: true});
  }

  $('#side-menu a').click(function(){
    var t = $(this);
    var p = t.closest('ul');
    p.find('a.active').removeClass('active');
    t.addClass('active');
  });
  $('.download').click(function(){
    var t = $(this);
    var link = t.attr('data-link');
    if(link !== undefined)
    {
      window.location.href = link;
      return;
    }
    $.ajax({
      url: "/" + document.documentElement.lang + "/download",
      data: { id: t.attr('data-id') },
      success: function(d)
      {
        if(d.agreement)
        {
          window.location.href = d.url;
        }
        else
        {
          $('body').append("<div class='js_modal'>"+d.form+"</div><div class='js_modal_bg'></div>");
        }
      }
    });
  });

});

////////////////////////////////////////////////
// convert the querystring variables into json
function queryStringToJSON(url) {
  if (url === ''){
    return '';    
  }
  var u = url.split('?');
  if (u.length != 2){
    return '';
  }
  var pairs = u[1].split('&');
  var result = {};
  for (var idx in pairs) {
    var pair = pairs[idx].split('=');
    if (!!pair[0])
      result[pair[0].toLowerCase()] = decodeURIComponent(pair[1] || '');
  }
  return result;
}

// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If `immediate` is passed, trigger the function on the
// leading edge, instead of the trailing.
function debounce(func, wait, immediate) {
  var timeout;
  return function() {
    var context = this, args = arguments;
    var later = function() {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
};