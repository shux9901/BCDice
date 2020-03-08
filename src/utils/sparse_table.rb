# -*- coding: utf-8 -*-
# frozen_string_literal: true

# TODO: Ruby 2.0未満のサポートを終了したとき削除する
if RUBY_VERSION < '2.0'
  require 'utils/array_bsearch'
end

# 疎らな表を表すクラス。
#
# このクラスを使うと、表の定義を短く書ける。
# このクラスを使って表を定義するときは、各項目を以下の形で書く。
#
#     [最大値, 内容]
#
# roll メソッドで表を振ると、以下のように動作する。
# 出目の合計値を _x_ とする。
# このとき、最大値が _x_ 以上であり、かつ最大値が _x_ と最も近い項目が選ばれる。
#
# @example 表の定義（バトルテックのクリティカル表）
#   CRITICAL_TABLE = SparseTable.new(
#     'クリティカル表',
#     '2D6',
#     [
#       [7, '致命的命中はなかった'],
#       [9, '1箇所の致命的命中'],
#       [11, '2箇所の致命的命中'],
#       [12, 'その部位が吹き飛ぶ（腕、脚、頭）または3箇所の致命的命中（胴）']
#     ]
#   )
#
# @example 表を振った結果
#   CRITICAL_TABLE.roll.format
#   # 出目の合計が6の場合："クリティカル表(6) ＞ 致命的命中はなかった"
#   # 出目の合計が9の場合："クリティカル表(9) ＞ 1箇所の致命的命中"
#   # 出目の合計が10の場合："クリティカル表(10) ＞ 2箇所の致命的命中"
#   # 出目の合計が11の場合："クリティカル表(11) ＞ 2箇所の致命的命中"
#   # 出目の合計が12の場合："クリティカル表(12) ＞ その部位が吹き飛ぶ（腕、脚、頭）または3箇所の致命的命中（胴）"
class SparseTable
  # 表を振った結果を表すクラス
  class RollResult
    # 振った表
    # @return [SparseTable]
    attr_reader :table
    # 出目の合計
    # @return [Integer]
    attr_reader :sum
    # 出目の配列
    # @return [Array<Integer>]
    attr_reader :values
    # 選ばれた項目の内容
    # @return [Object]
    attr_reader :content

    # 結果を初期化する
    # @param [SparseTable] table 振った表
    # @param [Array<Integer>] values 出目の配列
    # @param [Proc] formatter 結果の整形処理
    def initialize(table, values, formatter)
      @table = table
      @values = values.dup.freeze
      @formatter = formatter

      # TODO: Ruby 2.4以降では Array#sum を使う
      @sum = @values.reduce(0, :+)
      @content = table.fetch(@sum).content
    end

    # 表を振った結果を整形する
    #
    # 別名として to_s が指定されているので、式展開を使うと簡潔に整形された結果が得られる。
    #
    # @return [String]
    # @example 式展開
    #   result = some_sparse_table.roll(bcdice)
    #   result_str = "結果: #{result}"
    def format
      @formatter[@table, self]
    end

    alias to_s format
  end

  # 表の項目を表す構造体
  #
  # [+max+]  出目の合計の最大値
  # [+content+] 内容
  Item = Struct.new(:max, :content)

  # 項目を選ぶときのダイスロールの方法を表す正規表現
  DICE_ROLL_METHOD_RE = /\A(\d+)D(\d+)\z/i.freeze

  # 表を振った結果の整形処理（既定の処理）
  DEFAULT_FORMATTER = lambda do |table, result|
    "#{table.name}(#{result.sum}) ＞ #{result.content}"
  end

  # @return [String] 表の名前
  attr_reader :name
  # @return [Integer] 振るダイスの個数
  attr_reader :num_of_dice
  # @return [Integer] 振るダイスの面数
  attr_reader :num_of_sides

  # 表を初期化する
  #
  # ブロックを与えると、独自の結果整形処理を指定できる。
  # ブロックは振った表（+table+）と振った結果（+result+）を引数として受け取る。
  #
  # @param [String] name 表の名前
  # @param [String] dice_roll_method 項目を選ぶときのダイスロールの方法（'1D6'など）
  # @param [Array<Array<(Integer, Object)>>] items 表の項目の配列。[最大値, 内容]
  # @yieldparam [SparseTable] table 振った表
  # @yieldparam [RollResult] result 表を振った結果
  # @raise [ArgumentError] typeが正しい書式で指定されていなかった場合
  # @raise [ArgumentError] 出目の合計値が取り得る範囲と、itemsがカバーしている
  #   出目の合計値の範囲とが、対応していなかった場合。
  #
  # @example 表の定義（バトルテックのクリティカル表）
  #   CRITICAL_TABLE = SparseTable.new(
  #     'クリティカル表',
  #     '2D6',
  #     [
  #       [7, '致命的命中はなかった'],
  #       [9, '1箇所の致命的命中'],
  #       [11, '2箇所の致命的命中'],
  #       [12, 'その部位が吹き飛ぶ（腕、脚、頭）または3箇所の致命的命中（胴）']
  #     ]
  #   )
  #
  # @example 独自の結果整形処理を指定する場合
  #   CRITICAL_TABLE_WITH_FORMATTER = SparseTable.new(
  #     'クリティカル表',
  #     '2D6',
  #     [
  #       [7, '致命的命中はなかった'],
  #       [9, '1箇所の致命的命中'],
  #       [11, '2箇所の致命的命中'],
  #       [12, 'その部位が吹き飛ぶ（腕、脚、頭）または3箇所の致命的命中（胴）']
  #     ]
  #   ) do |table, result|
  #     "クリティカル発生? ＞ #{result.sum}[#{result.values}] ＞ #{result.content}"
  #   end
  #
  #   CRITICAL_TABLE_WITH_FORMATTER.roll.format
  #   #=> "クリティカル発生? ＞ 11[5,6] ＞ 2箇所の致命的命中"
  def initialize(name, dice_roll_method, items, &formatter)
    @name = name.freeze
    @formatter = formatter || DEFAULT_FORMATTER

    m = DICE_ROLL_METHOD_RE.match(dice_roll_method)
    unless m
      raise ArgumentError, "invalid dice roll method: #{dice_roll_method}"
    end

    @num_of_dice = m[1].to_i
    @num_of_sides = m[2].to_i

    store(items)
  end

  # 指定された値に対応する項目を返す
  # @param [Integer] value 値（出目の合計）
  # @return [Item]
  # @raise [ArgumentError] 値が大きすぎる場合
  def fetch(value)
    item = @items.find { |i| i.max >= value }
    unless item
      raise ArgumentError, "value is too big: #{value}"
    end

    return item
  end

  # 表を振る
  # @param [BCDice] bcdice ランダマイザ
  # @return [RollResult] 表を振った結果
  def roll(bcdice)
    _sum, values_str, = bcdice.roll(@num_of_dice, @num_of_sides)
    # TODO: BCDice#roll から直接、整数の配列として出目を受け取りたい
    values = values_str.split(',').map(&:to_i)

    return RollResult.new(self, values, @formatter)
  end

  private

  # 表の項目を格納する
  # @param [Array<Array<(Integer, String)>>] items 表の項目の配列。[最大値, 内容]
  # @raise [ArgumentError] 出目の合計値が取り得る範囲と、itemsがカバーしている
  #   出目の合計値の範囲とが、対応していなかった場合。
  #   @return [self]
  def store(items)
    # 出目の合計値が取り得る最大値
    max_sum = @num_of_dice * @num_of_sides

    sorted_items = items.sort_by { |max, _| max }

    max_sum_in_items = sorted_items.last[0]
    unless max_sum_in_items == max_sum
      raise(
        ArgumentError,
        "invalid max value in items: #{max_sum_in_items} (expected #{max_sum})"
      )
    end

    @items = sorted_items.
             map { |max, content| Item.new(max, content) }.
             freeze

    self
  end
end
