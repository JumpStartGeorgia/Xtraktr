$('.info .share').hover(function(){ // on hover do this:
   var t = $(this);
         var at = t.find('.addthis_sharing_toolbox');
         t.find('.prompt').animate({"right": at.width() }, 500, function(){  });
         at.delay( 500 ).animate({"opacity":1}, 100);
      }, function(){ 
           var t = $(this);
            var at = t.find('.addthis_sharing_toolbox');
          at.stop().animate({"opacity":0}, 100);
          t.find('.prompt').stop().delay( 100 ).animate({"right":0}, 250);

      });

