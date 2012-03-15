$LOAD_PATH.unshift('./')
require "yaml"
require "ruby-debug"
require "eventmanager"
require "output"
require "queue"

class EventReporter
  attr_accessor :manager, :help_dict, :queue_manager

  def initialize
    puts "EventReporter Initialized."
    loadhelp()
    self.queue_manager = Queue.new()
  end

  def load(command=["event_attendees.csv"])
    if command.empty? then filename = "event_attendees.csv"
    else filename = command[0]
    end
    puts "Loading #{filename}"
    self.manager = EventManager.new(filename)
  end

  def help(command)
    if help_dict.keys.include? command.join(' ')
      puts "\n#{help_dict[command.join(' ')]}"
    elsif command.empty?
      puts help_dict.keys.join(', ')
    else
      puts "#{command.join(' ')} not found"
    end
  end

  def queue(command)
    queue_manager.queue_do(command)
  end

  def find(command)
    queue_manager.find(command, manager.attendees) if manager
  end

  def add(command)
    queue_manager.add(command, manager.attendees)
  end

  def subtract(command)
    queue_manager.subtract(command, manager.attendees)
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

# reporter.find(%w(zipcode 00000))
# reporter.queue(%w(save to testing.xml))
# reporter.queue(%w(save to testing.json))
# reporter.queue(%w(save to testing.txt))
# reporter.queue(%w(save to testing.csv))
# reporter.queue(%w(print by last_name))
# manager.state_stats