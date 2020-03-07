# -*- coding: utf-8 -*-
# frozen_string_literal: true

#--
# Arrayに二分探索を行うbsearchメソッドを実装する。
# Ruby 2.0未満用。
#
# Ruby 2.6の処理を移植している。
#++
class Array
  # ブロックの評価結果で範囲内の各要素の判定を行い、
  # 条件を満たす値を二分探索(計算量は O(log n))で検索します
  # @return [Object] 条件を満たす値
  # @return [nil] 要素が見つからない場合
  # @return [Enumerator] ブロックが渡されなかった場合
  #
  # self はあらかじめソートしておく必要があります。
  #
  # 処理の簡略化のため、find-anyモードには非対応。
  def bsearch(&block)
    return each() unless block_given?

    index_result = bsearch_index(&block)
    return index_result && self[index_result]
  end

  # ブロックの評価結果で範囲内の各要素の判定を行い、
  # 条件を満たす値の位置を二分探索(計算量は O(log n))で検索します
  # @return [Integer] 条件を満たす値の位置
  # @return [nil] 要素が見つからない場合
  # @return [Enumerator] ブロックが渡されなかった場合
  #
  # self はあらかじめソートしておく必要があります。
  #
  # 処理の簡略化のため、find-anyモードには非対応。
  def bsearch_index
    return each() unless block_given?

    low = 0
    high = length()
    smaller = false
    satisfied = false

    while low < high
      mid = low + ((high - low) / 2)
      val = self[mid]
      v = yield val

      case v
      when true
        satisfied = true
        smaller = true
      when false, nil
        smaller = false
      else
        raise(
          TypeError,
          "wrong argument type #{v.class} (must be true, false or nil)"
        )
      end

      if smaller
        high = mid
      else
        low = mid + 1
      end
    end

    return nil unless satisfied

    return low
  end
end
