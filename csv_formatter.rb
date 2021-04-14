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

  def line(i, width)
    (lines[i] || "").rjust(width)
  end

  def lines
    raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
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

class ASCIIVisitor
  def forInt(cell)
    IntCellASCII.new(cell)
  end

  def forString(cell)
    StringCellASCII.new(cell)
  end

  def forMoney(cell)
    MoneyCellASCII.new(cell)
  end
end

class ASCIIFormatter
  EMPTY_TABLE = <<~TABLE
    ++
    ++
  TABLE

  def initialize(table)
    @table = table
  end

  def format
    return EMPTY_TABLE if @table.empty?

    visitor = ASCIIVisitor.new
    @csv_cells = @table.cells.map { |row| row.map { |cell| cell.accept(visitor)} }

    # require 'pry'; binding.pry
    column_count = @table.cells.first.size
    row_count = @table.cells.size
    @column_widths = Array.new(column_count, 0)
    @row_heights = Array.new(row_count, 0)
    @csv_cells.each.with_index do |row, i|
      row.each.with_index do |cell, j|
        @column_widths[j] = [@column_widths[j], cell.width].max
        @row_heights[i] = [@row_heights[i], cell.height].max
      end
    end
    @table_width = @column_widths.sum + @column_widths.size + 1

    @result = formatted_begin + "\n"
    @result += @csv_cells.size.times.map { |i| formatted_row(i) }.join("\n#{formatted_between}\n")
    @result += "\n" + formatted_between + "\n"
    @result
  end

  def format
    return EMPTY_TABLE if @table.empty?

    create_formatted_cells
    calculate_dimensions
  end

  def create_formatted_cells
    visitor = ASCIIVisitor.new
    @csv_cells = @table.cells.map { |row| row.map { |cell| cell.accept(visitor)} }
  end

  def formatted_begin
    # require 'pry'; binding.pry
    "+#{'-' * (@table_width - 2)}+"
  end

  def formatted_row(row_index)
    @row_heights[row_index].times.map do |i|
      row = @csv_cells[row_index].map.with_index do |cell, j|
        cell.line(i, @column_widths[j])
      end.join('|')
      "|#{row}|"
    end.join("\n")
  end

  def formatted_between
    "+#{@column_widths.map { |w| '-' * w }.join('+')}+"
  end
end
