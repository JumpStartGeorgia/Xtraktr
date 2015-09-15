$(document).ready(function () {
  // add autocomplete for collaborator search
  if ($('form#members-new #member_ids').length > 0){
    $('form#members-new #member_ids').tokenInput(
      gon.member_search,
      {
        method: 'POST',
        minChars: 2,
        theme: 'xtraktr',
        allowCustomEntry: true,
        preventDuplicates: true,
        prePopulate: $('form#members-new #member_ids').data('load'),
        hintText: gon.tokeninput_collaborator_hintText,
        noResultsText: gon.tokeninput_collaborator_noResultsText,
        searchingText: gon.tokeninput_searchingText,
        resultsFormatter: function(item){
          return "<li><p>" + item.name + "</p></li>" ;
        },
        tokenFormatter: function(item) {
          return "<li><p>" + item.name + "</p></li>" ;
        }
      }
    );
  }
});
