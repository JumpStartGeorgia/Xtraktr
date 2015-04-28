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
PageContent.create(name: 'api', title: 'API', content: '<p>The UNICEF Georgia Data Portal API allows you to get information and run analyses on the datasets and time series available on this site.&nbsp;</p>
<h2>The URL to the api is the following:</h2>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/[version]/</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently ka for Georgian or en for English)</li>
<li>[version] = the version number of the api (see below)</li>
</ul>
<h2>Access Token</h2>
<p>All API calls require an access token - a key that let\'s us know who is making the request.&nbsp;You can obtain an access token&nbsp;easily, and for free, by going <a href="#">here</a>.</p>
<h2>API Calls</h2>
<p>The following is a list of calls that are available in each version of the api.</p>') if PageContent.by_name('api').nil?

#####################
## Create API Versions/Methods
#####################
puts 'Creating API Versions/Methods'
v = ApiVersion.by_permalink('v1')
if v.blank?
  v = ApiVersion.create(permalink: 'v1', title: 'Version 1', public: true)
end
if v.api_methods.empty?
  v.api_methods.create(permalink: 'dataset_catalog', title: 'Dataset Catalog', public: true, sort_order: 1, content: '<p>Get a list of all datasets on this site.</p>
<h2>URL</h2>
<p>To call this method, use an HTTP GET request to the following URL:</p>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/v1/dataset_catalog</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently ka for Georgian or en for English)</li>
</ul>
<h2>Required Parameters</h2>
<p>The following parameters must be included in the request:</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>access_token</td>
<td>All requests must include an access_token. You can obtain an access tokeneasily, and for free, by going <a href="#">here</a>.</td>
</tr>
</tbody>
</table>
<p></p>
<h2>Optional Parameters</h2>
<p>There are no optional parameters for this call.</p>
<h2>What You Get</h2>
<p>The return object is a JSON array of all datasets in the site with the following information:</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>id</td>
<td>Unique ID of the dataset that you will need to get further information or run an analysis</td>
</tr>
<tr>
<td>title</td>
<td>The title of the dataset</td>
</tr>
<tr>
<td>source</td>
<td>The name of the source that gathered the data</td>
</tr>
<tr>
<td>start_gathered_at</td>
<td>Date the data gathering process started, format: yyyy-mm-dd (e.g., 2015-01-31)</td>
</tr>
<tr>
<td>end_gathered_at</td>
<td>Date the data gathering process finished, format: yyyy-mm-dd (e.g., 2015-01-31)</td>
</tr>
<tr>
<td>released_at</td>
<td>Date the data was released to the public by the source, format: yyyy-mm-dd (e.g., 2015-01-31)</td>
</tr>
<tr>
<td>public_at</td>
<td>Date the data was made public on this site, format: yyyy-mm-dd (e.g., 2015-01-31)</td>
</tr>
</tbody>
</table>
<h2>Examples</h2>
<p>Here is an example of what can be returned after calling this method with the following url:</p>
<div class="url">http://dev-unicef.jumpstart.ge/en/api/v1/dataset_catalog?access_token=123456789</div>
<pre class="brush:js;auto-links:false;toolbar:false;tab-size:2" contenteditable="false">{
  datasets: [
    {
      id: "1111111111",
      title: "This is a dataset!",
      source: "People",
      start_gathered_at: "2014-04-01",
      end_gathered_at: "2014-06-30",
      released_at: "2015-01-01",
      public_at: "2015-03-01"
    },
    {
      id: "2222222222",
      title: "Wow, another dataset!",
      source: "Studies R Us",
      start_gathered_at: null,
      end_gathered_at: null,
      released_at: null,
      public_at: "2015-04-15"
    }
  ]
}</pre>
<p></p>')
  v.api_methods.create(permalink: 'dataset', title: 'Dataset Details', sort_order: 2)
  v.api_methods.create(permalink: 'dataset_codebook', title: 'Dataset Codebook', sort_order: 3)
  v.api_methods.create(permalink: 'dataset_analysis', title: 'Dataset Analysis', sort_order: 4)

  v.api_methods.create(permalink: 'time_series_catalog', title: 'Time Series Catalog', sort_order: 5)
  v.api_methods.create(permalink: 'time_series', title: 'Time Series Details', sort_order: 6)
  v.api_methods.create(permalink: 'time_series_codebook', title: 'Time Series Codebook', sort_order: 7)
  v.api_methods.create(permalink: 'time_series_analysis', title: 'Time Series Analysis', sort_order: 8)
end