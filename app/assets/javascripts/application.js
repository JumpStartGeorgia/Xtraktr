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
//= require twitter/bootstrap/alert
//= require twitter/bootstrap/dropdown
//= require twitter/bootstrap/tab
//= require bootstrap.tooltip.min
//= require twitter/bootstrap/collapse
//= require dataTables/jquery.dataTables
// require dataTables/extras/dataTables.responsive
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/extras/dataTables.tableTools
//= require modal
//= require vendor

var globalCallback = globalCallback || function () {},
  page_wrapper,
  js;

$(document).ready(function () {
  page_wrapper = $("#page-wrapper");
   // set focus to first text box on page
  if (gon.highlight_first_form_field) {
    $(":input:visible:enabled:first").focus();
  }

   // workaround to get logout link in navbar to work
  $('body')
    .off('click.dropdown touchstart.dropdown.data-api', '.dropdown')
    .on('click.dropdown touchstart.dropdown.data-api', '.dropdown form', function (e) { e.stopPropagation(); });

  $("body").tooltip({
    selector: "[title]",
    container: "body",
    html: true
  });

  $('#side-menu a').click(function () {
    var t = $(this),
      p = t.closest('ul');
    p.find('a.active').removeClass('active');
    t.addClass('active');
  });
  $(document).on('change', 'form.user #user_account', function () {
    var t =  $(this),
      form = t.closest('form'),
      checked = t.is(":checked");
    form.find('.ghost-box').toggleClass('js-hide', !checked);
    var submit = form.find('input[type=submit]'),
      tmp = submit.attr('data-text-swap');
    submit.attr('data-text-swap', submit.val());
    submit.val(tmp);
  });
  $(document).on('change', 'form.user #user_notifications', function () {
    var t =  $(this),
      form = t.closest('form'),
      checked = t.is(":checked");
    form.find('#user_notification_locale_input').toggleClass('js-hide', !checked);
  });

  $(document).on('click', '.reattach', function (e) {
    navbarToggle();
    var t = $(this),
      data = {};
    if (downloading) {
      data = { d: 1 };
    }
    $.ajax({
      url: t.attr('href'),
      data: data
    }).success(function (d) {
      modal(d);
    }).error(function (d) { });
    e.preventDefault();
    e.stopPropagation();
  });

  $('body').on('submit', '#new_user', function (e) {
    var form = $(this),
      t = $(this).attr('data-form-id');
    if (t.length) {
      t = $("#" + t);
      $.ajax({
        type: "POST",
        url: $(this).attr('action'),
        data: $(this).serialize(),
        dataType: 'json',
        success: function (data) {
          if (data.url) {
            js_modal_off();
            window.location.href = data.url;
          } else {
            window.location.reload();
          }
        },
        error: function (data) {
          data = data.responseJSON;
          var errors = data.errors;
          if (data.sessions) {
            form.parent().find('.notification').remove();
            form.before(notification('alert', data.errors.alert));
            form.find(':input:visible:enabled:first').focus();
          } else {  //data.registration
            form.find('.form-group').removeClass('has-error').find('abbr.exclamation').remove();
            $.each(errors, function (k, v) {
              var input = form.find("[name='user[" + k + "]']:not([type=hidden])"),
                type = input.attr('type');

              if (['text', 'email', 'password'].indexOf(type) !== -1) {
                input.closest('.form-group').addClass('has-error');
                input.closest('.form-wrapper').append('<abbr class="exclamation" data-class="tooltip-exclamation" title="' + $.map(v, function (m) { return m.charAt(0).toUpperCase() + m.slice(1); }).join("\r\n") + '"></abbr>');
              } else if (['checkbox', 'radio'].indexOf(type) !== -1) {
                //console.log(k,v,type,input,input.closest('.form-group').find('> label'));
                input.closest('.form-group').addClass('has-error');
                input.closest('.form-group').find('label').append('<abbr class="exclamation" data-class="tooltip-exclamation" title="' +  $.map(v, function (m) { return m.charAt(0).toUpperCase() + m.slice(1); }).join("\r\n") + '"></abbr>');
              }
            });
          }
        }
      });
    }
    e.preventDefault();
    e.stopPropagation();
  });

  $(document).on('keyup.checkbox-radio-box', '.checkbox-box, .radio-box', function (e) {
    if (e.keyCode === 32) {  // space      
      $(this).find('label').trigger('click');
    }
  });

  $('.download').click(function (e) {
    var t = $(this),
      open = !t.hasClass('open');

    $('.download.open').each(function () {
      $(document).off('click.download');
      $(this).removeClass('open');
    });

    if (t.offset().top + 146 > $(document).height()) {
      t.find('ul').css('top', -132);
    }
    t.toggleClass('open', open);
    if (open) {
      $(document).on('click.download', function () {
        t.removeClass('open');
        $(document).off('click.download');
      });
    } else { $(document).off('click.download'); }
    e.stopPropagation();
  });


  $('.download li div.type').click(function (e) {
    var t = $(this),
      type = t.attr('data-type'),
      id = t.closest('.download').attr('data-id'),
      lang = t.closest('.download').attr('data-lang');
      download_type = t.closest('.download').attr('data-download-type');
    download_request("/" + document.documentElement.lang + "/download_request", { id: id, type: type, lang: lang, download_type: download_type });

    t.closest('.download').removeClass('open');
    $(document).off('click.download');
    e.stopPropagation();
  });

  $(document).on('change', '#user_status_input input[type=radio]', function () {
    if (this.value === 8) {
      $('#user_status_other_input').show();
    } else {
      var other = $('#user_status_other_input').hide();
      other.find('input').val('');
    }
  });


  $(".content > .message").delay(3000).fadeOut(3000);

  // language switcher for dataset/time series in dashboard/explore pages
  // reload the current page with the language param set
  // $('.available-language-switcher').on('change', 'select', function (e) {
  //   e.preventDefault();

  //   var querystring = queryStringToJSON(window.location.href);
  //   querystring.language = $(this).val();

  //   window.location.href = location.protocol + '//' + location.host + location.pathname + '?' + $.param(querystring);

  // });
  $('.search .go-submit').click(function () { $(this).closest('form').submit(); });



  $(document).on('click', '.notification .closeup', function () { $(this).parent().remove(); });

  $('.m-lang .figure').on('click', function () {
    navbarToggle();
    var t = $(this).closest('.m-lang').find('.under-box').toggleClass('open');
    t.animate({"left": (t.hasClass('open') ? '-' : '+') + "=" + (t.width() - 42) }, 500, function () {  });
    t.delay(500).animate({"opacity" : 1}, 100);
  });
  $('.m-search .figure').on('click', function () {
    navbarToggle();
    var t = $(this),
      b = t.closest('.navbar-header').find('.navbar-brand'),
      p = t.closest('.under-box').toggleClass('open');
    p.animate({"left": (p.hasClass('open') ? "-=" + (p.offset().left - b.width() - 42) : 0) }, 500, function () {  });
  });


  // Caption for selected tab is changed on tab selection from tab list. Caption is visible only for small devices. 
  $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    $('.tab-caption').html($(e.target).text());
    tabToggle();
  });

  $(document).on('click', function (e) {
    var t = $(e.target);
    if (!t.is('.navbar-toggle, .navbar-collapse, .tab-collapse') && !t.closest('.navbar-toggle, .navbar-collapse, .tab-collapse').length) {
      $('.navbar-toggle:not(.collapsed)').trigger('click');
    }
  });

  // when form with data loader is submitted, show the loading img
  $('form.form-data-loader').submit(function(){
    $('.data-loader').fadeIn('fast');
  });

});
var downloading = false;
function download_request(url, data) {
  $.ajax({
    url: url,
    data: data,
    dataType: 'json'
  }).done(function (d) {
    if (d.agreement) {
      window.location.href = d.url;
    } else {
      modal(d.form);
      downloading = true;
    }
  }).error(function (d) {
    //console.log('file downloading error', d);
  });
}


////////////////////////////////////////////////
// convert the querystring variables into json
function queryStringToJSON(url) {
  if (url === '') {
    return {};
  }
  var u = url.split('?');
  if (u.length !== 2) {
    return {};
  }
  var pairs = u[1].split('&'),
    result = {},
    idx = null;
  for (idx in pairs) {
    var pair = pairs[idx].split('=');
    if (!!pair[0]) {
      result[pair[0].toLowerCase()] = decodeURIComponent(pair[1] || '');
    }
  }
  return result;
}

// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If `immediate` is passed, trigger the function on the
// leading edge, instead of the trailing.
function debounce(func, wait, immediate) {
  var timeout;
  return function () {
    var context = this,
      args = arguments,
      later = function () {
        timeout = null;
        if (!immediate) {
          func.apply(context, args);
        }
      },
      callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) {
      func.apply(context, args);
    }
  };
}
function notification(state, text, extra_class) {
  state = ['success', 'error', 'info'].indexOf(state) !== -1 ? state : 'error';  
  return "<div class='message notification " + state + " " + extra_class + "'><div class='figure'></div><div class='text'>" + text + "</div><div class='closeup'></div></div>";
}
function navbarToggle() {
  if (!$(".navbar-toggle").hasClass('collapsed')) {
    $(".navbar-toggle").trigger('click');
  }
}
function tabToggle() {
  if (!$(".tab-toggle").hasClass('collapsed')) {
    $(".tab-toggle").trigger('click');
  }
}
function is_touch_device() {
  return (('ontouchstart' in window)
      || (navigator.MaxTouchPoints > 0)
      || (navigator.msMaxTouchPoints > 0));
}
var is_touch = is_touch_device();



// Closure
(function () {
  /**
   * Decimal adjustment of a number.
   *
   * @param {String}  type  The type of adjustment.
   * @param {Number}  value The number.
   * @param {Integer} exp   The exponent (the 10 logarithm of the adjustment base).
   * @returns {Number} The adjusted value.
   */
  function decimalAdjust (type, value, exp) {
    // If the exp is undefined or zero...
    if (typeof exp === "undefined" || +exp === 0) {
      return Math[type](value);
    }
    value = +value;
    exp = +exp;
    // If the value is not a number or the exp is not an integer...
    if (isNaN(value) || !(typeof exp === "number" && exp % 1 === 0)) {
      return NaN;
    }
    // Shift
    value = value.toString().split("e");
    value = Math[type](+(value[0] + "e" + (value[1] ? (+value[1] - exp) : -exp)));
    // Shift back
    value = value.toString().split("e");
    return +(value[0] + "e" + (value[1] ? (+value[1] + exp) : exp));
  }

  // Decimal round
  if (!Math.round10) {
    Math.round10 = function (value, exp) {
      return decimalAdjust("round", value, exp);
    };
  }
  // Decimal floor
  if (!Math.floor10) {
    Math.floor10 = function (value, exp) {
      return decimalAdjust("floor", value, exp);
    };
  }
  // Decimal ceil
  if (!Math.ceil10) {
    Math.ceil10 = function (value, exp) {
      return decimalAdjust("ceil", value, exp);
    };
  }

})();
  function isN (obj) {
    return !jQuery.isArray( obj ) && (obj - parseFloat( obj ) + 1) >= 0;
  }
  function replicate (n, x) {
    for (var i = 0, xs = []; i < n; ++i) {
      xs.push (x);
    }
    return xs;
  }
  function replicate2 (n, x) {
    for (var i = 0, xs = []; i < n; ++i) {
      xs.push ([x, x]);
    }
    return xs;
  }
function isInteger (x) {
  return Math.round(x) === +x;
}
