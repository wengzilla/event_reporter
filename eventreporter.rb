$LOAD_PATH.unshift('./')
require "csv"
require "sunlight"
require "eventmanager"
require "yaml"
require "active_support"
require "ruby-debug"

class EventReporter
  attr_accessor :manager, :queue_res, :help_dict
  PRINT_HEADERS = Hash[ :last_name => "LAST NAME", :first_name => "FIRST NAME", 
    :email_address => "E-MAIL", :zipcode => "ZIPCODE", :city => "CITY", 
    :state => "STATE", :street => "ADDRESS" ]
  OUTPUT_TYPES = [ "json", "txt", "xml", "csv"]
  PRINT_CONTINUES = [ "\r", "\s" ]

  def initialize
    puts "EventReporter Initialized."
    loadhelp()
    load()
    self.queue_res = []
  end

  def load(command=["event_attendees.csv"])
    filename = command[0]
    puts "Loading #{filename}"
    self.manager = EventManager.new(filename)
  end

  def help(command)
    if command.any?
      puts help_dict.keys.join(', ')
    elsif help_dict.keys.include? command.join(' ')
      puts help_dict[command.join(' ')]
    else 
      puts "#{command.join(' ')} not found"
    end
  end

  def queue(command)
    return queue_count if command[0] == "count" && command.length == 1
    return queue_clear if command[0] == "clear" && command.length == 1
    return queue_print if command[0] == "print" && command.length == 1
    if command[0] == "print" && command[1] == "by"
      return queue_print_by(command[2..-1])
    elsif command[0] == "save" && command[1] == "to" && command.length == 3
      return queue_save_to(command[2])
    else
      puts "queue #{command.join(' ')} not found."
    end
  end

  def queue_count
    puts "Queue has #{queue_res.length} entries"
  end

  def queue_clear
    self.queue_res = Array.new
  end

  def queue_print
      queue_output
  end

  def queue_print_by(field)
    puts field
    puts field.class
    sort_field = field.join('_')
    puts sort_field
    sort_field = sort_field.to_sym
    puts sort_field
    if field_valid?(sort_field)
      self.queue_res = queue_res.sort_by{ |a| a.send(sort_field) || "" }
      queue_output
    else
      puts "field #{field} not found."
    end
  end

  def queue_save_to(filename="results.xml")
    
    type = filename.split('.').last
    if OUTPUT_TYPES.include? type
    else
      puts "filename needs a valid extension: #{OUTPUT_TYPES.join(' ')}"
    end
    queue_res.each_with_index do |attendee, i|
      puts attendee
    end
    # output = File.new(filename, "w")
    #   queue_res.each_with_index do |attendee, i|
    #     output << attendee.to_xml
    #   end
    # output.close

    # if( type == "csv" )
    # output = CSV.open(filename, "w")
    # queue_res.each_with_index do |attendee, i|
    #   output << PRINT_HEADERS.values if i == 0
    #   output << PRINT_HEADERS.keys.collect { |k| "#{ attendee.send(k) }" }
    # end
  end

  def search(command) #takes a split array [field, criteria...]
    field = command[0].strip
    criteria = command[1..-1].join(' ').strip
    search_res = Array.new

    if field_valid?(field.to_sym)
      manager.attendees.each do |a|
        search_res << a if a.send(field.to_sym).to_s.downcase == criteria.downcase
      end  
      # debugger
      search_res
    else puts "Specified fields is invalid"
    end
  end

  def find(command)
    split_index = command.find_index{ |a| a =~ (/and|or/) }
    if split_index.nil? then self.queue_res = search(command)
      # debugger
    else
      command_one, command_two = command_split(command,split_index)
      case command[split_index]
        when "and" then self.queue_res = find(command_one) & find(command_two)
        when "or"  then self.queue_res = find(command_one) | find(command_two)
        else raise "Error in find method case statement."
      end
    end
  end

  def queue_find(command)

  end

  def command_split(command, split_index)
    #split an array on an index.
    #e.g. command_split( [1, 2, 3], 1 ) => [[1],[3]]
    [ command.slice(0..split_index - 1), command.slice(split_index + 1..-1) ]
  end

  def add(command)
    queue_temp = queue_res
    execute_command(command)
    self.queue_res |= queue_temp
  end

  def subtract(command)
    queue_temp = queue_res
    execute_command(command)
    self.queue_res = queue_temp - self.queue_res
  end

  def execute_command(command)
    if public_methods(false).grep(/^#{command[0]}$/).any?
      self.send(command[0].to_sym,command[1..-1]) 
    else
      puts "#{command.join(' ')} not found."
    end
  end

  private

  def loadhelp(filename='help.yaml')
    self.help_dict = YAML.load_file(filename)
  end

  def queue_output
    lengths = get_lengths()
    
    queue_res.each_with_index do |attendee, i|
      print_headers(lengths) if i == 0
      PRINT_HEADERS.keys.each do |field|
        value = attendee.send(field)
        printf "#{ value.ljust(lengths[field]) }\t" unless value.nil?
      end
      printf "\n"
      print_wait if i > 0 && i % 10 == 0
    end
  end

  def print_wait
    response = ""
    until PRINT_CONTINUES.include? response
      begin
        system("stty raw -echo")
        response = STDIN.getc
      ensure
        system("stty -raw echo")
      end
    end
  end

  def print_headers(lengths)
    PRINT_HEADERS.each do |field, value| 
      printf "#{ value.ljust( lengths[field] ) }\t"
    end
    printf "\n"
  end

  def get_lengths
    lengths = {}
    PRINT_HEADERS.keys.each do |field| 
      lengths[field] = format_length(field)
    end
    lengths
  end

  def format_length(field)
    if queue_res && field_valid?(field)
      lengths = queue_res.collect do |attendee|
        attendee.send(field).length unless attendee.send(field).nil?
      end
      lengths << PRINT_HEADERS[field].length
      lengths.compact.max
    end
  end

  def field_valid?(field)
    if manager.headers.include?(field)
      field
    else puts "Sorry, attribute is unrecognizable"
      puts "These are the following attributes: #{manager.headers.join(' ')}"
    end
  end
end

reporter = EventReporter.new

puts "Event Reporter: Active"
inputs = Array.new
while inputs.first != "quit"
  printf "enter command > "
  inputs = gets.strip.downcase.split(" ")
  if inputs[0] != "quit"
    reporter.execute_command(inputs)
  else
    #do_nothing
  end
end

# reporter.find(["zipcode", "00000"])
# reporter.queue_save_to
# reporter.queue_print_by(["last", "name"])
#manager.state_stats