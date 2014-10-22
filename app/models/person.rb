class Person
  include Mongoid::Document
  field :age, type: Integer
  field :name
  field :sdate



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