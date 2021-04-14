class MalformedRawModelData < StandardError; end

class CellModel
  attr_reader :value

  def initialize(raw_str)
    raise MalformedRawModelData, 'Invalid raw string data' unless valid?(raw_str)

    self.value = raw_str
  end

  def valid?(raw_str)
    raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
  end

  def value=(raw_str)
    raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
  end

  def accept(visitor)
    raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
  end

  def ==(other)
    self.class == other.class && self.value == other.value
  end
end

class IntCellModel < CellModel
  def valid?(raw_str)
    raw_str.match?(/\d+/)
  end

  def value=(raw_str)
    @value = raw_str.to_i
  end

  def accept(visitor)
    visitor.forInt(self)
  end
end

class StringCellModel < CellModel
  def valid?(raw_str)
    true
  end

  def value=(raw_str)
    @value = raw_str
  end

  def accept(visitor)
    visitor.forString(self)
  end
end

class MoneyCellModel < CellModel
  def valid?(raw_str)
    raw_str.match?(/\d+\.\d{2}/)
  end

  def value=(raw_str)
    dollars, cents = raw_str.split('.').map(&:to_i)
    @value = dollars * 100 + cents
  end

  def accept(visitor)
    visitor.forMoney(self)
  end
end

class TableModel
  attr_reader :cells

  def initialize(cells)
    @cells = cells
  end

  def ==(other)
    cells == other.cells
  end

  def empty?
    @cells.empty?
  end
end
