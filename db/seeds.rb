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
## Build search index
#####################
puts 'Building search index'
if Dataset.first._keywords.nil? || TimeSeries.first._keywords.nil?
  puts "- starting index"  
  Rake::Task['mongoid_search:index'].invoke
  puts "- finished index"  
end

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
PageContent.create(name: 'contact', title_translations: {'en' => 'Contact', 'ka' => 'კონტაქტი'}, content_translations: {'en' => '<p>If you would like to find out more about our data or have questions about datasets on this site, please send us an email or call us at:</p>
<p>
tbilisi@unicef.org
<br/>
+995 32 2 23 23 88 or +995 32 2 25 11 30 
</p>
', 'ka' => '<p>თუ გაქვთ რაიმე სახის შეკითხვა ან გსურთ მონაცემების შესახებ უფრო მეტი ინფორმაციის მიღება, გთხოვთ დაგვიკავშრდეთ ქვემოთ მითითებული ელ-ფოსტის ან ტელეფონის საშუალებით:</p>
<p>
tbilisi@unicef.org
<br/>
+995 32 2 23 23 88 or +995 32 2 25 11 30 
</p>'}) if PageContent.by_name('contact').nil?

PageContent.create(name: 'disclaimer', title: 'Disclaimer', content: 'coming soon...') if PageContent.by_name('disclaimer').nil?
if ENV['reload_api_docs'] && PageContent.by_name('api').present?
  PageContent.by_name('api').destroy
end
PageContent.create(name: 'api', title: 'API', content: '<p>The UNICEF Georgia Data Portal API allows you to get information and run analyses on the datasets and time series available on this site.</p>
<h2>The URL to the api is the following:</h2>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/[version]/</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently <strong>ka</strong> for Georgian or <strong>en</strong> for English)</li>
<li>[version] = the version number of the api (see below)</li>
</ul>
<h2>Access Token</h2>
<p>All API calls require an access token - a key that let\'s us know who is making the request.You can obtain an access tokeneasily, and for free, by going <a href="#">here</a>.</p>
<h2>API Calls</h2>
<p>The following is a list of calls that are available in each version of the api.</p>') if PageContent.by_name('api').nil?

PageContent.create(name: 'license', title_translations: {'en' => 'Licensing', 'ka' => 'ნებართვა'}, content_translations: {'en' => '<p>To review UNICEF\'s terms of use, licensing, and other relevant information, please visit UNICEF\'s index (English only) of important legal information.</p>
<p><a href="http://www.unicef.org/about/legal_index.html" target="_blank">http://www.unicef.org/about/legal_index.html</a></p>', 'ka' => '<p>UNICEF-ის გამოყენების წესების, ნებართვისა და სხვა რელევანტური ინფორმაციის მისაღებად, გთხოვთ ეწვიოთ UNICEF-ის მნიშვნელოვანი სამართლებრივი ინფორმაციის სიას.</p>
<p><a href="http://www.unicef.org/about/legal_index.html" target="_blank">http://www.unicef.org/about/legal_index.html</a></p>'}) if PageContent.by_name('license').nil?

#####################
## Create API Versions/Methods
#####################
puts 'Creating API Versions/Methods'
v = ApiVersion.by_permalink('v1')
if ENV['reload_api_docs'] && v.present?
  v.destroy
  v = nil
end
if v.blank?
  v = ApiVersion.create(permalink: 'v1', title: 'Version 1', public: true)
end
if v.api_methods.empty?
  v.api_methods.create(permalink: 'dataset_catalog', title: 'Dataset Catalog', public: true, sort_order: 1, content: '<p>Get a list of all datasets.</p>
<h2>URL</h2>
<p>To call this method, use an HTTP GET request to the following URL:</p>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/v1/dataset_catalog</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently <strong>ka</strong> for Georgian or <strong>en</strong> for English)</li>
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
<td>All requests must include an access_token. You can obtain an access token easily, and for free, by going <a href="#">here</a>.</td>
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
  v.api_methods.create(permalink: 'dataset', title: 'Dataset Details', sort_order: 2, public: true, content: '<p>Get details about a dataset.</p>
<h2>URL</h2>
<p>To call this method, use an HTTP GET request to the following URL:</p>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/v1/dataset</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently <strong>ka</strong> for Georgian or <strong>en</strong> for English)</li>
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
<td>All requests must include an access_token. You can obtain an access token easily, and for free, by going <a href="#">here</a>.</td>
</tr>
<tr>
<td>dataset_id</td>
<td>The ID of the dataset.</td>
</tr>
</tbody>
</table>
<p></p>
<h2>Optional Parameters</h2>
<p>There are no optional parameters for this call.</p>
<h2>What You Get</h2>
<p>The return object is a JSON objectof dataset informationwith the following information:</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>id</td>
<td>Unique ID of the dataset</td>
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
<td>source_url</td>
<td>The URL to the source that gathered the data</td>
</tr>
<tr>
<td>description</td>
<td>A description of the dataset, may include htmlmarkup</td>
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
<tr>
<td>is_mappable</td>
<td>A boolean flag indicating if this dataset has at least one question that has been assigned to map shapes</td>
</tr>
<tr>
<td>languages</td>
<td>An array of the languages that are available in this dateset</td>
</tr>
<tr>
<td>default_language</td>
<td>Thelanguage that is used by default</td>
</tr>
<tr>
<td>methodology</td>
<td>Themethod in which the data was collected, may include htmlmarkup</td>
</tr>
</tbody>
</table>
<h2>Examples</h2>
<p>Here is an example of what can be returned after calling this method with the following url:</p>
<div class="url">http://dev-unicef.jumpstart.ge/en/api/v1/dataset?access_token=123456789&amp;dataset_id=1111111111</div>
<pre class="brush:js;auto-links:false;toolbar:false;tab-size:2" contenteditable="false">{
  {
    id: "1111111111",
    title: "This is a dataset!",
    source: "People",
    source_url: "http://somewhere.org",
    description: "This is an amazing dataset!",
    start_gathered_at: "2014-04-01",
    end_gathered_at: "2014-06-30",
    released_at: "2015-01-01",
    public_at: "2015-03-01",
    is_mappable: false,
    languages:[
      "en",
      "ka"
    ],
    default_language: "en",
    methodology: "This data was gathered from by asking people questions!"
  }
}</pre>
<p></p>')
  v.api_methods.create(permalink: 'dataset_codebook', title: 'Dataset Codebook', sort_order: 3, public: true, content: '<p>Get the codebook for a dataset.</p>
<h2>URL</h2>
<p>To call this method, use an HTTP GET request to the following URL:</p>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/v1/dataset_codebook</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently <strong>ka</strong> for Georgian or <strong>en</strong> for English)</li>
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
<td>All requests must include an access_token. You can obtain an access token easily, and for free, by going <a href="#">here</a>.</td>
</tr>
<tr>
<td>dataset_id</td>
<td>The ID of the dataset.</td>
</tr>
</tbody>
</table>
<p></p>
<h2>Optional Parameters</h2>
<p>There are no optional parameters for this call.</p>
<h2>What You Get</h2>
<p>The return object is a JSON array of the dataset questions and answers with the following information:</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>code</td>
<td>Code of the question. Youwill use this valueto run an analysis.</td>
</tr>
<tr>
<td>original_code</td>
<td>The original code from the datasource. The difference between the <strong>code</strong> and <strong>original_code</strong> is that the <strong>code</strong> is lower case and has \'.\' replaced with \'|\'.</td>
</tr>
<tr>
<td>text</td>
<td>The question text</td>
</tr>
<tr>
<td>is_mappable</td>
<td>A boolean flag indicating if this question has been assigned to map shapes</td>
</tr>
<tr>
<td>answers</td>
<td>
<p>An array of the possible answers with the following values:</p>
<ul>
<li><strong>value</strong> - the answer value</li>
<li><strong>text</strong> - the answer text</li>
<li><strong>can_exclude</strong> - boolean flag indicating if this answer can be excluded from analysis</li>
<li><strong>sort_order</strong> - order in which the answer should appear</li>
</ul>
</td>
</tr>
</tbody>
</table>
<h2>Examples</h2>
<p>Here is an example of what can be returned after calling this method with the following url:</p>
<div class="url">http://dev-unicef.jumpstart.ge/en/api/v1/dataset_codebook?access_token=123456789&amp;dataset_id=1111111111</div>
<pre class="brush:js;auto-links:false;toolbar:false;tab-size:2" contenteditable="false">{
  questions: [
    {
      code: "gender",
      original_code: "GENDER",
      text: "What is your gender?",
      is_mappable: false,
      answers:[
        {
          value: "1",
          text: "Male",
          can_exclude: false,
          sort_order: 1
        },
        {
          value: "2",
          text: "Female",
          can_exclude: false,
          sort_order: 2
        },
        {
          value: "3",
          text: "Refuse to Answer",
          can_exclude: true,
          sort_order: 3
        }
      ]
    },
    {
      code: "live",
      original_code: "LIVE",
      text: "Where do you live?",
      is_mappable: false,
      answers:[
        {
          value: "1",
          text: "Tbilisi",
          can_exclude: false,
          sort_order: 1
        },
        {
          value: "2",
          text: "London",
          can_exclude: false,
          sort_order: 2
        },
        {
          value: "3",
          text: "New York City",
          can_exclude: false,
          sort_order: 3
        }
      ]
    }
  ]
}</pre>
<p></p>')
  v.api_methods.create(permalink: 'dataset_analysis', title: 'Dataset Analysis', sort_order: 4, public: true, content: '<p>Analyze data in a dataset. The dataset explore pages in this website use this API method to get the results of the analysis.</p>
<p><strong>This documentation is not complete yet.</strong></p>
<h2>URL</h2>
<p>To call this method, use an HTTP GET request to the following URL:</p>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/v1/dataset_analysis</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently <strong>ka</strong> for Georgian or <strong>en</strong> for English)</li>
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
<td>All requests must include an access_token. You can obtain an access token easily, and for free, by going <a href="#">here</a>.</td>
</tr>
<tr>
<td>dataset_id</td>
<td>The ID of the dataset.</td>
</tr>
<tr>
<td>question_code</td>
<td>The code of a question in the dataset.</td>
</tr>
</tbody>
</table>
<p></p>
<h2>Optional Parameters</h2>
<p>There following parameters are optional for this call.</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>broken_down_by_code</td>
<td>Code of question to compare against <strong>question_code</strong> (i.e., a crosstab analysis)</td>
</tr>
<tr>
<td>filter_by_code</td>
<td>Code of question to filter the analysis by</td>
</tr>
<tr>
<td>can_exclude</td>
<td>Boolean flag indicating if answers that can be excluded should be excluded (default value is false)</td>
</tr>
<tr>
<td>with_title</td>
<td>Boolean flag indicating if titles summarizing the data should be included (default value is false)</td>
</tr>
<tr>
<td>with_chart_data</td>
<td>Boolean flag indicating if the results should include data formatted to be put into a Highcharts chart (default value is false)</td>
</tr>
<tr>
<td>with_map_data</td>
<td>Boolean flag indicating if the results should include data formatted to be put into a Highmaps map (default value is false)</td>
</tr>
</tbody>
</table>
<h2>What You Get</h2>
<p>The return object is a JSON object of the dataset analysis with the following information:</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>dataset</td>
<td>
<p>An object with the following values:</p>
<ul>
<li><strong>id</strong> - the ID of the dataset that was analyzed</li>
<li><strong>title</strong> - the title of the dataset that was analyzed</li>
</ul>
</td>
</tr>
<tr>
<td>question</td>
<td>
<p>An object with the following values:</p>
<ul>
<li><strong>code</strong> - the code of the question that was analyzed</li>
<li><strong>original_code</strong> - the original_code of the question that was analyzed</li>
<li><strong>text</strong> - the text of the question that was analyzed</li>
<li><strong>is_mappable</strong> - a boolean flag indicating if this question has been assigned to map shapes</li>
<li><strong>answers</strong> - an array of the following information:
<ul>
<li><strong>value</strong> - the answer value</li>
<li><strong>text</strong> - the answer text</li>
<li><strong>can_exclude</strong> - boolean flag indicating if this answer can be excluded from analysis</li>
<li><strong>sort_order</strong> - order in which the answer should appear</li>
</ul>
</li>
</ul>
</td>
</tr>
<tr>
<td>broken_down_by</td>
<td>
<p>Only if <strong>broken_down_by_code</strong> was provided. An object with the following values:</p>
<ul>
<li><strong>code</strong> - the code of the question that was analyzed</li>
<li><strong>original_code</strong> - the original_code of the question that was analyzed</li>
<li><strong>text</strong> - the text of the question that was analyzed</li>
<li><strong>is_mappable</strong> - a boolean flag indicating if this question has been assigned to map shapes</li>
<li><strong>answers</strong> - an array of the following information:
<ul>
<li><strong>value</strong> - the answer value</li>
<li><strong>text</strong> - the answer text</li>
<li><strong>can_exclude</strong> - boolean flag indicating if this answer can be excluded from analysis</li>
<li><strong>sort_order</strong> - order in which the answer should appear</li>
</ul>
</li>
</ul>
</td>
</tr>
<tr>
<td>filtered_by</td>
<td>
<p>Only if <strong>filtered_by_code</strong> was provided. An object with the following values:</p>
<ul>
<li><strong>code</strong> - the code of the question that was analyzed</li>
<li><strong>original_code</strong> - the original_code of the question that was analyzed</li>
<li><strong>text</strong> - the text of the question that was analyzed</li>
<li><strong>is_mappable</strong> - a boolean flag indicating if this question has been assigned to map shapes</li>
<li><strong>answers</strong> - an array of the following information:
<ul>
<li><strong>value</strong> - the answer value</li>
<li><strong>text</strong> - the answer text</li>
<li><strong>can_exclude</strong> - boolean flag indicating if this answer can be excluded from analysis</li>
<li><strong>sort_order</strong> - order in which the answer should appear</li>
</ul>
</li>
</ul>
</td>
</tr>
<tr>
<td>analysis_type</td>
<td>
<p>Indicates what type of analysis was performed:</p>
<ul>
<li><strong>single</strong> - a summary of the <strong>question_code</strong> was created</li>
<li><strong>comparative</strong> - a summary of <strong>question_code</strong> compared against <strong>broken_down_by_code</strong> was created</li>
</ul>
</td>
</tr>
<tr>
<td>results</td>
<td>
<p>An object containing the results of the analysis with the following information:</p>
</td>
</tr>
<tr>
<td>chart</td>
<td>
<p>Only if <strong>with_chart_data</strong> was true. An object with the following values:</p>
</td>
</tr>
<tr>
<td>map</td>
<td>
<p>Only if <strong>with_map_data</strong> was true. An object with the following values:</p>
</td>
</tr>
</tbody>
</table>
<h2>Examples</h2>
<p>Here is an example of analyzing the results of Gender with the following url:</p>
<div class="url">http://dev-unicef.jumpstart.ge/en/api/v1/dataset_analysis?access_token=123456789&amp;dataset_id=1111111111&amp;question_code=gender</div>
<pre class="brush:js;auto-links:false;toolbar:false;tab-size:2" contenteditable="false">{
  dataset: 
  {
    id: "1111111111",
    title: "This is a dataset!"
  },
  question: 
  {
    code: "gender",
    original_code: "GENDER",
    text: "What is your gender?",
    is_mappable: false,
    answers:[
      {
        value: "1",
        text: "Male",
        can_exclude: false,
        sort_order: 1
      },
      {
        value: "2",
        text: "Female",
        can_exclude: false,
        sort_order: 2
      },
      {
        value: "3",
        text: "Refuse to Answer",
        can_exclude: true,
        sort_order: 3
      }
    ]
  },
  analysis_type: "single",
  results:
  {

  }
}</pre>
<p></p>')

  v.api_methods.create(permalink: 'time_series_catalog', title: 'Time Series Catalog', sort_order: 5, public: true, content: '<p>Get a list of all time series.</p>
<h2>URL</h2>
<p>To call this method, use an HTTP GET request to the following URL:</p>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/v1/time_series_catalog</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently <strong>ka</strong> for Georgian or <strong>en</strong> for English)</li>
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
<td>All requests must include an access_token. You can obtain an access token easily, and for free, by going <a href="#">here</a>.</td>
</tr>
</tbody>
</table>
<p></p>
<h2>Optional Parameters</h2>
<p>There are no optional parameters for this call.</p>
<h2>What You Get</h2>
<p>The return object is a JSON array of all time series in the site with the following information:</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>id</td>
<td>Unique ID of the time series that you will need to get further information or run an analysis</td>
</tr>
<tr>
<td>title</td>
<td>The title of the time series</td>
</tr>
<tr>
<td>dates_included</td>
<td>An array of the dates that are included in the time series.The dates may represent a year, month/year, etc - there is no specific format for these values.</td>
</tr>
<tr>
<td>public_at</td>
<td>Date the data was made public on this site, format: yyyy-mm-dd (e.g., 2015-01-31)</td>
</tr>
</tbody>
</table>
<h2>Examples</h2>
<p>Here is an example of what can be returned after calling this method with the following url:</p>
<div class="url">http://dev-unicef.jumpstart.ge/en/api/v1/time_series_catalog?access_token=123456789</div>
<pre class="brush:js;auto-links:false;toolbar:false;tab-size:2" contenteditable="false">{
  time_series: [
    {
      id: "1111111111",
      title: "This is a time series!",
      dates_included: [
        "2009",
        "2011",
        "2013"
      ],
      public_at: "2015-03-01"
    },
    {
      id: "2222222222",
      title: "Wow, another time series!",
      dates_included: [
        "April 2010",
        "May 2013"
      ],
      public_at: "2015-04-15"
    }
  ]
}</pre>
<p></p>')
  v.api_methods.create(permalink: 'time_series', title: 'Time Series Details', sort_order: 6, public: true, content: '<p>Get details about a time series.</p>
<h2>URL</h2>
<p>To call this method, use an HTTP GET request to the following URL:</p>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/v1/time_series</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently <strong>ka</strong> for Georgian or <strong>en</strong> for English)</li>
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
<td>All requests must include an access_token. You can obtain an access token easily, and for free, by going <a href="#">here</a>.</td>
</tr>
<tr>
<td>time_series_id</td>
<td>The ID of the time series.</td>
</tr>
</tbody>
</table>
<p></p>
<h2>Optional Parameters</h2>
<p>There are no optional parameters for this call.</p>
<h2>What You Get</h2>
<p>The return object is a JSON object of time series information with the following information:</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>id</td>
<td>Unique ID of the time series</td>
</tr>
<tr>
<td>title</td>
<td>The title of the time series</td>
</tr>
<tr>
<td>dates_included</td>
<td>An array of the dates that are included in the time series.The dates may represent a year, month/year, etc - there is no specific format for these values.</td>
</tr>
<tr>
<td>description</td>
<td>A description of the time series, may include htmlmarkup</td>
</tr>
<tr>
<td>public_at</td>
<td>Date the data was made public on this site, format: yyyy-mm-dd (e.g., 2015-01-31)</td>
</tr>
<tr>
<td>languages</td>
<td>An array of the languages that are available in this dateset</td>
</tr>
<tr>
<td>default_language</td>
<td>Thelanguage that is used by default</td>
</tr>
</tbody>
</table>
<h2>Examples</h2>
<p>Here is an example of what can be returned after calling this method with the following url:</p>
<div class="url">http://dev-unicef.jumpstart.ge/en/api/v1/time_series?access_token=123456789&amp;time_series_id=1111111111</div>
<pre class="brush:js;auto-links:false;toolbar:false;tab-size:2" contenteditable="false">{
  {
    id: "1111111111",
    title: "This is a time series!",
    dates_included: [
      "2009",
      "2011",
      "2013"
    ],
    description: "This is an amazing time series!"
    public_at: "2015-03-01"
    languages:[
      "en",
      "ka"
    ],
    default_language: "en"
  }
}</pre>
<p></p>')
  v.api_methods.create(permalink: 'time_series_codebook', title: 'Time Series Codebook', sort_order: 7, public: true, content: '<p>Get the codebook for a time series.</p>
<h2>URL</h2>
<p>To call this method, use an HTTP GET request to the following URL:</p>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/v1/time_series_codebook</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently <strong>ka</strong> for Georgian or <strong>en</strong> for English)</li>
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
<td>All requests must include an access_token. You can obtain an access token easily, and for free, by going <a href="#">here</a>.</td>
</tr>
<tr>
<td>time_series_id</td>
<td>The ID of the time series.</td>
</tr>
</tbody>
</table>
<p></p>
<h2>Optional Parameters</h2>
<p>There are no optional parameters for this call.</p>
<h2>What You Get</h2>
<p>The return object is a JSON array of the time series questions and answers with the following information:</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>code</td>
<td>Code of the question. Youwill use this valueto run an analysis.</td>
</tr>
<tr>
<td>original_code</td>
<td>The original code from the datasource. The difference between the <strong>code</strong> and <strong>original_code</strong> is that the <strong>code</strong> is lower case and has \'.\' replaced with \'|\'.</td>
</tr>
<tr>
<td>text</td>
<td>The question text</td>
</tr>
<tr>
<td>answers</td>
<td>
<p>An array of the possible answers with the following values:</p>
<ul>
<li><strong>value</strong> - the answer value</li>
<li><strong>text</strong> - the answer text</li>
<li><strong>can_exclude</strong> - boolean flag indicating if this answer can be excluded from analysis</li>
<li><strong>sort_order</strong> - order in which the answer should appear</li>
</ul>
</td>
</tr>
</tbody>
</table>
<h2>Examples</h2>
<p>Here is an example of what can be returned after calling this method with the following url:</p>
<div class="url">http://dev-unicef.jumpstart.ge/en/api/v1/time_series_codebook?access_token=123456789&amp;time_series_id=1111111111</div>
<pre class="brush:js;auto-links:false;toolbar:false;tab-size:2" contenteditable="false">{
  questions: [
    {
      code: "gender",
      original_code: "GENDER",
      text: "What is your gender?",
      is_mappable: false,
      answers:[
        {
          value: "1",
          text: "Male",
          can_exclude: false,
          sort_order: 1
        },
        {
          value: "2",
          text: "Female",
          can_exclude: false,
          sort_order: 2
        },
        {
          value: "3",
          text: "Refuse to Answer",
          can_exclude: true,
          sort_order: 3
        }
      ]
    },
    {
      code: "live",
      original_code: "LIVE",
      text: "Where do you live?",
      is_mappable: false,
      answers:[
        {
          value: "1",
          text: "Tbilisi",
          can_exclude: false,
          sort_order: 1
        },
        {
          value: "2",
          text: "London",
          can_exclude: false,
          sort_order: 2
        },
        {
          value: "3",
          text: "New York City",
          can_exclude: false,
          sort_order: 3
        }
      ]
    }
  ]
}</pre>
<p></p>')
  v.api_methods.create(permalink: 'time_series_analysis', title: 'Time Series Analysis', sort_order: 8, public: true, content: '<p>Analyze data in a time series. The time series explore pages in this website use this API method to get the results of the analysis.</p>
<p><strong>This documentation is not complete yet.</strong></p>
<h2>URL</h2>
<p>To call this method, use an HTTP GET request to the following URL:</p>
<div class="url">http://dev-unicef.jumpstart.ge/[locale]/api/v1/time_series_analysis</div>
<p>where:</p>
<ul class="list-unstyled">
<li>[locale] = the locale of the language you want the data to be returned in (currently <strong>ka</strong> for Georgian or <strong>en</strong> for English)</li>
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
<td>All requests must include an access_token. You can obtain an access token easily, and for free, by going <a href="#">here</a>.</td>
</tr>
<tr>
<td>time_series_id</td>
<td>The ID of the time series.</td>
</tr>
<tr>
<td>question_code</td>
<td>The code of a question in the time series.</td>
</tr>
</tbody>
</table>
<p></p>
<h2>Optional Parameters</h2>
<p>There following parameters are optional for this call.</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>filter_by_code</td>
<td>Code of question to filter the analysis by</td>
</tr>
<tr>
<td>can_exclude</td>
<td>Boolean flag indicating if answers that can be excluded should be excluded (default value is false)</td>
</tr>
<tr>
<td>with_title</td>
<td>Boolean flag indicating if titles summarizing the data should be included (default value is false)</td>
</tr>
<tr>
<td>with_chart_data</td>
<td>Boolean flag indicating if the results should include data formatted to be put into a Highcharts chart (default value is false)</td>
</tr>
</tbody>
</table>
<h2>What You Get</h2>
<p>The return object is a JSON object of the time series analysis with the following information:</p>
<table class="table table-bordered table-hover table-nonfluid">
<thead>
<tr><th>Parameter</th><th>Description</th></tr>
</thead>
<tbody>
<tr>
<td>time_series</td>
<td>
<p>An object with the following values:</p>
<ul>
<li><strong>id</strong> - the ID of the time series that was analyzed</li>
<li><strong>title</strong> - the title of the time series that was analyzed</li>
</ul>
</td>
</tr>
<tr>
<td>datasets</td>
<td>
<p>An array of the datasets that are in the time series with the following values:</p>
<ul>
<li><strong>id</strong> - the ID of the dataset</li>
<li><strong>title</strong> - the title of the dataset</li>
<li><strong>label</strong> - the label of the dataset in this time series</li>
</ul>
</td>
</tr>
<tr>
<td>question</td>
<td>
<p>An object with the following values:</p>
<ul>
<li><strong>code</strong> - the code of the question that was analyzed</li>
<li><strong>original_code</strong> - the original_code of the question that was analyzed</li>
<li><strong>text</strong> - the text of the question that was analyzed</li>
<li><strong>is_mappable</strong> - a boolean flag indicating if this question has been assigned to map shapes</li>
<li><strong>answers</strong> - an array of the following information:
<ul>
<li><strong>value</strong> - the answer value</li>
<li><strong>text</strong> - the answer text</li>
<li><strong>can_exclude</strong> - boolean flag indicating if this answer can be excluded from analysis</li>
<li><strong>sort_order</strong> - order in which the answer should appear</li>
</ul>
</li>
</ul>
</td>
</tr>
<tr>
<td>filtered_by</td>
<td>
<p>Only if <strong>filtered_by_code</strong> was provided. An object with the following values:</p>
<ul>
<li><strong>code</strong> - the code of the question that was analyzed</li>
<li><strong>original_code</strong> - the original_code of the question that was analyzed</li>
<li><strong>text</strong> - the text of the question that was analyzed</li>
<li><strong>is_mappable</strong> - a boolean flag indicating if this question has been assigned to map shapes</li>
<li><strong>answers</strong> - an array of the following information:
<ul>
<li><strong>value</strong> - the answer value</li>
<li><strong>text</strong> - the answer text</li>
<li><strong>can_exclude</strong> - boolean flag indicating if this answer can be excluded from analysis</li>
<li><strong>sort_order</strong> - order in which the answer should appear</li>
</ul>
</li>
</ul>
</td>
</tr>
<tr>
<td>analysis_type</td>
<td>
<p>Indicates what type of analysis was performed:</p>
<ul>
<li><strong>time_series</strong> - a time series analysis of <strong>question_code</strong> was created</li>
</ul>
</td>
</tr>
<tr>
<td>results</td>
<td>
<p>An object containing the results of the analysis with the following information:</p>
</td>
</tr>
<tr>
<td>chart</td>
<td>
<p>Only if <strong>with_chart_data</strong> was true. An object with the following values:</p>
</td>
</tr>
</tbody>
</table>
<h2>Examples</h2>
<p>Here is an example of analyzing the results of Gender with the following url:</p>
<div class="url">http://dev-unicef.jumpstart.ge/en/api/v1/time_series_analysis?access_token=123456789&amp;time_series_id=1111111111&amp;question_code=gender</div>
<pre class="brush:js;auto-links:false;toolbar:false;tab-size:2" contenteditable="false">{
  time_series: 
  {
    id: "1111111111",
    title: "This is a time series!"
  },
  datasets:[
    {
      id: "11112009",
      title: "This is a dataset from 2009"
      label: "2009"
    },
    {
      id: "11112011",
      title: "This is a dataset from 2011"
      label: "2011"
    },
    {
      id: "11112013",
      title: "This is a dataset from 2013"
      label: "2013"
    }
  ],
  question: 
  {
    code: "gender",
    original_code: "GENDER",
    text: "What is your gender?",
    is_mappable: false,
    answers:[
      {
        value: "1",
        text: "Male",
        can_exclude: false,
        sort_order: 1
      },
      {
        value: "2",
        text: "Female",
        can_exclude: false,
        sort_order: 2
      },
      {
        value: "3",
        text: "Refuse to Answer",
        can_exclude: true,
        sort_order: 3
      }
    ]
  },
  analysis_type: "time_series",
  results:
  {

  }
}</pre>
<p></p>')
end


#####################
## Create Categories
#####################
puts 'Creating categories'
Category.create(permalink: 'child_protection',  name_translations:{'en' => 'Child Protection', 'ka' => 'ბავშვთა დაცვა'},                            sort_order: 1) if Category.by_permalink('child_protection').nil?
Category.create(permalink: 'violence',          name_translations:{'en' => 'Violence against children', 'ka' => 'ბავშვთა მიმართ ძალადობა'},         sort_order: 2) if Category.by_permalink('violence').nil?
Category.create(permalink: 'disability',        name_translations:{'en' => 'Disability', 'ka' => 'შეზღუდვა'},                                       sort_order: 3) if Category.by_permalink('disability').nil?
Category.create(permalink: 'health',            name_translations:{'en' => 'Maternal and Child Health', 'ka' => 'დედისა და ბავშვის ჯანმრთელობა'},   sort_order: 4) if Category.by_permalink('health').nil?
Category.create(permalink: 'education',         name_translations:{'en' => 'Education', 'ka' => 'განათლება'},                                       sort_order: 5) if Category.by_permalink('education').nil?
Category.create(permalink: 'social_production', name_translations:{'en' => 'Social Protection', 'ka' => 'სოციალური დაცვა'},                         sort_order: 6) if Category.by_permalink('social_production').nil?
Category.create(permalink: 'wash',              name_translations:{'en' => 'Water, Sanitation and Hygiene', 'ka' => 'წყალი, სანიტარია და ჰიგიენა'}, sort_order: 7) if Category.by_permalink('wash').nil?
Category.create(permalink: 'youth',             name_translations:{'en' => 'Youth', 'ka' => 'ახალგაზრდობა'},                                        sort_order: 8) if Category.by_permalink('youth').nil?
