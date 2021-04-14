require 'model'
require 'csv_formatter'
require 'csv_reader'

def main
  csv_path = ARGV[0]
  unless csv_path && File.file?(csv_path)
    puts 'No suitable input path provided'
    puts 'Usage: bundle exec ruby -I csv_to_ascii.rb CSV_PATH'
    exit(1)
  end

  begin
    table_model = CSVReader.new.read(csv_path)
  rescue MalformedCSVError
    puts 'Unable to read provided CSV file'
    exit(1)
  end

  csv_formatter = ASCIIFormatter.new(table_model)
  puts csv_formatter.format
end

main if $PROGRAM_NAME == __FILE__
