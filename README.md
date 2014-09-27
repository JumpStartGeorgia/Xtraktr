# JumpStart Bootstrap Starter Project

The Bootstrap Starter Project is a Ruby on Rails application with Bootstrap 3, Devise authorization and the most commonly used gems already installed and ready to go.  


## Current Versions
Look at the Gemfile for a complete list.
* Ruby 2.1.2
* Rails 3.2.18
* Bootstrap 3
* Capistrano 2.12
* Devise 2.0.4
* Paperclip 3.4.0
* Unicorn 4.8.3


## Requirements
* git
* Ruby 2.1.x
* [rvm](http://rvm.io/) - share gems between applications
* nginx - for staging/production server

Environment variables
You will need the following [Environment Variables](https://help.ubuntu.com/community/EnvironmentVariables) set. 
* APPLICATION_FROM_EMAIL - email address to send all emails from
* APPLICATION_FROM_PWD - password of above email address
* APPLICATION_ERROR_TO_EMAIL - email address to send application errors to
* DEV_FACEBOOK_APP_ID - Facebook is one of the options for logging in to the system and you must have an app account created under facebook developers. This key is for use on development/testing sites. This key stores the application id. (optional)
* DEV_FACEBOOK_APP_SECRET - This key stores the facebook application secret for development/testing sites. (optional)
* FACEBOOK_APP_ID - Facebook is one of the options for logging in to the system and you must have an app account created under facebook developers. This key is for use on production sites. This key stores the application id. (optional)
* FACEBOOK_APP_SECRET - This key stores the facebook application secret for production sites. (optional)

After you add environment variables, do the following in order for your application to be able to see the values:
* on a dev machine - reboot your computer
* on a server:
    * in console type in 'source /etc/environment'
    * logout of the server and close all terminal windows
    * log back into server and stop/start nginx and unicorn


## Internationalization/Translations
The application comes ready to work with two language site translations: Georgian and English. You can add more languages by adding more locale translation files to the [/config/locales/](/config/locales/) folder. The template file at [/app/views/layouts/application.html.erb](/app/views/layouts/application.html.erb) is setup to show all available languages. Please read the [Rails I18n](http://guides.rubyonrails.org/i18n.html) for information on how to use translations throughout your application.

In order for the application to know which language to use for the site translations, the [/config/routes.rb](/config/routes.rb) file has been updated to force a the locale of the language to be at the beginning of the URL. For instance, /en/admin/users instead of /admin/users. If the URL does not include a language locale, the default locale that is set in [/config/application.rb](/config/application.rb) will be used.  In the routes file, there is a 'scope ":locale"' statement. All routes statements that you enter by hand or that are created when you run rails g scaffold must be contained within this scope statement (all scaffold statements add routes to the top of the file so you will have to move them by hand). 


In addition to site translations, you may also need user provided content to be saved in multiple translations. This is where the [gem globalize](https://github.com/globalize/globalize/tree/3-1-stable) comes into play. In essence, this gem uses an additional table to record the translations. For example, if you have a pages table/Page model, then a page_translations table/PageTranslation model will contain all of the translated objects.

This application includes a Page/PageTranslations model as an example of how this gem works. This is a simple model to allow the admin to enter content for an about page that is rendered on the home page. Below is a brief example of all the components:

### Migration File
If you look at the second migration file at [/db/migration](/db/migration) you will see the migration file for creating the pages and page_translations tables. Also, the [/db/seeds.rb](/db/seeds.rb) file creates a record in these tables. To generate the table and populate it with inital data, run:

````ruby
rake db:migrate
rake db:seed
````

### Model Files
The [/app/models](/app/models) folder contains two files: [page.rb](/app/models/page.rb) and [page_translation.rb](/app/models/page_translation.rb). 

#### page.rb 
A 'translates' call at the top of the file tells globalize which fields should have translations. Also notice the attr_accessible line with the :page_translations_attributes value. This must be there if you want to add translated text through a web form.

#### page_translation.rb
In this file, make sure that you do not include the mapping id field, in this case page_id, in the validates presence statement. The value is not populated until after the page model is saved so validation on this would always fail.

This file also includes some custom code that allows the user to enter content for one language and have it automatically be applied to all other languages if no content in that language is provided. This is what the 'required_data_provided?' and 'add_required_data methods' are for. In this case, the title and content are required so if both of them are not provided, the text from another language will automatically be used (more on this part later).

### Controllers
For any controller that is allowing a user to add/edit translated content, please change the controller in the following ways (refer to [/app/controllers/admin/page_controller.rb](/app/controllers/admin/page_controller.rb) for an exmaple):

#### new method
In order for the user to be able to enter translated content for your model object, you must first build translation objects for each locale that your application is using. So in the new method, after creating the new object, insert the following lines (chaging page to the name of your model):

````ruby
# create the translation object for however many locales there are
# so the form will properly create all of the nested form fields
I18n.available_locales.each do |locale|
  @page.page_translations.build(:locale => locale.to_s)
end
````

#### create method
As described in the model section above, there is custom code to check if all required translated content is provided for each locale, and if not, it adds the content from another language if it exists. This is where those model methods get called. In the create method, after creating a new model object with the params, insert the following line (changing page to the name of your model):

````ruby
add_missing_translation_content(@page.page_translations)
````

This 'add_missing_translation_content' method is located in the application_controller.rb and discussed more below.

#### update method
Similarly to the create method, the update method also checks for required translated content. But to do this in an update statement requires a few steps.
* after the find statement, add the following (changing page to the name of your model): 

    ````ruby
    @page.assign_attributes(params[:page])
    add_missing_translation_content(@page.page_translations)
    ````
* now change the model.update_attributes statement to just a simple save statement (changing page to the name of your model): @page.save

#### application_controller.rb
In the [application_controller](/app/controllers/application_controller.rb), there is a method called 'add_missing_translation_content' which is called before a model with translations is saved and calls the above model methods to add missing translated content if necessary. This method gets the default locale translations and compares that against all other locales. If the other locales are missing required content, that content is pulled from the default locale translation object.

### Views
You can look at [/app/views/admin/pages/_form.html.erb](/app/views/admin/pages/_form.html.erb) for an example of how to update the form to work with translations.
* create_sorted_translation_objects - this method is located in [/app/helpers/application_helper.rb](/app/helpers/application_helper.rb) and simply orders the locales so that the default locale is first and the rest are in alphabetical order.
* field_for - this is standard Rails syntax for adding form fields in nested objects
* multilanguage_nested div - there is a div that is wrapped around each language. It will show a header with the language the form fields apply to followed by the form fields. The file [/app/assets/stylesheets/application.css.less](/app/assets/stylesheets/application.css.less) has styles attached to #form-xx, where xx is the abbreviation for the locale so you can style each language to look differently and be easily recognizable. 
* you must include a hidden field for the local field so Rails knows which language the content applies to

When you are rendering the text on a page, you use the attribute names listed in the translates line at the top of the [/app/models/page.rb](/app/models/page.rb) file. So for example, if we have an @page object, we can get the translated content field by calling @page.content. The globalize gem will look at which locale is currently being used (from the locale in the URL) and then get the content for that locale.

### Final Note
It is quite possible that you will not need to use the Page model. In that case, feel free to delete the following files:
* [/app/controllers/admin/pages_controller.rb](/app/controllers/admin/pages_controller.rb)
* [/app/models/page.rb](/app/models/page.rb)
* [/app/models/page_translation.rb](/app/models/page_translation.rb)
* [/app/views/admin/pages](/app/views/admin/pages)
* [/db/migration/(create_pages.rb)](/db/migration/)

You will also want to remove the link to the admin pages section at [/app/views/admin/index.html](/app/views/admin/index.html).
 
## Authentication
The application uses [Devise](https://github.com/plataformatec/devise/tree/v2.0) to manage authentication for the system. In [/db/migrate](/db/migrate) is a file that will create the users table that you will need to use Devise authentication. Simply run rake db:migrate to create the table.

By default, no users are in the table. In order to create a user, it is best to do the following from the terminal:

```ruby
rails c
User.create(:email => '___', :password => '___', :role => 99)
````

You can fill in the appropriate email and password above.

By default, the application comes with two roles: User and Admin. The roles are set in the [/app/models/user.rb](/app/models/user.rb) file using a hash called ROLES: ROLES = {:user => 0, :admin => 99}. You can add more roles as your application requires. When new users are created and no role is defined, the user is assigned the User role by default.

The roles are setup to use inheritance. This means that if your application has a requirement that a user has the role of User, a user with the role of Admin will also be allowed access. The [/app/models/user.rb](/app/models/user.rb) file has a method called 'role?' that compares the current user's role to what is required and if the user's role is >= the required role, the user will be granted access. You can see this in action by looking at the top of [/app/controllers/admin_controller.rb](/app/controllers/admin_controller.rb). This code says that the user can only continue if they are an Admin.

By default, no login link appears on the site. You can add one if you want with a link like: 

````ruby
link_to(t('helpers.links.sign_in2'), new_user_session_path)
````

You can also access the login page by using one of the following urls
* /users/login
* /admin - going to this page will redirect you to the login screen and after login send you to the admin page

There is a users admin section that is provided in the application that allows you to manage users. If you created your user account with the Admin role, you will see a link to the Admin Section in the top-right corner of the header when you click on your nickname.


## Omniauth (facebook) Login
Omniauth login allows users to login in with 3rd party systems like facebook or twitter. This application has facebook login built in by default, but is turned off by default. If you want to use facebook for logging in, do the following:
* Go to [app/controllers/application_controller.rb](app/controllers/application_controller.rb) and set @enable_omniauth = true
* Register an app on [facebook](https://developers.facebook.com/apps/)
* Create the appropriate facebook environment variables mentioned in the last section using the app id and app secret facebook gives you


## Deployment with Capistrano
[Capistrano](https://github.com/capistrano/capistrano/wiki) is used to deploy the application to a staging and production enviornment. 

The config file at [/config/deploy.rb](/config/deploy.rb) is the basic setup for capistrano deploying. The file is set up to:
* deploy to multiple environments, default is staging
* only keep the last 2 releases
* only compile and send the assets if the assets have changed

To setup the config files for the staging and production server, look in the [/config/deploy](/config/deploy) folder. The staging.rb and production.rb files contain the variables that are needed for deployment (server user name, server folder location, github project name, etc). 

Within the /config/deploy folder are folders for each server you can deploy to (staging and production) that contain more configuration.
* nginx.conf
    * update this file with the application and user variables you set in the staging.rb/production.rb file
    * server name - root url to site
    * timeout length - default is 30 seconds
* unicorn.rb
    * update this file with the application and user variables you set in the staging.rb/production.rb file
    * port number - each application on the server must have a unique port number, run 'netstat -anltp | grep "LISTEN"' to see which ports are being used
    * timeout length - default is 30 seconds
    * number of worker processes - default is 2
* unicorn_init.sh
    * update this file with the application and user variables you set in the staging.rb/production.rb file

The staging environment is set as the default so if you run 'cap deploy' the application will be deployed to the staging server. Use 'cap production deploy' to deploy to the production server.

## Helpful Additions/Tools

### Latin <-> Georgian
[Transparency International Georgia](https://github.com/tigeorgia/georgian-language-toolkit) created a ruby script to convert Georgian text into it's Latin equivalent letters, or vice-versa. The script is located at /config/initializers/latinize.rb. To convert Georgian text, do the following: 'გამარჯობათ'.latinize. To convert Latin text, do the following: 'hello'.georgianize.

### to_bool
Many times Rails parameters contain boolean values, but they are read in as string. [/config/initializers/to_bool.rb](/config/initializers/to_bool.rb) provides a to_bool function to Strings that will convert a string value to a boolean value.

### TinyMCE
[TinyMCE](http://www.tinymce.com/) is a javascript library for creating textarea boxes with rich-text editing controls. This application uses the (tinymce-rails gem)[https://github.com/spohlenz/tinymce-rails] to make the process of using the library a little more integrated into rails.

To configure which controls are available in the rich-text editor, edit the file located at [/config/tinymce.yml](/config/tinymce.yml).

To add the tinymce editor to a textarea control, do the following:
* add the following to the top of the form page:

    ````ruby
    <%= tinymce_assets %>
    <%= tinymce %>
    ````
* add the class 'tinymce' to the textarea box

To render the text that is saved use the following (assuming content has the text): 

````ruby
simple_format_no_tags(content, {}, {sanitize: false})
````

### Sending Emails
The application is setup to send email using Google SMTP. You can view/edit these settings at [/config/initializers/gmail.rb](/config/initializers/gmail.rb).

### Emails in Development Mode
[Mailcatcher](http://mailcatcher.me/) is a helpful gem in development mode for catching all emails that your application sends, whether they be error message emails, feedback emails, etc and showing them in a web interface instead of actually sending them to the intended users. Simply run mailcatcher at the command line and then go to [http://127.0.0.1:1080/](http://127.0.0.1:1080/) to see the emails that are sent. You will be able to see the html and text version of the emails.

### Exception Notifications
[Exception Notification](http://smartinez87.github.io/exception_notification/) is a gem that is wonderful at catching errors that occur in your application and sending you emails to let you know about it. You can customize the email settings (i.e., subject, to email, from email, etc) by going to [/config/environments](/config/environments) and updating the appropriate file.  Look at the bottom of the file to see the default settings that come in this application. You can customize what type of exceptions you want to be notified about by editing the code at the bottom of [/app/controllers/application_controller.rb](/app/controllers/application_controller.rb).

### Gon
[Gon](https://github.com/gazay/gon) is a gem that lets you set varaibles in your controllers and have them be accessible in javascript.

### jQuery DataTables
[DataTables](http://www.datatables.net/) turns a boring table of data into one that can be sorted, searched and paginated. The user admin page uses DataTables with ajax calls. The following files are used for this:
* [/app/datatables/user_datatable.rb](/app/datatables/user_datatable.rb) - this file defines the methods to create the sql to search, sort and paginate and then return the results in the desired format.
* [/app/controllers/admin/users_controller.rb](/app/controllers/admin/users_controller.rb) - the index action calls the user_datatable.rb file when called using json.
* [/app/views/admin/users/index.html.erb](/app/views/admin/users/index.html.erb) - this file contains the html table and the data-source attribute with the url to get the data via ajax
* [/app/assets/javscripts/search.js](/app/assets/javscripts/search.js) - this file assigns the DataTable object to the html table

To create your own datatables, simply copy and paste these files and tweak as necessary.

Also, the translation of the DataTable interface into Georgian is located at [/public/datatable_ka.txt](/public/datatable_ka.txt). If the page is in Georgian, this file path is set in a variable in [/app/controllers/application_controller.rb](/app/controllers/application_controller.rb) under the method initialize_gon.

### Unicorn
[Unicorn](http://unicorn.bogomips.org/) is a Rails server that this application is setup to use in staging and production environments.

### Maintenance Mode
The nginx config file located at [/config/deploy/staging/nginx.conf](/config/deploy/staging/nginx.conf) and [/config/deploy/production/nginx.conf](/config/deploy/production/nginx.conf) is setup to look for a file in the [/public](/public) folder called maintenance.html.  If this file is found, the file will automatically be shown instead of processing whatever request the user is asking for. 

In the /public folder, there is a file called [maintenance_disabled.html](/public/maintenance_disabled.html). This file is a plain html file that is setup to have a similar look as the [/app/views/layout/application.html.erb](/app/views/layout/application.html.erb). The content of this file is a simple message to the user indicating that the site is down and for how long. 

To turn on maintenance mode, either rename the file and deploy or simply rename the file on the server.

To turn off maintenance mode, either rename the file to anything other than maintenance.html and deploy or simply renmae the file on the server.


## To use as start of new project
This is a short description on how to use this repo as the start of a new project.

* On your machine, in projects folder, create folder for new project
* cd into folder and run:
    * git clone git@github.com:JumpStartGeorgia/Bootstrap-Starter.git .
* the new project does not need to include all of the git history from the bootstrap starter project. So do the following to start git over from scratch:
    * rm -rf .git
    * git init
    * git add -A
    * git commit -am ‘_________’
* push new project to repo for first time
    * go to github and copy the clone url for the new project
    * run: 
        * git remote add origin [clone url here]
        * git push -u origin master
