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

end