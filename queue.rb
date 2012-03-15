class Queue
  attr_accessor :queue_res, :headers
  PRINT_HEADERS = Hash[ :last_name => "LAST NAME", :first_name => "FIRST NAME", 
    :email_address => "E-MAIL", :zipcode => "ZIPCODE", :city => "CITY", 
    :state => "STATE", :street => "ADDRESS", :phone_number => "PHONE" ]
  OUTPUT_TYPES = [ "json", "txt", "xml", "csv"]
  PRINT_CONTINUES = [ "\r", "\s" ]

  def initialize
    queue_clear
  end

  def queue_do(command)
    return queue_count if command[0] == "count" && command.length == 1
    return queue_clear if command[0] == "clear" && command.length == 1
    return queue_print if command[0] == "print" && command.length == 1
    return queue_find(command[1..-1]) if command[0] == "find"
    if command[0] == "print" && command[1] == "by"
      return queue_print_by(command[2..-1])
    elsif command[0] == "save" && command[1] == "to" && command.length == 3
      return queue_save_to(command[2])
    else puts "queue #{command.join(' ')} not found."
    end
  end

  def queue_count
    puts "Queue has #{queue_res.length} entries"
  end

  def queue_clear
    self.queue_res = Array.new
  end

  def queue_find(command)
    find(command, self.queue_res) if self.queue_res
  end

  def queue_print
    queue_output
  end

  def queue_print_by(field)
    sort_field = field.join('_')
    sort_field = sort_field.to_sym
    if field_valid?(sort_field)
      self.queue_res = queue_res.sort_by{ |a| a.send(sort_field) || "" }
      queue_output
    else
      puts "field #{field} not found."
    end
  end

  def queue_save_to(filename)
    extension = filename.split('.').last
    return unless filetype_valid?(extension)
    scribe = Output.new(PRINT_HEADERS)

    case extension
      when 'xml'  then scribe.output_xml(filename, queue_res)
      when 'json' then scribe.output_json(filename, queue_res)
      when 'txt'  then scribe.output_txt(filename, queue_res)
      when 'csv'  then scribe.output_csv(filename, queue_res)
    end
  end

  def add(command, list)
    queue_temp = queue_res
    find(command[1..-1], list)
    self.queue_res |= queue_temp
  end

  def subtract(command, list)
    queue_temp = queue_res
    find(command[1..-1], list)
    self.queue_res = queue_temp - self.queue_res
  end

  def find(cmd, list)
    split_index = cmd.find_index{ |a| a =~ (/and|or/) }
    if split_index.nil? then self.queue_res = search(cmd, list)
    else
      cmd_one, cmd_two = command_split(cmd,split_index)
      res_one = find(cmd_one, list)
      res_two = find(cmd_two, list)
      if cmd[split_index] == "and" then self.queue_res = res_one & res_two 
      elsif cmd[split_index] == "or" then self.queue_res = res_one | res_two 
      else raise "Error in find method case statement."
      end
    end
  end

  private

  def queue_output
    lengths = get_lengths()
    PRINT_HEADERS.each { |k, v| printf "#{ v.ljust( lengths[k] ) }\t" }
    printf "\n"
    queue_res.each_with_index do |a, i|
      PRINT_HEADERS.keys.each do |field|
        value = a.send(field)
        printf "#{ value.to_s.ljust(lengths[field]) }\t" unless value.nil?
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
    if PRINT_HEADERS.include?(field)
      field
    else 
      puts "Sorry, attribute is unrecognizable"
      puts "These are the following attributes: #{PRINT_HEADERS.keys.join(' ')}"
    end
  end

  def command_split(command, split_index)
    #split an array on an index.
    #e.g. command_split( [1, 2, 3], 1 ) => [[1],[3]]
    part_one = command.slice(0..split_index - 1)
    part_two = command.slice(split_index + 1..-1)
    [ part_one, part_two ]
  end

  def search(command, list) #takes a split array [field, criteria...]
    field = command[0].strip
    criteria = command[1..-1].join(' ').strip
    criteria = criteria.gsub(/[()]/,'').strip.split(',')

    if field_valid?(field.to_sym)
      list.select{ |a| a if ostruct_match(a, field, criteria) }    
    else puts "Specified fields is invalid"
    end
  end

  def ostruct_match(ostruct, field, criteria) #criteria is an array
    criteria_arry = criteria.collect{ |c| c.downcase.strip }

    if criteria_arry.include? ostruct.send(field.to_sym).to_s.downcase
      ostruct
    end
  end

  #check to see if filetype match the types in OUTPUT_TYPES
  def filetype_valid?(extension) 
    if OUTPUT_TYPES.include? extension
      return true
    else
      puts "Output supports #{OUTPUT_TYPES.join(', ')} filetypes"
      return false
    end
  end
end