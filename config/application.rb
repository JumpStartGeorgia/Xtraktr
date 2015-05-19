require File.expand_path('../boot', __FILE__)

#require 'rails/all'
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module BootstrapStarter
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    config.mongoid.observers = :user_observer, :dataset_observer, :time_series_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Tbilisi'

    config.i18n.enforce_available_locales = false

    config.i18n.available_locales = [:en, :ka]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    # rails will fallback to config.i18n.default_locale translation
    config.i18n.fallbacks = true

    # rails will fallback to en, no matter what is set as config.i18n.default_locale
    config.i18n.fallbacks = [:en]
    config.i18n.fallbacks = {'ka' => 'en'}

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation, :encrypted_password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'


    config.assets.precompile += %w( api.js dashboard.js datasets.js embed.js exclude_answers.js exclude_questions.js explore.js explore_data.js explore_time_series.js highlights.js list.js live_search.js mappable_form.js questions.js search.js tabbed_translation_form.js time_series.js time_series_questions.js )    
    config.assets.precompile += %w( api.css boxic.css dashboard.css datasets.css embed.css exclude_answers.css exclude_questions.css explore.css highlights.css list.css mappable_form.css questions.css root.css settings.css tabbed_translation_form.css tabs.css time_series.css time_series_questions.css variables.css)    
    config.assets.precompile += %w( bootstrap.tooltip.js bootstrap-select.min.js highcharts.js highcharts-map.js highcharts-exporting.js masonry.pkgd.min.js select2/select2.min.js shBrushJScript.js shCore.js tinymce/*)    
    config.assets.precompile += %w( bootstrap-select.min.css select2.css select2-bootstrap.css shCore.css shThemeDefault.css )    

    config.assets.precompile += %w( jquery.ui.datepicker.js cocoon.js )    
    config.assets.precompile += %w( jquery.ui.datepicker.css )    


    # from: https://robots.thoughtbot.com/content-compression-with-rack-deflater
    # compress all html/json responses
    config.middleware.use Rack::Deflater
  end
end
