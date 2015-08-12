var counter = 0;
var check_status;
function check_download_generation_status(){
  $.ajax({
    type: "POST",
    url: gon.generate_download_file_status_dataset_path
  }).success(function(status){
    counter++;
    if (status.finished == true){
      clearTimeout(check_status);
      // on finish hide the loader and hide the info message
      $('.notification').fadeOut();
      $('.data-loader-message-container').fadeOut();
    }else{
      check_status = setTimeout(check_download_generation_status, 5000);
    }
  });
}


$(function() {
  // download page - generate files
  // when the link is clicked, trigger the generation and
  // keep checking to see if the files are generated
  $('span.generate-files').click(function(){
    if (gon.generate_download_files_dataset_path && gon.generate_download_file_status_dataset_path){
      // turn on the loader
      $('.data-loader-message-container').fadeIn();

      // start the file generation
      $.ajax({
        type: "POST",
        url: gon.generate_download_files_dataset_path
      });

      // check if completed every 5 seconds
      check_status = setTimeout(check_download_generation_status, 5000);

    }
  });
});
