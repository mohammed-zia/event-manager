require 'google/apis/civicinfo_v2'
require 'csv'
require 'erb'
require 'time'

puts 'Event Manager Initialized!'

# contents = File.read("event_attendees.csv")
# puts contents

# lines = File.readlines('event_attendees.csv')

# lines.each_with_index do |line, index|
#   next if index == 0
#   columns = line.split(',')
#   name = columns[2]
#   p name
# end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

# def clean_zipcode(zipcode)
#   if zipcode.nil?
#     zipcode = '00000'
#   elsif zipcode.length < 5
#     zipcode = zipcode.rjust(5, '0')
#   elsif zipcode.length > 5
#     zipcode = zipcode[0..4]
#   else
#     zipcode
#   end
# end
# This longform clean_zipcode function can be concised down to :

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislator_by_zipcode(zipcode)

  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives at blah blah'
  end
end

def save_thankyou_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def phone_number(phone_number_clean)
  unless phone_number_clean.nil?
    if phone_number_clean.length == 10
      phone_number_clean
    elsif phone_number_clean.length == 11 && phone_number_clean[0] == "1"
      phone_number_clean[1..10]
    else
      phone_number_clean = ""
    end
  else
    phone_number_clean = ""
  end
end

def max_count(arr)
  arr.uniq.map { |n| arr.count(n) }.max
end

def most_freq(array)
  counts = array.tally
  max = counts.values.max
  most_freq = Hash[counts.select { |k,v| v == max }].keys
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = []
days = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_numbers = row[:homephone]
  phone_numbers_clean = phone_numbers.gsub(/[^0-9A-Za-z]/, '')
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = phone_number(phone_numbers_clean)
  date = Time.strptime(row[:regdate], "%m/%d/%y %H:%M")
  hours << date.hour
  days << date.strftime('%A')
  legislators = legislator_by_zipcode(row[:zipcode])
  form_letter = erb_template.result(binding)
  save_thankyou_letter(id, form_letter)
end
puts "Most frequent hours: #{most_freq(hours)}, Most frequent days: #{most_freq(days)}"
