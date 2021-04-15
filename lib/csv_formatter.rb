# frozen_string_literal: true

require_relative 'model'

# Represents one cell in ASCII table.
# This cell knows its format (by type), dimensions and how to justify itself
class CellASCII
  def initialize(cell_model)
    @model = cell_model
  end

  def width
    lines.map(&:size).max
  end

  def height
    lines.size
  end

  # Returns lines of cell's formatted form (but without justification)
  def lines
    raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
  end

  # Returns one formatted line from lines with correct justification applied
  def line(i, width)
    (lines[i] || "").rjust(width)
  end
end

class IntCellASCII < CellASCII
  def lines
    @lines ||= [@model.value.to_s]
  end
end

class StringCellASCII < CellASCII
  def line(i, width)
    (lines[i] || "").ljust(width)
  end

  def lines
    @lines ||= @model.value.empty? ? [''] : @model.value.split(' ')
  end
end

class MoneyCellASCII < CellASCII
  def lines
    dollars, cents = @model.value.abs.divmod(100)
    sign = @model.value.negative? ? '-' : ''
    @lines ||= ["#{sign}#{dollars.to_s.reverse.scan(/.{1,3}/).join(' ').reverse}.#{cents.to_s.rjust(2, '0')}"]
  end
end

# Visitor
class ASCIICellFormatter
  def createInt(cell)
    IntCellASCII.new(cell)
  end

  def createString(cell)
    StringCellASCII.new(cell)
  end

  def createMoney(cell)
    MoneyCellASCII.new(cell)
  end
end

# Creates ASCII table for table model
class ASCIIFormatter
  EMPTY_TABLE = <<~TABLE
    ++
    ++
  TABLE

  def initialize(table_model)
    @table_model = table_model
  end

  def format
    return EMPTY_TABLE if @table_model.empty?

    create_ascii_cells
    calculate_dimensions
    generate_formatted_string
  end

  private 

  def create_ascii_cells
    formatter = ASCIICellFormatter.new
    @ascii_cells = @table_model.cells.map { |row| row.map { |cell| cell.format(formatter)} }
  end

  def calculate_dimensions
    column_count = @table_model.cells.first.size
    @column_widths = Array.new(column_count, 0)
    @ascii_cells.each do |row|
      row.each.with_index do |cell, j|
        @column_widths[j] = [@column_widths[j], cell.width].max
      end
    end
    @table_width = @column_widths.sum + @column_widths.size + 1
  end

  def generate_formatted_string
    @output = String.new
    @output << header_rule
    @ascii_cells.each do |row|
      write_row(row)
      @output << line_rule
    end
    @output
  end

  def header_rule
    "+#{'-' * (@table_width - 2)}+\n"
  end

  def line_rule
    "\n+#{@column_widths.map { |w| '-' * w }.join('+')}+\n"
  end

  def write_row(row)
    height = row.map(&:height).max
    (height - 1).times do |i|
      write_line(row, i)
      @output << "\n"
    end
    write_line(row, height - 1)
  end

  def write_line(row, line_index)
    @output << '|'
    row.each.with_index do |cell, j|
      @output << cell.line(line_index, @column_widths[j]) << '|'
    end
  end
end
