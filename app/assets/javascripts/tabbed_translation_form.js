  // see if all items in an array are the same value
  // from: http://stackoverflow.com/a/21266395
  function allAreEqual(array){
    if(!array.length) return true;
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
  if (typeof tinyMCE !== "undefined"){
    gon.tinymce_options.height = $('form.tabbed-translation-form .tab-content .tab-pane:first textarea').height();
    gon.tinymce_options.width = $('form.tabbed-translation-form .tab-content .tab-pane:first textarea').width();
    tinyMCE.init(gon.tinymce_options);
  }


  // update the default language drop down
  function load_default_languages(){
    console.log('load default langs');
    // if not items are selected, hide the default language selector
    // else, show it with the options of what is selected in default language
    console.log('selected languages = ' + $('form.tabbed-translation-form select.languages option:selected').length);
    var values = $('form.tabbed-translation-form select.languages').val();

    if (values == null || values.length == 0){
      console.log('- no selected, hiding');
      $('form.tabbed-translation-form select.default-language').val('');
      $('form.tabbed-translation-form select.default-language option').addClass('hide');
      $('form.tabbed-translation-form select.default-language').next().attr('style', 'visibility: hidden !important');
    }else{
      console.log('- langs selected, adding');
      // turn on all of the languages that are selected
      $('form.tabbed-translation-form select.default-language option').each(function(){
        if (values.indexOf($(this).attr('value')) == -1){
          $(this).addClass('hide');
        }else{
          $(this).removeClass('hide');
        }
      })
  
      // update the default language list
      // - if current default lang is not in the language list, reset the value to the first selected lang
      var default_language = $('form.tabbed-translation-form select.default-language').val();
      console.log('- current default selection is ' + default_language);
      if ( (default_language == null || default_language == '') || (default_language != null && default_language != '' && values.indexOf(default_language) == -1) ) {

        console.log('@@@@ reseting default language selection');
        $('form.tabbed-translation-form select.default-language').val(values[0]);
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
      var name = $('form.tabbed-translation-form select.languages option[value="' + new_locale + '"]').html();

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
      if ($('form.tabbed-translation-form ul.nav.nav-tabs li').length > 1){
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
      if ($('form.tabbed-translation-form ul.nav.nav-tabs li').length > 1){
        $(form).removeClass('in').removeClass('active');
      }

      // reset form fields
      $(form).find('input, select, textarea').each(function(){
        $(this).val('');
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
    if ($('form.tabbed-translation-form ul.nav.nav-tabs li.active').length == 0){
      $('form.tabbed-translation-form ul.nav.nav-tabs li:first a').trigger('click');
    }
  }

  // make sure the default language is first
  function make_default_first(){
    var default_language = $('form.tabbed-translation-form select.default-language').val();
    if ( default_language != null && default_language != '' && $('form.tabbed-translation-form ul.nav.nav-tabs li:first').data('locale') != default_language ){
      console.log('-- making sure default language is first tab');
      var ptab = $('form.tabbed-translation-form ul.nav.nav-tabs li[data-locale="' + default_language + '"]');
      var pform = $('form.tabbed-translation-form .tab-content .tab-pane[data-locale="' + default_language + '"]') 

      // have to turn off tinymce first
      tinyMCE.execCommand('mceFocus', false, $(pform).find('textarea').attr('id'));
      tinyMCE.execCommand('mceRemoveControl', false, $(pform).find('textarea').attr('id'));

      ptab.parent().prepend(ptab);
      pform.parent().prepend(pform);

      // have to rebuild tinymce
      tinyMCE.execCommand('mceAddControl', true, $(pform).find('textarea').attr('id'));
    }    

    // add icon to default language
    // first remove all icons
    $('form.tabbed-translation-form ul.nav.nav-tabs li a span.glyphicon').remove();
    // add to default
    $('form.tabbed-translation-form ul.nav.nav-tabs li[data-locale="' + default_language + '"] a').prepend($('form.tabbed-translation-form ul.nav.nav-tabs').data('default-language-icon'));
  }

  // when a language changes, hide/show the appropriate language tabs
  function load_language_tabs(){
    console.log('=== load lang tabs');
    var values = $('form.tabbed-translation-form select.languages').val();

    if (values == null || values.length == 0){
      console.log('- no selections so defualt to current app locale');
      // no items selected so default to current locale
      values = [I18n.locale]; 
    }
    console.log('--> current selected langs = ' + values);

    // get the index for each locale in tabs
    var existing_indexes = [];
    var existing_locales = $('form.tabbed-translation-form ul.nav.nav-tabs li').map(function(){ return $(this).data('locale'); }).toArray();
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
    if ($('form.tabbed-translation-form ul.nav.nav-tabs li').length > 1){
      console.log('-- there was more than one tab');

      // work on tabs
      console.log('--> removing un needed tabs');
      var i = 0;
      for(var index=0; index<$('form.tabbed-translation-form ul.nav.nav-tabs li').length; index++){
        var item = $('form.tabbed-translation-form ul.nav.nav-tabs li')[index];
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
      for(var index=0; index<$('form.tabbed-translation-form .tab-content .tab-pane').length; index++){
        var item = $('form.tabbed-translation-form .tab-content .tab-pane')[index];
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
        update_block_with_new_locale(values[index], $('form.tabbed-translation-form ul.nav.nav-tabs li:first'), $('form.tabbed-translation-form .tab-content .tab-pane:first'))
      
      }else if ( existing_indexes[index] == -1 ){
        console.log('--> add new block');
        // this is a new locale, need to add it

        // first have to turn off all tinymce so clone works nicely
        // for (var i=0; i<=tinyMCE.editors.length; i++) {
        //   tinyMCE.editors[0].remove();
        // };
        // tinyMCE.editors.length = 0;
        $('form.tabbed-translation-form .tab-content .tab-pane:first textarea').each(function(){
          tinyMCE.execCommand('mceFocus', false, $(this).attr('id'));
          tinyMCE.execCommand('mceRemoveControl', false, $(this).attr('id'));
        });


        // copy the first tab and insert it in appropriate index
        var tab = $('form.tabbed-translation-form ul.nav.nav-tabs li:first').clone().hide();
        var form = $('form.tabbed-translation-form .tab-content .tab-pane:first').clone().removeClass('active').removeClass('in');

        // now insert in the correct index
        $('form.tabbed-translation-form ul.nav.nav-tabs').insertAt(index, tab);
        $('form.tabbed-translation-form .tab-content').insertAt(index, form);

        // update the locale values
        update_block_with_new_locale(values[index], tab, form);

        // have to rebuild tinymce
        // tinyMCE.init(gon.tinymce_options);
        $('form.tabbed-translation-form .tab-content .tab-pane:first textarea').each(function(){
          tinyMCE.execCommand('mceAddControl', true, $(this).attr('id'));
        });
        $(form).find('textarea').each(function(){
          tinyMCE.execCommand('mceAddControl', true, $(this).attr('id'));
        })

      }
    }

    // make sure the default language is first
    make_default_first();

    console.log('=== load lang tabs end');
  }


  // initalize the fancy select boxes
  $('form.tabbed-translation-form select.selectpicker-language').select2({width:'element', allowClear:true});
  $('form.tabbed-translation-form select.selectpicker-language-disabled').select2({width:'element'});
  $('form.tabbed-translation-form select.selectpicker-language-disabled').select2('readonly', true);
  // remove class that causes conflicting styles
  $('form.tabbed-translation-form .select2-container').removeClass('form-control');


  // when language changes, update:
  // - default language list
  // - language tabs/forms
  // - activate first tab if not active
  $('form.tabbed-translation-form select.languages').change(function(){
    load_default_languages();
    load_language_tabs();
    activate_first_tab();
  });

  // when default language changes
  // - move it to be the first tab
  // - and activate it no other active
  $('form.tabbed-translation-form select.default-language').change(function(){
    make_default_first();
    activate_first_tab();
  });

  // set the languages/tabs when page loads
  load_default_languages();
  load_language_tabs();
  make_default_first();
  activate_first_tab();


});