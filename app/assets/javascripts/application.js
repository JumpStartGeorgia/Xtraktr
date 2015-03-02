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

