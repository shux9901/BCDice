# -*- coding: utf-8 -*-
# frozen_string_literal: true

require 'utils/table'
require 'utils/sparse_table'

class BattleTech < DiceBot
  setPrefixes(['\d*SRM\d+.+', '\d*LRM\d+.+', '\d*BT.+', 'CT', 'DW', 'CD\d+'])

  def initialize
    super
  end

  def gameName
    'バトルテック'
  end

  def gameType
    "BattleTech"
  end

  def getHelpMessage
    return <<MESSAGETEXT
・判定方法
　(回数)BT(ダメージ)(部位)+(基本値)>=(目標値)
　回数は省略時 1固定。
　部位はC（正面）R（右）、L（左）。省略時はC（正面）固定
　U（上半身）、L（下半身）を組み合わせ CU/RU/LU/CL/RL/LLも指定可能
　例）BT3+2>=4
　　正面からダメージ3の攻撃を技能ベース2目標値4で1回判定
　例）2BT3RL+5>=8
　　右下半身にダメージ3の攻撃を技能ベース5目標値8で2回判定
　ミサイルによるダメージは BT(ダメージ)の変わりに SRM2/4/6, LRM5/10/15/20を指定
　例）3SRM6LU+5>=8
　　左上半身にSRM6連を技能ベース5目標値8で3回判定
・CT：致命的命中表
・DW：転倒後の向き表
・CDx：メック戦士意識維持表。ダメージ値xで判定　例）CD3
MESSAGETEXT
  end

  # 致命的命中が発生しない上限値
  NO_CRITICAL_HIT_LIMIT = 7

  def changeText(string)
    string.sub(/PPC/, 'BT10')
  end

  def undefCommandResult
    '1'
  end

  def rollDiceCommand(command)
    result = roll_tables(command, TABLES)
    return result if result

    count = 1
    if /^(\d+)(.+)/ === command
      count = Regexp.last_match(1).to_i
      command = Regexp.last_match(2)
    end

    debug('executeCommandCatched count', count)
    debug('executeCommandCatched command', command)

    case command
    when /^CD(\d+)$/
      damage = Regexp.last_match(1).to_i
      return getCheckDieResult(damage)
    when /^((S|L)RM\d+)(.+)/
      tail = Regexp.last_match(3)
      type = Regexp.last_match(1)
      damageFunc = lambda { getXrmDamage(type) }
      return getHitResult(count, damageFunc, tail)
    when /^BT(\d+)(.+)/
      debug('BT pattern')
      tail = Regexp.last_match(2)
      damageValue = Regexp.last_match(1).to_i
      damageFunc = lambda { damageValue }
      return getHitResult(count, damageFunc, tail)
    end

    return nil
  end

  def getXrmDamage(type)
    raise "unknown XRM type:#{type}" unless XRM_DAMAGE_TABLES.key?(type)

    table = XRM_DAMAGE_TABLES[type]
    roll_result = table.roll(bcdice)

    lrm = type.start_with?('L')
    damage = roll_result.content
    modified_damage = lrm ? damage : (2 * damage)

    return modified_damage, roll_result.sum, lrm
  end

  @@lrmLimit = 5

  def getHitResult(count, damageFunc, tail)
    return nil unless /(\w*)(\+\d+)?>=(\d+)/ === tail

    side = Regexp.last_match(1)
    baseString = Regexp.last_match(2)
    target = Regexp.last_match(3).to_i
    base = getBaseValue(baseString)
    debug("side, base, target", side, base, target)

    partTable = getHitPart(side)

    resultTexts = []
    damages = {}
    hitCount = 0

    count.times do
      isHit, hitResult = getHitText(base, target)
      if isHit
        hitCount += 1

        damages, damageText = getDamages(damageFunc, partTable, damages)
        hitResult += damageText
      end
      resultTexts << hitResult
    end

    totalResultText = resultTexts.join("\n")

    if  totalResultText.length >= $SEND_STR_MAX
      totalResultText = "..."
    end

    totalResultText += "\n ＞ #{hitCount}回命中"
    totalResultText += " 命中箇所：" + getTotalDamage(damages) if hitCount > 0

    return totalResultText
  end

  def getBaseValue(baseString)
    base = 0
    return base if baseString.nil?

    base = parren_killer("(" + baseString + ")").to_i
    return base
  end

  def getHitPart(side)
    case side
    when /^L$/i
      ['左胴＠', '左脚', '左腕', '左腕', '左脚', '左胴', '胴中央', '右胴', '右腕', '右脚', '頭']
    when /^C$/i, '', nil
      ['胴中央＠', '右腕', '右腕', '右脚', '右胴', '胴中央', '左胴', '左脚', '左腕', '左腕', '頭']
    when /^R$/i
      ['右胴＠', '右脚', '右腕', '右腕', '右脚', '右胴', '胴中央', '左胴', '左腕', '左脚', '頭']

    when /^LU$/i
      ['左胴', '左胴', '胴中央', '左腕', '左腕', '頭']
    when /^CU$/i
      ['左腕', '左胴', '胴中央', '右胴', '右腕', '頭']
    when /^RU$/i
      ['右胴', '右胴', '胴中央', '右腕', '右腕', '頭']

    when /^LL$/i
      ['左脚', '左脚', '左脚', '左脚', '左脚', '左脚']
    when /^CL$/i
      ['右脚', '右脚', '右脚', '左脚', '左脚', '左脚']
    when /^RL$/i
      ['右脚', '右脚', '右脚', '右脚', '右脚', '右脚']
    else
      raise "unknown hit part side :#{side}"
    end
  end

  def getHitText(base, target)
    dice1, = roll(1, 6)
    dice2, = roll(1, 6)
    total = dice1 + dice2 + base
    isHit = (total >= target)
    baseString = (base > 0 ? "+#{base}" : "")

    result = "#{total}[#{dice1},#{dice2}#{baseString}]>=#{target} ＞ "

    if isHit
      result += "命中 ＞ "
    else
      result += "外れ"
    end

    return isHit, result
  end

  def getDamages(damageFunc, partTable, damages)
    resultText = ''
    damage, dice, isLrm = damageFunc.call()

    damagePartCount = 1
    if isLrm
      damagePartCount = (1.0 * damage / @@lrmLimit).ceil
      resultText += "[#{dice}] #{damage}点"
    end

    damagePartCount.times do |damageIndex|
      currentDamage, damageText = getDamageInfo(dice, damage, isLrm, damageIndex)

      text, part, criticalText = getHitResultOne(damageText, partTable)
      resultText += " " if isLrm
      resultText += text

      if damages[part].nil?
        damages[part] = {
          :partDamages => [],
          :criticals => [],
        }
      end

      damages[part][:partDamages] << currentDamage
      damages[part][:criticals] << criticalText unless criticalText.empty?
    end

    return damages, resultText
  end

  def getDamageInfo(dice, damage, isLrm, index)
    return damage, damage.to_s if dice.nil?
    return damage, "[#{dice}] #{damage}" unless isLrm

    currentDamage = damage - (@@lrmLimit * index)
    if currentDamage > @@lrmLimit
      currentDamage = @@lrmLimit
    end

    return currentDamage, currentDamage.to_s
  end

  def getTotalDamage(damages)
    parts = ['頭',
             '胴中央',
             '右胴',
             '左胴',
             '右脚',
             '左脚',
             '右腕',
             '左腕',]

    allDamage = 0
    damageTexts = []
    parts.each do |part|
      damageInfo = damages.delete(part)
      next if  damageInfo.nil?

      damage = damageInfo[:partDamages].inject(0) { |sum, i| sum + i }
      allDamage += damage
      damageCount = damageInfo[:partDamages].size
      criticals = damageInfo[:criticals]

      text = ""
      text += "#{part}(#{damageCount}回) #{damage}点"
      text += " #{criticals.join(' ')}" unless criticals.empty?

      damageTexts << text
    end

    unless damages.empty?
      raise "damages rest!! #{damages.inspect()}"
    end

    result = damageTexts.join(" ／ ")
    result += " ＞ 合計ダメージ #{allDamage}点"

    return result
  end

  def getHitResultOne(damageText, partTable)
    part, value = getPart(partTable)

    result = ""
    result += "[#{value}] #{part.gsub(/＠/, '（致命的命中）')} #{damageText}点"
    debug('result', result)

    index = part.index('＠')
    critical_hit_may_occur = !index.nil?
    debug('critical_hit_may_occur', critical_hit_may_occur)

    part = part.gsub(/＠/, '')

    critical_hit_occurred = false
    criticalText = ''
    if critical_hit_may_occur
      ct_result = TABLES['CT'].roll(bcdice)

      critical_hit_occurred = ct_result.sum > NO_CRITICAL_HIT_LIMIT
      if critical_hit_occurred
        criticalText = ct_result.content
      end

      result += " ＞ [#{ct_result.sum}] #{ct_result.content}"
    end

    return result, part, criticalText
  end

  def getPart(partTable)
    diceCount = 2
    if partTable.length == 6
      diceCount = 1
    end

    part, value = get_table_by_nD6(partTable, diceCount)
    return part, value
  end

  def getCheckDieResult(damage)
    if damage >= 6
      return "死亡"
    end

    table = [[1,  3],
             [2,  5],
             [3,  7],
             [4,  10],
             [5,  11]]

    target = get_table_by_number(damage, table, nil)

    dice1, = roll(1, 6)
    dice2, = roll(1, 6)
    total = dice1 + dice2
    result = total >= target ? "成功" : "失敗"
    text = "#{total}[#{dice1},#{dice2}]>=#{target} ＞ #{result}"

    return text
  end

  TABLES = {
    'CT' => SparseTable.new(
      '致命的命中表',
      '2D6',
      [
        [NO_CRITICAL_HIT_LIMIT, '致命的命中はなかった'],
        [ 9, '1箇所の致命的命中'],
        [11, '2箇所の致命的命中'],
        [12, 'その部位が吹き飛ぶ（腕、脚、頭）または3箇所の致命的命中（胴）'],
      ]
    ),
    'DW' => Table.new(
      '転倒後の向き表',
      '1D6',
      [
        '同じ（前面から転倒） 正面／背面',
        '1ヘクスサイド右（側面から転倒） 右側面',
        '2ヘクスサイド右（側面から転倒） 右側面',
        '180度逆（背面から転倒） 正面／背面',
        '2ヘクスサイド左（側面から転倒） 左側面',
        '1ヘクスサイド左（側面から転倒） 左側面',
      ]
    )
  }.freeze

  # ミサイルダメージ表
  XRM_DAMAGE_TABLES = {
    'SRM2' => SparseTable.new(
      'SRM2ダメージ表',
      '2D6',
      [
        [ 7, 1],
        [12, 2],
      ]
    ),
    'SRM4' => SparseTable.new(
      'SRM4ダメージ表',
      '2D6',
      [
        [ 2, 1],
        [ 6, 2],
        [10, 3],
        [12, 4],
      ]
    ),
    'SRM6' => SparseTable.new(
      'SRM6ダメージ表',
      '2D6',
      [
        [ 3, 2],
        [ 5, 3],
        [ 8, 4],
        [10, 5],
        [12, 6],
      ]
    ),
    'LRM5' => SparseTable.new(
      'LRM5ダメージ表',
      '2D6',
      [
        [ 2, 1],
        [ 4, 2],
        [ 8, 3],
        [10, 4],
        [12, 5],
      ]
    ),
    'LRM10' => SparseTable.new(
      'LRM10ダメージ表',
      '2D6',
      [
        [ 3,  3],
        [ 4,  4],
        [ 8,  6],
        [10,  8],
        [12, 10],
      ]
    ),
    'LRM15' => SparseTable.new(
      'LRM15ダメージ表',
      '2D6',
      [
        [ 3,  5],
        [ 4,  6],
        [ 8,  9],
        [10, 12],
        [12, 15],
      ]
    ),
    'LRM20' => SparseTable.new(
      'LRM20ダメージ表',
      '2D6',
      [
        [ 3,  6],
        [ 4,  9],
        [ 8, 12],
        [10, 16],
        [12, 20],
      ]
    )
  }.freeze
end
