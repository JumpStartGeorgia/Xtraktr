function filter()
{
  var filters = $('.filters');
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
     $('.list').html(d.d);
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