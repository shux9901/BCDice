# -*- coding: utf-8 -*-
# frozen_string_literal: true

bcdice_root = File.expand_path('..', File.dirname(__FILE__))
$:.unshift(bcdice_root) unless $:.include?(bcdice_root)

require 'test/unit'
require 'utils/sparse_table'

class TestSparseTable < Test::Unit::TestCase
  # ダイスロール方法の書式が正しい場合、受理される
  def test_valid_dice_roll_method_should_be_accepted_1
    assert_nothing_raised do
      SparseTable.new(
        'Table',
        '2D6',
        [
          [7, 'A'],
          [12, 'B']
        ]
      )
    end
  end

  # ダイスロール方法の書式が正しい場合、受理される
  def test_valid_dice_roll_method_should_be_accepted_2
    assert_nothing_raised do
      SparseTable.new(
        'Table',
        '1D100',
        [
          [25, 'A'],
          [50, 'B'],
          [75, 'C'],
          [100, 'D']
        ]
      )
    end
  end

  # ダイスロール方法の書式が正しくない場合、拒絶される
  def test_invalid_dice_roll_method_should_be_denied_1
    assert_raise(ArgumentError) do
      SparseTable.new(
        'Table',
        'D6',
        [
          [3, 'A'],
          [6, 'B']
        ]
      )
    end
  end

  # ダイスロール方法の書式が正しくない場合、拒絶される
  def test_invalid_dice_roll_method_should_be_denied_2
    assert_raise(ArgumentError) do
      SparseTable.new(
        'Table',
        '2B6',
        [
          [7, 'A'],
          [12, 'B']
        ]
      )
    end
  end

  # 出目の合計値の範囲の不一致がある場合、拒絶される（定義域が最大値未満）
  def test_sum_range_mismatch_should_be_denied_less_than_max
    assert_raise(ArgumentError) do
      SparseTable.new(
        'Table',
        '2D6',
        [
          [7, 'A'],
          [11, 'B']
        ]
      )
    end
  end

  # 出目の合計値の範囲の不一致がある場合、拒絶される（定義域が最大値を超過）
  def test_sum_range_mismatch_should_be_denied_greater_than_max
    assert_raise(ArgumentError) do
      SparseTable.new(
        'Table',
        '2D6',
        [
          [7, 'A'],
          [13, 'B']
        ]
      )
    end
  end
end
