$LOAD_PATH.unshift('./')
require "csv"
require "sunlight"
require "eventmanager"

class EventReporter
  attr_accessor :manager, :queue

  def initialize
    puts "EventReporter Initialized."
    loadfile()
    self.queue = []
    queue_clear()
    load_definitions()
  end

  def loadfile(filename="event_attendees.csv")
    puts "Loading #{filename}"
    self.manager = EventManager.new(filename)
  end

  def load_definitions
    @Definitions = Hash.new
    @Definitions["load"] = "load <filename>\nErase any loaded data and parse \
the specified file. If no filename is given, default to event_attendees.csv."
    @Definitions["help"] = "help\nOutput a listing of the available individual \
commands."
    @Definitions["queue count"] = "queue count\nOutput how many records are in \
the current queue."
    @Definitions["queue clear"] = "queue clear\nEmpty the queue."
    @Definitions["queue print"] = "queue print\nPrint out a tab-delimited data \
table with a header row." 
    @Definitions["queue print by"] = "queue print by <attribute>\nPrint the \
data table sorted by the specified attribute."
    @Definitions["queue save to"] ="queue save to <filename.csv>\nExport the \
current queue to the specified filename as a CSV."
    @Definitions["find"] = "find <attribute> <criteria>\nLoad the queue with \
all records matching the criteria for the given attribute."
    @Definitions["options"] = "load, help, queue count, queue clear, \
queue print, queue print by, queue save to, find"
  end

  def print_help(*command)
    if command.length == 0
      puts @Definitions["options"]
    elsif @Definitions.keys.include? command.first
      puts @Definitions[command.first]
    else 
      puts "#{command.first} not found"
    end
  end

  def find(attribute, criteria)
    #Add error handling...
    if attribute_valid?(attribute.intern)
      manager.attendees.each do |attendee|
          queue << attendee if attendee.send(attribute.intern) == criteria
      end
    else puts "Specified attribute is invalid"
    end
  end

  def queue_count
    puts "Queue has #{queue.length} entries"
  end

  def queue_clear
    queue = Array.new
  end

  def queue_print_headers(headers)
    headers.each{ |header| printf "#{header.upcase}\t" }
    printf "\n"
  end

  def queue_output
    queue.each_with_index do |attendee, i|
      queue_print_headers( manager.headers ) if i == 0
      puts attendee.to_s
    end
  end

  def queue_print(*attribute)
    if attribute.length == 1
      attribute = attribute.first.intern
      attribute_valid?(attribute)
      queue = queue.sort_by{ |attendee| attendee.send(attribute) }
    elsif attribute.length > 1
      puts "queue_print command only takes one argument"
    end
    queue_output
  end

  def attribute_valid?(attribute)
    if(manager.headers.include? attribute)
      attribute
    else puts "Sorry, attribute is unrecognizable"
    end
  end

  def run
    puts "Event Reporter: Active"
    parts = Array.new
    while parts[0] != "quit"
      printf "Please enter a command: "
      input = gets.chomp
      parts = input.split(" ")
      num_of_parts = parts.length #number of parts
      if parts[0] == "quit"
        #do nothing
      elsif parts[0] == "help"
        if num_of_parts == 1 then print_help
        else print_help(parts[1..-1].join(" "))
        end
      else
        if num_of_parts == 1
          case parts[0]
          when 'load' then loadfile
          else 
            puts "Can't recognize command."
          end
        elsif num_of_parts == 2
          case parts[0]
          when 'load' then loadfile(parts[1])
          when 'queue' then
            case parts[0..1].join(" ")
            when 'queue count' then queue_count
            when 'queue clear' then queue_clear
            when 'queue print' then queue_print
            end
          else puts "Can't recognize command."
          end
        elsif num_of_parts == 3
          case parts[0]
            when 'find' then
              find(parts[1], parts[2])
          end
        elsif num_of_parts == 4
          case parts[0..2].join(" ")
          when 'queue print by' then queue_print(parts[3])
          when 'queue save to' then output_data(queue, parts[3])
          else puts "Can't recognize command."
          end
        else 
          puts "Can't recognize command."
        end
      end
    end
  end
end

reporter = EventReporter.new
#reporter.loadfile
#reporter.find("zipcode", "20010")
reporter.run
#manager.state_stats