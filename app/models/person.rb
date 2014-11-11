class Person
  include Mongoid::Document
  field :age, type: Integer
  field :name
  field :sdate
  embeds_many :questions
  accepts_nested_attributes_for :questions

  has_many :data_items do
    # these are functions that will query the data_items documents

    # get the data for the provided code
    def with_code(code)
      where(:code => code).first
    end

    def code_data(code)
      x = where(:code => code).first
      if x.present?
        return x.data
      else
        return nil
      end
    end
  end
  accepts_nested_attributes_for :data_items

  def test(code)
    x = self.data_items.select{|x| x.code == code}.first
    if x.present?
      return x.data
    else
      return nil
    end
  end

  def data_item_stats(code)
    start = Time.now
    # get the counts of each row value
    map = "
      function(){
        if (!this.data_items){
          return;
        }

        for (var i = 0; i < this.data_items.length; i++) {
          if (this.data_items[i] != null && this.data_items[i].code == '#{code}'){
            for (var j = 0; j < this.data_items[i].data.length; j++) {
              emit(this.data_items[i].data[j].toString(), 1 ); 
            }
          }
        }

      }
    "

      puts map
      puts "---"

    # countRowValue will be an array of ones from the map function above
    # for the total number of times that the row value appears in data
    # count the length of the array to see how many times it appears
    reduce = "
      function(rowValue, countRowValue) {
        return countRowValue.length;
      };
    "

      puts reduce
      puts "---"

    x = Person.where(:id => self.id).map_reduce(map, reduce).out(inline: true).to_a

    puts "== total time = #{(Time.now - start)*1000} ms"
    return x
  end


  def data_item_stats2(code)
    start = Time.now
    # get the data for this code
    data = self.data_items.code_data(code)

    # get the counts of each row value
    map = "
      function(){
        var data = #{data};
        if (!data){
          return;
        }

        for (var i = 0; i < data.length; i++) {
          if (data[i] != null){
            emit(data[i].toString(), 1 ); 
          }
        }

      }
    "

      puts map
      puts "---"

    # countRowValue will be an array of ones from the map function above
    # for the total number of times that the row value appears in data
    # count the length of the array to see how many times it appears
    reduce = "
      function(rowValue, countRowValue) {
        return countRowValue.length;
      };
    "

      puts reduce
      puts "---"

    x = Person.where(:id => self.id).map_reduce(map, reduce).out(inline: true).to_a

    puts "== total time = #{(Time.now - start)*1000} ms"
    return x
  end

  def data_item_stats3(code)
    start = Time.now
    # get the data for this code
    data = self.data_items.code_data(code)

    # have to do special sort in case nil values exist
    x =  data.sort_by{|x| [x ? 1 : 0, x]}
            .each_with_object(Hash.new(0)) { |item,counts| counts[item.to_s] += 1 }

    puts "== total time = #{(Time.now - start)*1000} ms"
    return x
  end


  def data_items_stats(code1, code2)
    start = Time.now
    # get the data for this code
    data1 = self.data_items.code_data(code1)
    data2 = self.data_items.code_data(code2)

    row_items = data1.uniq.sort_by{|x| [x ? 1 : 0, x]}
    col_items = data2.uniq.sort_by{|x| [x ? 1 : 0, x]}

    puts "uniq row items = #{row_items}"
    puts "uniq col items = #{col_items}"

    data = data1.zip(data2)

    counts = {}

    row_items.each do |row_item|
      if row_item.present?
        # have to do special sort in case nil values exist
        counts[row_item.to_s] = data.select{|x| x[0] == row_item && x[1].present?}.map{|x| x[1]}
                                  .sort_by{|x| [x ? 1 : 0, x]}
                                  .each_with_object(Hash.new(0)) { |item,counts| counts[item.to_s] += 1 }
      end
    end


    puts "== total time = #{(Time.now - start)*1000} ms"
    return counts
  end

######################################
###############################33


  def self.generate_stats
    map = "
      function() {
        emit(this.sdate, { age: this.age, count: 1 }); 
      }  
    "

    reduce = "
      function(key, values) {   
        var result = { avg_of_ages: 0, count: 0 };
        var sum = 0;
        var total = values.length;
        values.forEach(function(value) {
          sum += value.age;    
          result.count += value.count; 
        });
        result.avg_of_ages = sum/total;
        return result;
      }
    "

    map_reduce(map, reduce).out(inline: true)
  end


  def self.generate_stats2(row, col)
    map = "
      function() {
        emit(this.#{row}, { #{col}: this.#{col}, count: 1 }); 
      }  
    "

puts map
puts "---"
    reduce = "
      function(key, values) {   
        var result = { avg: 0, count: 0 };
        var sum = 0;
        var total = values.length;
        values.forEach(function(value) {
          sum += value.#{col};    
          result.count += value.count; 
        });
        result.avg = sum/total;
        return result;
      }
    "
puts reduce
puts "---"
    map_reduce(map, reduce).out(inline: true)
  end


  # trying to do crosstab in one map/reduce query
  # - not working
  def self.generate_stats3(row, col)
    # get uniq values of col
    cols = distinct(col)  
    map = "
      function() {
        emit(this.#{row}, { "
    map << cols.map{|c| "'#{c}': 1"}.join(', ')
    map << "}); 
      }  
    "

puts map
puts "---"
    reduce = "
      function(key, values) {   
        var result = { "
    reduce << cols.map{|c| "'#{c}': 0"}.join(', ')
    reduce << " };
        values.forEach(function(value) {"
    reduce << cols.map{|c| "if (value['#{c}'] == 1){result['#{c}'] += 1;}"}.join(' ')
    reduce << ";
        });
        return result;
      }
    "
puts reduce
puts "---"
    map_reduce(map, reduce).out(inline: true)
  end


  # do map/reduce query for each possible col value and then put together into one result
  def self.generate_stats4(row, col)
    # get uniq values of col
    cols = distinct(col).sort  
    rows = distinct(row).sort

    results = []
    data = {}

    cols.each do |c|
      puts "--------------------"
      puts "c = #{c}"
      map = "
        function() {
          emit(this.#{row}, { #{col}: this.#{col}, count: 1 }); 
        }  
      "

      puts map
      puts "---"


      reduce = "
        function(key, values) {   
          var result = { #{col}: '#{c}', count: 0 };
          values.forEach(function(value) {
            result.count += 1; 
          });
          return result;
        }
      "
      puts reduce
      puts "---"

      results << where(col => c).map_reduce(map, reduce).out(inline: true).to_a

    end

    # flatten the results
    puts "++ results length was = #{results.length}"
    results.flatten!
    puts "++ results length = #{results.length}"

puts results

    # now put it all together
    data[:row_header] = row.titlecase
    data[:row_answers] = rows
    data[:column_header] = col.titlecase
    data[:column_answers] = cols

    data[:counts] = []
    rows.each do |r|
      data_row = []
      cols.each do |c|
        data_match = results.select{|x| x['_id'].to_s == r.to_s && x['value'][col].to_s == c.to_s}
        if data_match.present?
          data_row << data_match.map{|x| x['value']['count']}.inject(:+)
        else
          data_row << 0
        end
      end
      data[:counts] << data_row
    end

    return data
  end


  # the one that works!
  def self.generate_stats5(row, col)
    # get uniq values of col
    cols = distinct(col).sort  
    rows = distinct(row).sort

    results = []
    data = {}

    cols.each do |c|
      puts "--------------------"
      puts "c = #{c}"

      # need to make sure the row value and c value are recorded as strings
      # for if it is an int, the javascript function turns it into a decimal 
      # (2 -> 2.0) and then comparisons do not work!
      map = "
        function() {
          emit(this.#{row}.toString(), { #{col}: '#{c}', count: 1 }); 
        }  
      "

      puts map
      puts "---"


      reduce = "
        function(key, values) {   
          var result = { #{col}: '#{c}', count: 0 };
          values.forEach(function(value) {
            result.count += 1; 
          });
          return result;
        }
      "


      puts reduce
      puts "---"

      results << where(col => c).map_reduce(map, reduce).out(inline: true).to_a

    end

    # flatten the results
    puts "++ results length was = #{results.length}"
    results.flatten!
    puts "++ results length = #{results.length}"

puts results

    # now put it all together
    data[:row_header] = row.titlecase
    data[:row_answers] = rows
    data[:column_header] = col.titlecase
    data[:column_answers] = cols

    data[:counts] = []
    rows.each do |r|
      data_row = []
      cols.each do |c|
        data_match = results.select{|x| x['_id'].to_s == r.to_s && x['value'][col].to_s == c.to_s}
        if data_match.present?
          data_row << data_match.map{|x| x['value']['count']}.inject(:+)
        else
          data_row << 0
        end
      end
      data[:counts] << data_row
    end

    return data
  end
end