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
// Do not use twitter/bootstrap/tooltip because it has hack, to have possibility add class with klass options
//= require twitter/bootstrap/dropdown
//= require twitter/bootstrap/tab
//= require twitter/bootstrap/alert
//= require bootstrap.tooltip.min
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

  $('body').tooltip({
    selector: '[title]',
    container: 'body'    
  });

  $('#side-menu a').click(function(){
    var t = $(this);
    var p = t.closest('ul');
    p.find('a.active').removeClass('active');
    t.addClass('active');
  });
  $(document).on('change','#user_account', function(){
     console.log($(this).is(":checked"));
  });

  $(document).on('click', '.reattach', function(e){
    var t = $(this);
    $.ajax({
      url: t.attr('href')
    }).done(function(d)
    {
       modal(d);      
    });
    e.preventDefault();
    e.stopPropagation();
  });

  $('body').on('submit','#new_user', function ()
  {    
    var t = $(this).attr('data-form-id');
    if(t.length)
    {
      t="#" + t;
      $.ajax({
        type: "POST",
        url: $(this).attr('action'),
        data: $(this).serialize(),
        success: function (data)
        {      
         console.log(data); 
          $(t).parent().find('.alert').remove();  
          var rhtml = $(data);
        
          if (rhtml.length && rhtml.find('#errorExplanation').length)
          {
            $(t).replaceWith(rhtml);
          }
          else if (rhtml.find('.alert.alert-info').length)
          {
            $(t).replaceWith(rhtml.find('.alert.alert-info').children().remove().end());
            delayed_reload(3000);
          }
          else
          {
            window.location.reload();
          }
        },
        error: function (data)
        {     
        console.log(data);            
          $(t).parent().find('.alert').remove();  
          $(t + ' form').before('<div class="alert alert-danger fade in"><span>' + data.responseText + '</span></div>');          
          $(t + ' :input:visible:enabled:first').focus();
        }
      });     
    }
    return false;
  });

$('.download').click(function(e){
    var t = $(this);  
    var open = !t.hasClass('open');
      
    $('.download.open').each(function(){
      $(document).off('click.download');
      $(this).removeClass('open');
    });

    if(t.offset().top+146 > $(document).height())
    {
      t.find('ul').css('top', -132);
    }
  t.toggleClass('open',open);
  if(open)
  {
    $(document).on('click.download',function(){
       t.removeClass('open');
       // t.find('ul').toggle();
       $(document).off('click.download');
    });
  }
  else $(document).off('click.download');
  // t.find('ul').toggle();

  e.stopPropagation();
});


  $('.download li div.type').click(function(e){
    var t = $(this);
    var type = t.attr('data-type');
    
    var id = t.closest('.download').attr('data-id');
    var lang = t.closest('.download').attr('data-lang');
    $.ajax({
      url: "/" + document.documentElement.lang + "/download_request",
      data: { id: id, type: type, lang: lang },      
    }).done(function(d)
    {
      if(d.agreement)
      {
        window.location.href = d.url;
      }
      else
      {
        modal(d.form);
      }
    });
     // t.closest('ul').toggle();
      t.closest('.download').removeClass('open');
      $(document).off('click.download');
    e.stopPropagation();      
  });

  js_modal =  $('#js_modal');
  // js_modal.find('.popup').click(function(e){
  //   e.stopPropagation();   
  // });
  

  $(document).on('change', '#agreement_status_input input[type=radio], #user_status_input input[type=radio]', function()
    {
      if(this.value == 8)
      {
        $('#agreement_status_other_input, #user_status_other_input').show();
      }
      else
      {
        var other = $('#agreement_status_other_input, #user_status_other_input').hide();
        other.find('input').val('');
      }
    });

  $('.category[data-filter=category] .selector').click(function(e){
    var t = $(this)
    t.toggleClass('open');
    var open = t.hasClass('open');
    if(open)
    {
      $(document).on('click.category',function(){
         t.removeClass('open');
         t.parent().find('ul').toggle();
         $(document).off('click.category');
      });
    }
    else $(document).off('click.category');
    t.parent().find('ul').toggle();
    e.stopPropagation();
  });  

  $('.category[data-filter=category] ul li').click(function(e){
    var t = $(this);
    var has = t.hasClass('active');
    var v = has ? 'none' : t.attr('data-filter-value');
    $('.category[data-filter=category] ul li').removeClass('active');  
    var selector = $('.category[data-filter=category] .selector');
    var img  = selector.find('.img');
    var span  = selector.find('span');
    selector.removeClass('open');
    img.removeClass(img.attr('data-selected')).addClass(v).attr('data-selected', v).attr('title', (has ? span.attr('data-text-none') : t.find('.img').attr('title')));
    span.text(span.attr('data-text-' + (has ? v : 'selected')));
    if(!has) t.addClass('active');
    
    t.parent().toggle();
    
    $(document).off('click.category');
    e.stopPropagation();
    filter();
  });  
   $('.search .go').click(function(){ filter(); });

  $(document).on('keyup.dataset_search','.search input', function(e) {
    if (e.keyCode == 13) {  // enter
      $('.search .go').trigger('click');
    }  
  });
  $('.search .go').click(function(){ filter(); });
  $('.sort select').change(function(){ filter(); });
});
function filter()
{
  var filters = $('.dataset-filters');
  var q = filters.find('.search input').val();
  var sort = filters.find('.sort select').val();
  var category = filters.find('.category .selector .img').attr('data-selected');
  var url = filters.attr('data-path');
  var data = { sort: sort };
  if(q != "") data["q"] = q;
  if(category != "none") data["category"] = category;
  $.ajax({
    url: url,
    data: data,
    dataType: 'json',    
  }).done(function(d)
  {
     $('.dataset-list').html(d.d);
    // if(d.agreement)
    // {
    //   window.location.href = d.url;
    // }
    // else
    // {
    //   modal(d.form);
    // }
  });
   console.log(q,sort,category,url);

}
var js_modal;
function modal(html)
{
  if(typeof html !== 'undefined')
  {
    var w = $(window).width();
    var h = $(window).height();
    var max_width = (w > 768 ? 768 : w) - 20;
    var max_height = (h > 1024 ? 1024 : h - 60);
    js_modal.find('.popup').html(html).css({'max-width':max_width, 'max-height':max_height});
    js_modal_on();
  }
}
function js_modal_on() 
{
  $(document).on('keyup.js_modal',function(e) {
    if (e.keyCode == 27) {  // escape key maps to keycode `27`
      js_modal_off();
    }  
  });
  $(document).on('click.js_modal',function(e) {
    if(!$(e.target).closest('.popup').length)        
      js_modal_off();
  });
  js_modal.fadeIn(500);
}
function js_modal_off() 
{
  js_modal.fadeOut(500);
  $(document).off('keyup.js_modal').off('click.js_modal');
}
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