function filter() {
  var filters = $('.filters'),
    q = filters.find('.search input').val(),
    sort = filters.find('.sort select').val(),
    category = filters.find('.category .selector').attr('data-selected'),
    url = filters.attr('data-path'),
    data = { sort: sort };

  if (q !== "") {
    data['q'] = q;
  }
  if (category !== "none") {
    data["category"] = category;
  }
  $('body').append("<div class='loading'></div>");
  $.ajax({
    url: url,
    data: data,
    dataType: 'json'
  }).done(function (d) {
    $('.list').html(d.d);
  }).always(function () {
    $('.loading').fadeOut(500, function () { $(this).remove(); });
  });
}

$(document).ready(function () {

  $('.category[data-filter=category] .selector').click(function (e) {
    var t = $(this).toggleClass('open');
    if (t.hasClass('open')) {
      $(document).on('click.category', function () {
        t.removeClass('open');
        t.parent().find('ul').toggle();
        $(document).off('click.category');
      });
    } else {
      $(document).off('click.category');
    }
    t.parent().find('ul').toggle();
    e.stopPropagation();
  });
  $('.category[data-filter=category] ul li').click(function (e) {
    var t = $(this),
      has = t.hasClass('active'),
      v = has ? 'none' : t.attr('data-filter-value'),
      cat = $('.category[data-filter=category]'),
      selector = cat.find('.selector'),
      list = cat.find('ul'),
      item = selector.find('.item').empty();
    
    list.find('li').removeClass('active');
    selector.attr('data-selected', v).removeClass('open');
    item.append(has ? '' : t.addClass('active').html());
    cat.find('select').val(v);
    
    list.toggle();
    $(document).off('click.category');
    e.stopPropagation();
    filter();
  });
  
  $('.category[data-filter=category] select').change(function (e) {
    var t = $(this),
      v = t.val(),
      cat = $('.category[data-filter=category]'),
      selector = cat.find('.selector'),
      list = cat.find('ul'),
      item = selector.find('.item').empty();
    
    list.find('li').removeClass('active');
    selector.attr('data-selected', v).removeClass('open');

    if (v !== 'none') {
      item.append(list.find('li[data-filter-value=' + v + ']').addClass('active').html());
    }
    list.toggle(false);
    $(document).off('click.category');
    e.stopPropagation();
    filter();

  });
  
  $('.search .go').click(function () { filter(); });

  $(document).on('keyup.dataset_search', '.search input', function (e) {
    if (e.keyCode === 13) {
      $('.search .go').trigger('click');
    }
  });
  $('.sort select').change(function () { filter(); });

});