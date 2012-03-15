$LOAD_PATH << './'
require 'csv'
require 'attendee'
require 'sunlight'

class EventManager
  CSV_OPTIONS = {:headers => true, :header_converters => :symbol}
  Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

  attr_accessor :attendees, :headers

  def initialize(filename, options = CSV_OPTIONS)
    load_attendees(CSV.open(filename, options))
  end

  def print_names
    attendees.each do |attendee|
      puts attendee.full_name
    end
  end

  def print_zipcodes
    attendees.each do |attendee|
      puts attendee.zipcode
    end
  end

  def print_phone_numbers
    attendees.each do |attendee|
      puts attendee.phone_number
    end
  end

  def output_data
    output = CSV.open("event_attendees_clean.csv", "w")

    attendees.each do |attendee|
      output << attendee.get_keys if output.lineno == 0
      output << attendee.to_s
    end
  end

  def rep_lookup
    20.times do |i|
      legs = Sunlight::Legislator.all_in_zipcode(attendees[i].zipcode)
      names = legs.collect do |leg|
        "#{leg.title} #{leg.firstname[0]}. #{leg.lastname} (#{leg.party})"
      end

      puts "#{attendees[i].full_name} #{attendees[i].zipcode},#{names.join(", ")}"
    end
  end

  def create_form_letters
    letter = File.open("form_letter.html", "r").read
    20.times do |i|
      attendee = attendees[i]
      cl = letter.gsub("#first_name",attendee.first_name)
      cl = cl.gsub("#last_name",attendee.last_name)
      cl = cl.gsub("#street", attendee.street)
      cl = cl.gsub("#city", attendee.city)
      cl = cl.gsub("#state", attendee.state)
      cl = cl.gsub("#zipcode", attendee.zipcode)

      filename = "output/thanks_#{attendee.last_name}_#{attendee.first_name}"
      output = File.new(filename, "w")
      output.write(cl)
    end
  end

  def day_stats
    days = Array.new(7){0}
    attendees.each do |attendee|
      rawdate = attendee.regdate.split(" ")[0]
      weekday = Date.strptime(rawdate, "%m/%d/%y").wday
      days[weekday] = days[weekday] + 1
    end

    days.each_with_index{|counter,day| puts "#{day}\t#{counter}"}
  end

  def state_stats
    state_data = {}
    puts attendees[1]
    attendees.each do |attendee|
      state = attendee.state
      if state_data[state].nil? then state_data[state] = 1
      else state_data[state] = state_data[state] + 1
      end
    end
    ranks = state_data.sort_by{|state, counter| counter}.collect{|state, counter| state}.reverse
    state_data = state_data.sort_by{|state, counter| state || ""}
    state_data.each do |state, counter|
      puts "#{state}:\t#{counter}\t(#{ranks.index(state) + 1})"
    end
  end

  private

  def load_attendees(file)
    self.attendees = file.collect do |line|
      self.headers=line.headers
      Attendee.new(line)
    end
  end

end

#em = EventManager.new("event_attendees.csv")
#em.print_zipcodes
#em.output_data
#em.print_names
#em.state_stats
