require "json"
require "active_support/all"

class Output
  attr_accessor :headers

  def initialize(print_headers)
    self.headers = print_headers
  end

  def output_xml(filename, list)
    f = File.open(filename, "w")
    list.each{ |row| f << row.marshal_dump.slice(*headers.keys).to_xml }
    f.close
  end

  def output_json(filename, list) #expects list to be an array of hashes
    f = File.open(filename, "w")
    list.each { |row, i| f << row.marshal_dump.slice(*headers.keys).to_json }
    f.close
  end

  def output_txt(filename, list)
    CSV.open(filename, "w", {:col_sep => "\t"} ) do |f|
      f << headers.keys
      list.each_with_index do |row, i|  
        f << headers.keys.collect { |k| "#{ row.send(k) }" }
      end
    end
  end

  def output_csv(filename, list)
    CSV.open(filename, "w", {:col_sep => ","} ) do |f|
      f << headers.keys
      list.each_with_index do |row, i|
        f << headers.keys.collect { |k| "#{ row.send(k) }" }
      end
    end
  end
end