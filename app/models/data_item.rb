class DataItem
  include Mongoid::Document

  belongs_to :person
  belongs_to :dataset
  field :code, type: String
  field :data, type: Array

  #############################

  # indexes
  index ({ :code => 1})

  #############################

=begin
  def data_item_stats
    # get the counts of each row value
    map = "
      function(){
        if (!this.data){
          return;
        }

        for (var i = 0; i < this.data.length; i++) {
          if (this.data[i] != null){
            emit(this.data[i].toString(), 1 ); 
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

    x = DataItem.where(:id => self.id).map_reduce(map, reduce).out(inline: true).to_a

    return x
  end
=end

end