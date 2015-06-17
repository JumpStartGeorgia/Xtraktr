  // show highlight description form
  $(document).on('click', '.edit-highlight-description', function (e) {
    e.preventDefault();

    var url = $(this).attr('data-href');
    var embed_id = $(this).attr('data-embed-id');
    var row = $(this).closest('tr');

    // get the form for this embed id
    $.ajax({
      type: "GET",
      url: url,
      data: {embed_id: embed_id},
      dataType: 'json'
    }).done(function(data){
      if (data && data.form != null){
        // got form, create modal popup
        modal($('#description-form-popup').html().replace('{form}', data.form),
        {
          position:'center', 
          events: [
            { 
              event:'submit',
              element: 'form.highlight', 
              callback:function(e)
              {  
                e.preventDefault();
                var params = $(this).serialize();
                params += '&embed_id=' + embed_id;
                var desc = $(this).find('textarea:first').val();

                // submit the form and close window
                $.ajax({
                  type: "POST",
                  url: $(this).attr('action'),
                  data: params,
                  dataType: 'json'
                }).done(function(data){
                  if (data && data.success == true){
                    // clear desc
                    $(row).find('td:nth-last-child(2)').empty();

                    // if description exists, show it
                    if (desc != undefined && desc != ''){
                      // show desc  
                      $(row).find('td:nth-last-child(2)').html(desc.replace(/(?:\r\n|\r|\n)/g, '<br />'));
                    }

                    // close popup
                    js_modal_off();

                    // show success message
                    $('#page-wrapper .content').prepend(notification('success', data.message, 'message'));
                    $('#page-wrapper .content > .message').delay(3000).fadeOut(3000);
                  }else{
                    $('#js_modal .popup .header').after(notification('error', data.message));
                  }
                });
              }
            },
          ]
        }
        );
      }
    });
  });

