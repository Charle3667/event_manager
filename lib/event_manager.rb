require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def get_hour (date_time)
  date_time_array = date_time.split(' ')
  time = date_time_array[1].split(':')
  hour = time[0]
  hour
end

def peak_hour(hash)
  hash.each do |k, v| 
    if v == hash.values.max 
      if k.to_i > 12
        puts "At #{(k.to_i) - 12} PM, a peak of 3 registrations occured."
      else
        puts "At #{k} AM, a peak of 3 registrations occured."
      end
    end
  end
end

def clean_phone_number(phone_number, name)
  bad_num = "Bad Number"
  phone_string = phone_number.split('').delete_if {|x| x == "(" || x == ")" || x == "-" || x == " " || x == "."}.join('')
  if phone_string.length < 10 
    puts "#{name} #{bad_num}"
  elsif phone_string.length == 10
    puts "#{name} #{phone_string }"
  elsif phone_string.length > 10 && phone_string[0] == "1"
    puts "#{name} #{phone_string[1..10]}"
  else
    puts "#{name} #{bad_num}"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

peak_hours = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  # home_phone = clean_phone_number(row[:homephone], name)
  hour = get_hour(row[:regdate])
  peak_hours[hour] += 1
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

current_peak = peak_hour(peak_hours)
