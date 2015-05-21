function filter()
{
  var filters = $('.filters');
  var q = filters.find('.search input').val();
  var sort = filters.find('.sort select').val();
  var category = filters.find('.category .selector').attr('data-selected');
  var url = filters.attr('data-path');
  var data = { sort: sort };

  if(q != "") data["q"] = q;
  if(category != "none") data["category"] = category;
  $('body').append("<div class='loading'></div>");
  $.ajax({
    url: url,
    data: data,
    dataType: 'json',    
  }).done(function(d)
  {
     $('.list').html(d.d);
  }).always(function(){
    $('.loading').fadeOut(500, function(){ $(this).remove() });
  });
}

$(document).ready(function(){

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
    var selector = $('.category[data-filter=category] .selector').attr('data-selected', v);
    selector.find('.item').empty().append(has ? '' : t.html());
    selector.removeClass('open');
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
  $('.sort select').change(function(){ filter(); });

});