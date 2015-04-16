# encoding: UTF-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

=begin
#####################
## Languages
#####################
puts 'loading languages'
Language.delete_all
langs = [
  ["af", "Afrikaans"],
  ["sq", "shqipe"],
  ["ar", "العربية‏"],
  ["hy", "Հայերեն"],
  ["az", "Azərbaycan­ılı"],
  ["eu", "euskara"],
  ["be", "Беларускі"],
  ["bg", "български"],
  ["ca", "català"],
  ["hr", "hrvatski"],
  ["cs", "čeština"],
  ["da", "dansk"],
  ["div", "ދިވެހިބަސް‏"],
  ["nl", "Nederlands"],
  ["en", "English"],
  ["et", "eesti"],
  ["fo", "føroyskt"],
  ["fi", "suomi"],
  ["fr", "français"],
  ["gl", "galego"],
  ["ka", "ქართული"],
  ["de", "Deutsch"],
  ["el", "ελληνικά"],
  ["gu", "ગુજરાતી"],
  ["he", "עברית‏"],
  ["hi", "हिंदी"],
  ["hu", "magyar"],
  ["is", "íslenska"],
  ["id", "Bahasa Indonesia"],
  ["it", "italiano"],
  ["ja", "日本語"],
  ["kn", "ಕನ್ನಡ"],
  ["kk", "Қазащb"],
  ["sw", "Kiswahili"],
  ["kok", "कोंकणी"],
  ["ko", "한국어"],
  ["ky", "Кыргыз"],
  ["lv", "latviešu"],
  ["lt", "lietuvių"],
  ["mk", "македонски јазик"],
  ["ms", "Bahasa Malaysia"],
  ["mr", "मराठी"],
  ["mn", "Монгол хэл"],
  ["no", "norsk"],
  ["fa", "فارسى‏"],
  ["pl", "polski"],
  ["pt", "Português"],
  ["pa", "ਪੰਜਾਬੀ"],
  ["ro", "română"],
  ["ru", "русский"],
  ["sa", "संस्कृत"],
  ["sr", "srpski"],
  ["sk", "slovenčina"],
  ["sl", "slovenski"],
  ["es", "español"],
  ["sv", "svenska"],
  ["syr", "ܣܘܪܝܝܐ‏"],
  ["ta", "தமிழ்"],
  ["tt", "Татар"],
  ["te", "తెలుగు"],
  ["th", "ไทย"],
  ["tr", "Türkçe"],
  ["uk", "україньска"],
  ["ur", "اُردو‏"],
  ["uz", "U'zbek"],
  ["vi", "Tiếng Việt"],
  ["zh-TW", "繁體中文"],
  ["zh-CN", "简体中文"]
]

langs = langs.map{|x| {locale: x[0], name: x[1]}}
Language.collection.insert(langs)
=end

#####################
## Create app user and api key
#####################
puts 'Creating app user and api key'
email = 'application@mail.com'
if User.where(email: email).nil?
  #User.where(email: email).destroy
  u = User.create(email: email, password: Devise.friendly_token[0,20], role: 0)
  u.api_keys.create
end

#####################
## Create page content records
#####################
puts 'Creating page content records'
PageContent.create(name: 'instructions', title: 'Instructions', content: 'coming soon...') if PageContent.by_name('instructions').nil?
PageContent.create(name: 'contact', title: 'Contact', content: 'coming soon...') if PageContent.by_name('contact').nil?
PageContent.create(name: 'disclaimer', title: 'Disclaimer', content: 'coming soon...') if PageContent.by_name('disclaimer').nil?
PageContent.create(name: 'api', title: 'API', content: '<p>The UNICEF Georgia Data Portal API allows you to get information and run analyses on the datasets and time series available on this site.</p>
<h2>The URL to the api is the following:</h2>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/[version]/</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently ka for Georgian or en for English)</li>
<li>[version] = the version number of the api (see below)</li>
</ul>
<h2>API Calls</h2>
<p>The following is a list of calls that are available in each version of the api.</p>') if PageContent.by_name('api').nil?

#####################
## Create API Versions/Methods
#####################
puts 'Creating API Versions/Methods'
v = ApiVersion.by_permalink('v1')
if v.blank?
  v = ApiVersion.create(permalink: 'v1', title: 'Version 1')
end
if v.api_methods.empty?
  v.api_methods.create(permalink: 'dataset_catalog', title: 'Dataset Catalog', sort_order: 1)
  v.api_methods.create(permalink: 'dataset', title: 'Dataset Details', sort_order: 2)
  v.api_methods.create(permalink: 'dataset_codebook', title: 'Dataset Codebook', sort_order: 3)
  v.api_methods.create(permalink: 'dataset_analysis', title: 'Dataset Analysis', sort_order: 4)

  v.api_methods.create(permalink: 'time_series_catalog', title: 'Time Series Catalog', sort_order: 5)
  v.api_methods.create(permalink: 'time_series', title: 'Time Series Details', sort_order: 6)
  v.api_methods.create(permalink: 'time_series_codebook', title: 'Time Series Codebook', sort_order: 7)
  v.api_methods.create(permalink: 'time_series_analysis', title: 'Time Series Analysis', sort_order: 8)
end