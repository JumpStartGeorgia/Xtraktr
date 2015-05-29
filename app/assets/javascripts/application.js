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
  $(document).on('change','form.user #user_account', function(){
    var t =  $(this);
    var form = t.closest('form');
    var checked = t.is(":checked");
    form.find('.ghost-box').toggleClass('js-hide', !checked);
    var submit = form.find('input[type=submit]');
    var tmp = submit.attr('data-text-swap');
    submit.attr('data-text-swap',submit.val())
    submit.val(tmp);
  });
  $(document).on('change', 'form.user #user_notifications', function(){
    var t =  $(this);
    var form = t.closest('form');
    var checked = t.is(":checked");
    form.find('#user_notification_locale_input').toggleClass('js-hide', !checked);
  });

  $(document).on('click', '.reattach', function(e){
    var t = $(this);
    var data = {};
    if(downloading)
    {
      data = { d:1 }
    }
    $.ajax({
      url: t.attr('href'),
      data: data,
      // dataType: 'json',
    }).success(function(d)
    {
       modal(d);      
    }).error(function(d){
    });
    e.preventDefault();
    e.stopPropagation();
  });

  $('body').on('submit','#new_user', function (e)
  {    
    var form = $(this);
    var t = $(this).attr('data-form-id');
    if(t.length)
    {
      t=$("#" + t);
      $.ajax({
        type: "POST",
        url: $(this).attr('action'),
        data: $(this).serialize(),
        dataType: 'json',
        success: function (data)
        {      
           // console.log('success function',data);
           // return;
           if(data.url)
           {
               js_modal_off();
               window.location.href = data.url;
           }   
           else 
           {
              window.location.reload();
            }    
        },
        error: function (data)
        {     
          data = data.responseJSON;
          var errors = data.errors;
          if(data.sessions)
          {
              form.parent().find('.notification').remove();  
              form.before(notification('alert', data.errors.alert));          
              form.find(':input:visible:enabled:first').focus();
          }
          else //data.registration
          {
            form.find('.form-group').removeClass('has-error').find('abbr.exclamation').remove();
             $.each(errors, function(k,v){
               var input = form.find("[name='user[" + k + "]']:not([type=hidden])");
               var type = input.attr('type');

               if(['text','email','password'].indexOf(type) != -1)
               {
                input.closest('.form-group').addClass('has-error');
                input.closest('.form-wrapper').append('<abbr class="exclamation" data-class="tooltip-exclamation" title="'+ $.map(v,function(m){ return m.charAt(0).toUpperCase() + m.slice(1); }).join("\r\n")+'"></abbr>');
               }
               else if(['checkbox','radio'].indexOf(type) != -1)
               {
                console.log(k,v,type,input,input.closest('.form-group').find('> label'));
                input.closest('.form-group').addClass('has-error');
                input.closest('.form-group').find('label').append('<abbr class="exclamation" data-class="tooltip-exclamation" title="'+ $.map(v,function(m){ return m.charAt(0).toUpperCase() + m.slice(1); }).join("\r\n")+'"></abbr>');
               }
            });  
          }


        // console.log(data);       

        //   $(t).parent().find('.alert').remove();  
        //   $(t + ' form').before('<div class="alert alert-danger fade in"><span>' + data.responseText + '</span></div>');          
        //   $(t + ' :input:visible:enabled:first').focus();
        }
      });     
    }
    e.preventDefault();
    e.stopPropagation();
  });

 $(document).on('keyup.checkbox-radio-box', '.checkbox-box, .radio-box',function(e) {
    if (e.keyCode == 32) {  // space      
      $(this).find('label').trigger('click');     
    }  
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
           $(document).off('click.download');
        });
      }
      else $(document).off('click.download');
      e.stopPropagation();
  });


  $('.download li div.type').click(function(e){
    var t = $(this);
    var type = t.attr('data-type');
    
    var id = t.closest('.download').attr('data-id');
    var lang = t.closest('.download').attr('data-lang');
    download_request("/" + document.documentElement.lang + "/download_request", { id: id, type: type, lang: lang });

    t.closest('.download').removeClass('open');
    $(document).off('click.download');
    e.stopPropagation();      
  });

  js_modal =  $('#js_modal');

  $(document).on('change', '#user_status_input input[type=radio]', function()
    {
      if(this.value == 8)
      {
        $('#user_status_other_input').show();
      }
      else
      {
        var other = $('#user_status_other_input').hide();
        other.find('input').val('');
      }
    });


    $('.content > .message').delay(3000).fadeOut(3000);

    // language switcher for dataset/time series in dashboard/explore pages
    // reload the current page with the language param set
    $('.available-language-switcher').on('change', 'select', function(e){
      e.preventDefault();

      var querystring = queryStringToJSON(window.location.href);
      querystring.language = $(this).val();

      window.location.href = location.protocol + '//' + location.host + location.pathname + '?' + $.param(querystring);

    });
  $('.search .go-submit').click(function(){ $(this).closest('form').submit(); });



  $(document).on('click', '.notification .closeup', function() { $(this).parent().remove(); });

  $('.m-lang .figure').on('click', function() {
     var t = $(this).closest('.m-lang').find('.under-box').toggleClass('open');
     t.animate({"left": (t.hasClass('open') ? '-':'+') + "="+(t.width()-42) }, 500, function(){  });
     t.delay( 500 ).animate({"opacity":1}, 100);
  });
  $('.m-search input').on('click', function() {
      var t = $(this);
      t.css({'background-color':'#fff'});
      var b = t.closest('.navbar-header').find('.navbar-brand');
      var p = t.closest('.navbar-form')
     // var t = $(this).closest('.m-lang').find('.under-box').toggleClass('open');
     // t.animate({"left": (t.hasClass('open') ? '-':'+') + "="+(t.width()-42) }, 500, function(){  });
     // t.delay( 500 ).animate({"opacity":1}, 100);
  });


  //  $('.m-lang').hover(function(){ // on hover do this:
  //   var t = $(this);
  //  var at = t.find('a');
  //  t.find('.figure').animate({"right": at.width()+15 }, 500, function(){  });
  //  at.delay( 500 ).animate({"opacity":1}, 100);
  // }, function(){ 
  //   var t = $(this);
  //   var at = t.find('a');
  //   at.stop().animate({"opacity":0}, 100);
  //   t.find('.figure').stop().delay( 100 ).animate({"right":0}, 250);
  // }); 



});
var downloading = false;
function download_request(url, data)
{
  $.ajax({
    url: url,
    data:data,
    dataType: 'json',   
  }).done(function(d)
  {
    if(d.agreement) 
    { 
     window.location.href = d.url; 
    }
    else { 
      modal(d.form);
      downloading = true;
    }
  }).error(function(d)
  {
     console.log('file downloading error',d);
  });
}

var js_modal;
function modal(html,options)
{
  if(typeof html === 'undefined') return;
  if(typeof options === 'undefined') options = {};
  var opt = options;
  
  var w = $(window).width();
  var h = $(window).height();
  var max_width = (w > 768 ? 768 : w) - 20;
  var max_height = (h > 1024 ? 1024 : h - 60);
  var css = {'max-width':max_width, 'max-height':max_height};
  var klass = "popup";
  if(typeof opt.position !== 'undefined') 
  {
    klass += " " + opt.position;
  }
  var popup = js_modal.find('.popup');
  popup.html(html).css(css).removeClass().addClass(klass);
  if(typeof opt.events !== 'undefined' && Array.isArray(opt.events)) 
  {
    opt.events.forEach(function(d){
      popup.on(d.event, d.element, d.callback);
    });
  }
  if(typeof opt.before === 'function' ) 
  {
    opt.before(popup);
  }
  js_modal_on();
  
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
  js_modal.fadeOut(500,function(){
    $(document).off('keyup.js_modal').off('click.js_modal');
    js_modal.find('.popup').empty();
     downloading = false;
   });
}
////////////////////////////////////////////////
// convert the querystring variables into json
function queryStringToJSON(url) {
  if (url === ''){
    return {};    
  }
  var u = url.split('?');
  if (u.length != 2){
    return {};
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
function notification(state,text)
{
  state = ['success', 'error', 'info'].indexOf(state) != -1 ? state : 'error';
  return "<div class='notification "+ state + "'><div class='figure'></div><div class='text'>"+text+"</div><div class='closeup'></div></div>";
}
