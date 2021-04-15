# frozen_string_literal: true

require 'csv'

class MalformedCSVError < StandardError; end

# Creates table model from CSV file
class CSVReader
  def read(path)
    CSV.open(path, col_sep: ';') do |csv|
      types = (csv.readline || []).map { |x| self.class.parse_type(x) }
      cells = csv.read.map do |row|
        # needed for case when there is only one column and it allows empty values (like string)
        row = [''] if row.empty?
        raise MalformedCSVError, "Columns count differs from headers'" if row.size != types.size

        begin
          row.map.with_index { |cell_raw, i| types[i].new(cell_raw || '') }
        rescue MalformedRawModelData
          raise MalformedCSVError, 'Unable to cast column value to required type'
        end
      end
      TableModel.new(cells)
    end
  end

  def self.parse_type(type_str)
    case type_str
    when 'int' then IntCellModel
    when 'string' then StringCellModel
    when 'money' then MoneyCellModel
    else raise MalformedCSVError, 'Unable to parse types from headers'
    end
  end
end
