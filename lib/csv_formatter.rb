require_relative 'model'

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
    dollars, cents = @model.value.divmod(100)
    @lines ||= ["#{dollars.to_s.reverse.scan(/.{1,3}/).join(' ').reverse}.#{cents.to_s.rjust(2, '0')}"]
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
    @ascii_cells.each.with_index do |row|
      row.each.with_index do |cell, j|
        @column_widths[j] = [@column_widths[j], cell.width].max
      end
    end
    @table_width = @column_widths.sum + @column_widths.size + 1
  end

  def generate_formatted_string
    @result = header_rule
    @result << @ascii_cells.map { |row| format_row(row) }.join("#{line_rule}")
    @result << line_rule
  end

  def header_rule
    "+#{'-' * (@table_width - 2)}+\n"
  end

  def line_rule
    @line_rule ||= "\n+#{@column_widths.map { |w| '-' * w }.join('+')}+\n"
  end

  def format_row(row)
    height = row.map(&:height).max
    (0...height).map do |i|
      "|#{row.map.with_index { |cell, j| cell.line(i, @column_widths[j]) }.join('|')}|"
    end.join("\n")
  end
end
