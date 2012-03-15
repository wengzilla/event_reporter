require 'ostruct'

class Zipcode
  def self.clean(dirty_zipcode)
    dirty_zipcode.to_s.rjust(5, '0')
  end
end

class PhoneNumber
  INVALID_TELEPHONE = "0" * 10

  def initialize(phone_number)
    @phone_number = clean(phone_number)
  end

  def clean(dirty_number)
    clean_number = dirty_number.scan(/\d/).join

    if clean_number.length == 10 then clean_number
    elsif clean_number.length == 11
      if clean_number.start_with?("1") then clean_number = clean_number[1..-1]
      else clean_number = INVALID_TELEPHONE
      end
    else clean_number = INVALID_TELEPHONE
    end
  end

  def length
    @phone_number.to_s.length
  end

  def to_s
    "(#{@phone_number[0..2]}) #{@phone_number[3..5]}-#{@phone_number[6..-1]}"
  end
end

class Name
  def self.clean(dirty_name)
    dirty_name = dirty_name.downcase
    dirty_name.gsub(/\b\w/){|c| c.capitalize}
  end
end

class Attendee < OpenStruct

  def initialize(attributes)
    # Clean the attributes data?
    super
  end

  def full_name
    [Name.clean(first_name), Name.clean(last_name)].join(' ')
  end

  def first_name
    Name.clean(super) unless super.nil?
  end

  def last_name
    Name.clean(super) unless super.nil?
  end

  def city
    Name.clean(super) unless super.nil?
  end

  def street
    Name.clean(super) unless super.nil?
  end

  def state
    super.upcase unless super.nil?
  end

  def zipcode
    Zipcode.clean(super)
    #super calls the zipcode method of OpenStruct
    #and returns zipcode
  end

  def phone_number
    PhoneNumber.new(homephone)
  end

  def get_keys
    marshal_dump.keys
  end

  def to_s
    line = get_keys.collect { |key| send(key) }
    line.join(' ')
  end
end