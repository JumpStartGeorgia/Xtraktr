  // from: http://stackoverflow.com/a/21266395
  function allAreEqual(array){
    if(!array.length) return true;
    // I also made sure it works with [false, false] array
    return array.reduce(function(a, b){return (a === b)?a:("false"+b);}) === array[0];
  } 

  // insert an item into an array at an index
  // from: http://stackoverflow.com/a/5086688
  jQuery.fn.insertAt = function(index, element) {
    var lastIndex = this.children().size()
    if (index < 0) {
      index = Math.max(0, lastIndex + 1 + index)
    }
    this.append(element)
    if (index < lastIndex) {
      this.children().eq(index).before(this.children().last())
    }
    return this;
  }


$(document).ready(function(){
  // load tinymce
  // set the width and height so even the tabs that are not showing still have the correct size
  gon.tinymce_options.height = $('.tab-pane:first textarea').height();
  gon.tinymce_options.width = $('.tab-pane:first textarea').width();
  tinyMCE.init(gon.tinymce_options);


  // update the primary language drop down
  function load_primary_languages(){
    console.log('load primary langs');
    // if not items are selected, hide the primary language selector
    // else, show it with the options of what is selected in primary language
    console.log('selected languages = ' + $('form.shapeset select#shapeset_languages option:selected').length);
    var values = $('form.shapeset select#shapeset_languages').val();

    if (values == null || values.length == 0){
      console.log('- no selected, hiding');
      $('form.shapeset select#shapeset_primary_language').val('');
      $('form.shapeset select#shapeset_primary_language option').addClass('hide');
      $('form.shapeset select#shapeset_primary_language').next().attr('style', 'visibility: hidden !important');
    }else{
      console.log('- langs selected, adding');
      // turn on all of the languages that are selected
      $('form.shapeset select#shapeset_primary_language option').each(function(){
        if (values.indexOf($(this).attr('value')) == -1){
          $(this).addClass('hide');
        }else{
          $(this).removeClass('hide');
        }
      })
  
      // update the primary language list
      // - if current primary lang is not in the language list, reset the value to the first selected lang
      var primary = $('form.shapeset select#shapeset_primary_language').val();
      console.log('- current primary selection is ' + primary);
      if ( (primary == null || primary == '') || (primary != null && primary != '' && values.indexOf(primary) == -1) ) {

        console.log('@@@@ reseting primary language selection');
        $('form.shapeset select#shapeset_primary_language').val(values[0]);
      }
    }
  }

  // update a block of code with the new provided locale
  // - new_locale = new locale
  // - tab = jquery reference to tab that needs to be updated
  // - form = jquery reference to form that needs to be updated
  function update_block_with_new_locale(new_locale, tab, form){
    console.log('++++ update block with new locale');
    // get old locale
    var old_locale = $(form).attr('id');

    console.log('--> old_locale = ' + old_locale + '; new locale = ' + new_locale);
    // if the new locale is the same as the old one, do nothing
    if (old_locale != new_locale){
      console.log('--> locales are different, so update tab/form');

      // first get name for this locale
      var name = $('form.shapeset select#shapeset_languages option[value="' + new_locale + '"]').html();

      console.log('--> new locale name = ' + name);

      ////////////
      // update the tab
      ////////////
      // data locale
      $(tab).attr('data-locale', new_locale);

      // new href
      $(tab).find('a').attr('href', '#' + new_locale);

      // new link text
      $(tab).find('a').html(name);

      // remove active class unless there is only one tab
      console.log('--> remove active class');
      if ($('ul.nav.nav-tabs li').length > 1){
        console.log(tab);
        $(tab).removeClass('active');
        console.log(tab);
      }

      ////////////
      // update the form
      ////////////
      // data locale
      $(form).attr('data-locale', new_locale);

      // replace main id in tab-pane div
      $(form).attr('id', new_locale);

      // replace all form field ids (_locale)
      $(form).find('input, select, textarea, div.input').each(function(){
        $(this).attr('id', $(this).attr('id').replace('_' + old_locale, '_' + new_locale));
      });

      // replace all form field names ([locale])
      $(form).find('input, select, textarea').each(function(){
        $(this).attr('name', $(this).attr('name').replace('[' + old_locale + ']', '[' + new_locale + ']'));
      });

      // replace all label fors (_locale)
      $(form).find('label').each(function(){
        $(this).attr('for', $(this).attr('for').replace('_' + old_locale, '_' + new_locale));
      });
      
      // remove active class unless there is only one tab
      if ($('ul.nav.nav-tabs li').length > 1){
        $(form).removeClass('in').removeClass('active');
      }

      // replace tinymce class name (-locale)
      $(form).find('textarea').each(function(){
        $(this).removeClass('tinymce-' + old_locale);
        $(this).addClass('tinymce-' + new_locale);
      });


    }

    // show the tab
    // do not show form for the tab has to be clicked to show it
    $(tab).show();
    //$(form).show();

    console.log('++++ update block with new locale END');
  }

  // if no tabs are marked as active, activate the first one
  function activate_first_tab(){
    if ($('ul.nav.nav-tabs li.active').length == 0){
      $('ul.nav.nav-tabs li:first a').trigger('click');
    }
  }

  // make sure the primary language is first
  function make_primary_first(){
    var primary = $('form.shapeset select#shapeset_primary_language').val();
    if ( primary != null && primary != '' && $('ul.nav.nav-tabs li:first').data('locale') != primary ){
      console.log('-- making sure primary language is first tab');
      var ptab = $('ul.nav.nav-tabs li[data-locale="' + primary + '"]');
      var pform = $('.tab-content .tab-pane[data-locale="' + primary + '"]') 

      // have to turn off tinymce first
      tinyMCE.execCommand('mceFocus', false, $(pform).find('textarea').attr('id'));
      tinyMCE.execCommand('mceRemoveControl', false, $(pform).find('textarea').attr('id'));

      ptab.parent().prepend(ptab);
      pform.parent().prepend(pform);

      // have to rebuild tinymce
      // tinyMCE.init(gon.tinymce_options);
      tinyMCE.execCommand('mceAddControl', true, $(pform).find('textarea').attr('id'));

    }    
  }

  // when a language changes, hide/show the appropriate language tabs
  function load_language_tabs(){
    console.log('=== load lang tabs');
    var values = $('form.shapeset select#shapeset_languages').val();

    if (values == null || values.length == 0){
      console.log('- no selections so defualt to current app locale');
      // no items selected so default to current locale
      values = [I18n.locale]; 
    }
    console.log('--> current selected langs = ' + values);

    // get the index for each locale in tabs
    var existing_indexes = [];
    var existing_locales = $('ul.nav.nav-tabs li').map(function(){ return $(this).data('locale'); }).toArray();
    console.log('--> existing locales = ');
    console.log(existing_locales);
    for(var i=0; i<values.length; i++){
      console.log('--- testing if ' + values[i] + ' is already a tab');
      existing_indexes.push(existing_locales.indexOf(values[i]));
    }
    console.log('--> existing tab indexes = ');
    console.log(existing_indexes);

    // if currently there are more than one tab, 
    // see if any of the tabs are the currently selected locale(s)
    // if so - keep it
    // else, remove it
    if ($('ul.nav.nav-tabs li').length > 1){
      console.log('-- there was more than one tab');

      // work on tabs
      console.log('--> removing un needed tabs');
      var i = 0;
      for(var index=0; index<$('ul.nav.nav-tabs li').length; index++){
        var item = $('ul.nav.nav-tabs li')[index];
        if ( (allAreEqual(existing_indexes) == false && existing_indexes.indexOf(i) != -1 ) || (allAreEqual(existing_indexes) == true && i == 0) ){
          // make it active
//          $(item).addClass('active');
        }else{
          // remove this tab
          $(item).remove();
        }

        i++;
      }
      
      // work on form 
      console.log('--> removing un needed forms');
      i = 0;
      for(var index=0; index<$('.tab-content .tab-pane').length; index++){
        var item = $('.tab-content .tab-pane')[index];
        if ( (allAreEqual(existing_indexes) == false && existing_indexes.indexOf(i) != -1 ) || (allAreEqual(existing_indexes) == true && i == 0) ){
//          $(item).addClass('in active');
        }else{
          $(item).remove();
        }

        i++;
      }
    }

    // now any existing tabs that match the current selection are shown
    // or the first tab is the only one shown because no existing tabs are in the current selection

    // now go through each locale and if it does not exist as a tab yet, add it
    for(var index=0; index<values.length; index++){
      console.log('==> index = ' + index + '; locale = ' + values[index] + '; existing index = ' + existing_indexes[index]);

      // if no existing indexes exist, just update the first block with the locale if this is the first locale
      if ( allAreEqual(existing_indexes) == true && index == 0){
        console.log('--> updating first block with new locale');
        // now update first block to use the new locale
        update_block_with_new_locale(values[index], $('ul.nav.nav-tabs li:first'), $('.tab-content .tab-pane:first'))
      
      }else if ( existing_indexes[index] == -1 ){
        console.log('--> add new block');
        // this is a new locale, need to add it

        // first have to turn off all tinymce so clone works nicely
        // for (var i=0; i<=tinyMCE.editors.length; i++) {
        //   tinyMCE.editors[0].remove();
        // };
        // tinyMCE.editors.length = 0;
        tinyMCE.execCommand('mceFocus', false, $('.tab-content .tab-pane:first textarea').attr('id'));
        tinyMCE.execCommand('mceRemoveControl', false, $('.tab-content .tab-pane:first textarea').attr('id'));


        // copy the first tab and insert it in appropriate index
        var tab = $('ul.nav.nav-tabs li:first').clone().hide();
        var form = $('.tab-content .tab-pane:first').clone().removeClass('active').removeClass('in');

        // now insert in the correct index
        $('ul.nav.nav-tabs').insertAt(index, tab);
        $('.tab-content').insertAt(index, form);

        // update the locale values
        update_block_with_new_locale(values[index], tab, form);

        // have to rebuild tinymce
        // tinyMCE.init(gon.tinymce_options);
        tinyMCE.execCommand('mceAddControl', true, $('.tab-content .tab-pane:first textarea').attr('id'));
        tinyMCE.execCommand('mceAddControl', true, $(form).find('textarea').attr('id'));

      }
    }

    // make sure the primary language is first
    make_primary_first();

    console.log('=== load lang tabs end');
  }


  // initalize the fancy select boxes
  $('select.selectpicker-language').select2({width:'element', allowClear:true});
  $('.select2-container').removeClass('form-control');


  $('form.shapeset select#shapeset_languages').change(function(){
    load_primary_languages();
    load_language_tabs();
    activate_first_tab();
  });

  $('form.shapeset select#shapeset_primary_language').change(function(){
    make_primary_first();
    activate_first_tab();
  });


  // set the languages/tabs when page loads
  load_primary_languages();
  load_language_tabs();
  make_primary_first();
  activate_first_tab();


});