require 'csv_reader'
require 'csv_formatter'
require 'model'

shared_context "common models" do
  let(:normal_model) do
    TableModel.new([
      [IntCellModel.new("123"), StringCellModel.new("a00000bc def hhhhhhhhhhh"), MoneyCellModel.new("1000.33")],
      [IntCellModel.new("-9"), StringCellModel.new("xxxxxxxxxxxxxxxxx"), MoneyCellModel.new("999999.00")],
      [IntCellModel.new("0"), StringCellModel.new(""), MoneyCellModel.new("-1.03")],
    ])
  end
  let(:empty_model) { TableModel.new([]) }
  let(:model_with_empty) { TableModel.new([[StringCellModel.new("")], [StringCellModel.new("asdf")]]) }

  let(:normal_output) { <<~OUTPUT }
    +--------------------------------+
    |123|a00000bc         |  1 000.33|
    |   |def              |          |
    |   |hhhhhhhhhhh      |          |
    +---+-----------------+----------+
    | -9|xxxxxxxxxxxxxxxxx|999 999.00|
    +---+-----------------+----------+
    |  0|                 |     -1.03|
    +---+-----------------+----------+
  OUTPUT
  let(:empty_output) { <<~OUTPUT }
    ++
    ++
  OUTPUT
  let(:output_with_empty) { <<~OUTPUT }
    +----+
    |    |
    +----+
    |asdf|
    +----+
  OUTPUT
end

describe CSVReader do
  include_context "common models"

  context ".read" do
    subject { described_class.new.read(csv_path) }

    context "given normal input" do
      let(:csv_path) { "./spec/fixtures/normal.csv" }

      it { is_expected.to eq(normal_model) }
    end

    context "given input with only headers" do
      let(:csv_path) { "./spec/fixtures/header_only.csv" }

      it { is_expected.to eq(empty_model) }
    end

    context "given one-column input with empty lines" do
      let(:csv_path) { "./spec/fixtures/with_empty.csv" }

      it { is_expected.to eq(model_with_empty) }
    end

    context "given empty file" do
      let(:csv_path) { "./spec/fixtures/empty.csv" }

      it { is_expected.to eq(empty_model) }
    end

    context "given malformed header" do
      let(:csv_path) { "./spec/fixtures/bad_header.csv" }

      it "raises CSVMalformedError" do
        expect { subject }.to raise_error(MalformedCSVError)
      end
    end

    context "given input with row with wrong number of columns" do
      let(:csv_path) { "./spec/fixtures/wrong_column_counts.csv" }

      it "raises CSVMalformedError" do
        expect { subject }.to raise_error(MalformedCSVError)
      end
    end

    context "given value that cannot be parsed as required type" do
      let(:csv_path) { "./spec/fixtures/invalid.csv" }

      it "raises CSVMalformedError" do
        expect { subject }.to raise_error(MalformedCSVError)
      end
    end
  end
end

describe ASCIIFormatter do
  include_context "common models"

  context ".format" do
    subject { described_class.new(model).format }

    context "given normal input" do
      let(:model) { normal_model }

      it { is_expected.to eq(normal_output) }
    end

    context "given input with only headers" do
      let(:model) { empty_model }

      it { is_expected.to eq(empty_output) }
    end

    context "given one-column input with empty lines" do
      let(:model) { model_with_empty }

      it { is_expected.to eq(output_with_empty) }
    end
  end
end
