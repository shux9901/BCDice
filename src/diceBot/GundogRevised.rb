# -*- coding: utf-8 -*-

require 'diceBot/Gundog'

class GundogRevised < DiceBot
  setPrefixes(['(.DPT|.FT)(\+|\-)?\d*'])

  def gameName
    'ガンドッグ・リヴァイズド'
  end

  def gameType
    "GundogRevised"
  end

  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
失敗、成功、クリティカル、ファンブルとロールの達成値の自動判定を行います。
nD9ロールも対応。
・ダメージペナルティ表　　(～DPTx) (x:修正)
　射撃(SDPT)、格闘(MDPT)、車両(VDPT)、汎用(GDPT)の各表を引くことが出来ます。
　修正を後ろに書くことも出来ます。
・ファンブル表　　　　　　(～FTx)  (x:修正)
　射撃(SFT)、格闘(MFT)、投擲(TFT)の各表を引くことが出来ます。
　修正を後ろに書くことも出来ます。
INFO_MESSAGE_TEXT
  end

  # ---- 以降、Gundog.rbよりほぼコピペ（絶対成功→ベアリーに用語変更対応の為、継承だと不都合）
  # ゲーム別成功度判定(1d100)
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)
    return '' unless signOfInequality == "<="

    if total_n >= 100
      return " ＞ ファンブル"
    end

    if total_n <= 1
      return " ＞ ベアリー(達成値1+SL)"
    end

    if total_n <= diff
      dig10 = (total_n / 10).to_i
      dig1 = total_n - dig10 * 10
      dig10 = 0 if dig10 >= 10
      dig1 = 0 if dig1 >= 10 # 条件的にはあり得ない(笑

      if dig1 <= 0
        return " ＞ クリティカル(達成値20+SL)"
      end

      return " ＞ 成功(達成値#{(dig10 + dig1)}+SL)"
    end

    return " ＞ 失敗"
  end

  def isD9
    true
  end
  # ---- コピペ分、ここまで

  def rollDiceCommand(command)
    string = command.upcase

    table = []
    ttype = ""
    type = ""
    dice = 0
    mod = 0

    # ダメージペナルティ表
    if /(\w)DPT([\+\-\d]*)/i =~ string
      ttype = 'ダメージペナルティー'
      head = $1
      mod = parren_killer("(0#{$2})").to_i if $2

      type, table = getDamageTypeAndTable(head)
    end

    # ファンブル表
    if /(\w)FT([\+\-\d]*)/i =~ string
      ttype = 'ファンブル'
      head = $1
      mod = parren_killer("(0#{$2})").to_i if $2

      type, table = getFumbleTypeAndTable(head)
    end

    return '1' if  type.empty?

    dice, diceText = roll(2, 10)

    dice = mod
    diceArray = diceText.split(/,/).collect{|i|i.to_i}
    diceArray.each do |i|
      dice += i if  i < 10
    end
    diceOriginalText = dice
    dice = 0 if dice < 0
    dice = 18 if dice > 18

    output = "#{type}#{ttype}表[#{diceOriginalText}] ＞ #{table[dice]}"

    return output
  end

  def getDamageTypeAndTable(head)
    case head
    when "S"
      type = '射撃'
      # 射撃ダメージペナルティー表
      table = [
        '対象は[死亡]', #0
        '[追加D]4D6/[出血]2D6/[重傷]-40％/[朦朧判定]15',    #1
        '[追加D]3D6/[出血]2D6/[重傷]-30％/[朦朧判定]14',    #2
        '[追加D]3D6/[出血]2D6/[重傷]-30％/[朦朧判定]13',    #3
        '[追加D]3D6/[出血]1D6/[重傷]-20％/[朦朧判定]12',    #4
        '[追加D]2D6/[出血]1D6/[重傷]-20％/[朦朧判定]11',    #5
        '[追加D]2D6/[軽傷]-20％/[朦朧判定]11',              #6
        '[追加D]2D6/[軽傷]-20％/[朦朧判定]10',              #7
        '[追加D]2D6/[軽傷]-20％/[朦朧判定]8',               #8
        '[追加D]2D6/[軽傷]-20％/[朦朧判定]6',               #9
        '[追加D]2D6/[軽傷]-10％/[朦朧判定]4',               #10
        '[追加D]2D6/[軽傷]-20％',                           #11
        '[追加D]1D6/[軽傷]-20％',                           #12
        '[追加D]1D6/[軽傷]-10％',                           #13
        '[ショック]-20％',                                  #14
        '[ショック]-10％',                                  #15
        '[不安定]', #16
        '手に持った武器を落とす。複数ある場合はランダム', #17
        'ペナルティー無し', #18
      ]

    when "M"
      type = '格闘'
      # 格闘ダメージペナルティー表
      table = [
        '対象は[死亡]', #0
        '[追加D]4D6/[出血]2D6/[重傷]-40％/[朦朧判定]15',    #1
        '[追加D]3D6/[出血]2D6/[重傷]-30％/[朦朧判定]14',    #2
        '[追加D]3D6/[出血]1D6/[重傷]-20％/[朦朧判定]14/[不安定]', #3
        '[追加D]2D6/[出血]1D6/[重傷]-20％/[朦朧判定]14', #4
        '[追加D]2D6/[重傷]-20％/[朦朧判定]12/[不安定]', #5
        '[追加D]2D6/[軽傷]-20％/[朦朧判定]11',              #6
        '[追加D]2D6/[軽傷]-20％/[朦朧判定]10',              #7
        '[追加D]2D6/[軽傷]-20％/[朦朧判定]8',               #8
        '[追加D]2D6/[軽傷]-20％/[朦朧判定]6',               #9
        '[追加D]1D6/[軽傷]-20％/[朦朧判定]6',               #10
        '[追加D]1D6/[軽傷]-10％/[朦朧判定]6',               #11
        '[追加D]1D6/[軽傷]-10％/[不安定]', #12
        '[追加D]1D6/[軽傷]-10％',                           #13
        '[ショック]-20％',                                  #14
        '[ショック]-10％',                                  #15
        '[不安定]', #16
        '手に持った武器を落とす。複数ある場合はランダム', #17
        'ペナルティー無し', #18
      ]

    when "V"
      type = '車両'
      # 車両ダメージペナルティー表
      table = [
        '[クラッシュ]する。[チェイス]から除外', #0
        '[車両D]4D6/[乗員D]3D6/[操作性]-40%/[スピン判定]',  #1
        '[車両D]3D6/[乗員D]3D6/[操作性]-30%/[スピン判定]',  #2
        '[乗員D]3D6/[操作性]-20%/[スピン判定]',             #3
        '[乗員D]3D6/[操作性]-20%/[スピン判定]',             #4
        '[乗員D]3D6/[操作性]-10%/[スピン判定]',             #5
        '[乗員D]3D6/[操作性]-10%/[スピン判定]',             #6
        '[乗員D]2D6/[スピード]-2/[スピン判定]',             #7
        '[乗員D]2D6/[スピード]-2/[スピン判定]',             #8
        '[乗員D]2D6/[操縦判定]-20%/[スピン判定]',           #9
        '[乗員D]2D6/[操縦判定]-20%/[スピン判定]',           #10
        '[乗員D]2D6/[操縦判定]-20%',                        #11
        '[乗員D]2D6/[操縦判定]-20%',                        #12
        '[乗員D]1D6/[操縦判定]-20%',                        #13
        '[乗員D]1D6/[操縦判定]-10%',                        #14
        '攻撃が乗員をかすめる。ランダムな乗員1人に[ショック]-20％', #15
        '攻撃が乗員に当たりかける。ランダムな乗員1人に[ショック]-10％', #16
        '車両が蛇行。乗員全員は〈運動〉判定。失敗で[不安定]', #17
        'ペナルティー無し', #18
      ]

    when "G"
      type = '汎用'
      # 汎用ダメージペナルティー表
      table = [
        '対象は[死亡]', #0
        '[追加D]4D6/[出血]2D6/[重傷]-40％/[朦朧判定]15',    #1
        '[追加D]3D6/[出血]2D6/[重傷]-30％/[朦朧判定]14',    #2
        '[追加D]2D6/[出血]1D6/[重傷]-30％/[朦朧判定]13/[不安定]', #3
        '[追加D]2D6/[出血]1D6/[重傷]-30％/[朦朧判定]12', #4
        '[追加D]2D6/[重傷]-20％/[朦朧判定]12/[不安定]', #5
        '[追加D]1D6/[重傷]-20％/[朦朧判定]11',              #6
        '[追加D]1D6/[軽傷]-30％/[朦朧判定]10',              #7
        '[追加D]1D6/[軽傷]-30％/[朦朧判定]8',               #8
        '[追加D]1D6/[軽傷]-30％/[朦朧判定]6',               #9
        '[追加D]1D6/[軽傷]-20％/[朦朧判定]6',               #10
        '[軽傷]-20％/[朦朧判定]6', #11
        '[軽傷]-20％/[不安定]', #12
        '[軽傷]-20％',                                      #13
        '[軽傷]-10％',                                      #14
        '[ショック]-20％' , #15
        '[ショック]-10％', #16
        '[不安定]', #17
        'ペナルティー無し', #18
      ]
    else
      head = "S" # 間違ったら射撃扱い
      type, table = getDamageTypeAndTable(head)
    end

    return type, table
  end

  def getFumbleTypeAndTable(head)
    case head
    when "S"
      type = '射撃'
      # 射撃ファンブル表
      table = [
        '銃器が暴発、自分に命中。[貫通D]。武装喪失', #0
        '銃器が暴発、自分に命中。[非貫通D]。武装喪失', #1
        '誤射。射線に最も近い味方に命中。[貫通D]', #2
        '誤射。射線に最も近い味方に命中。[非貫通D]', #3
        '銃器が完全に故障。直せない', #4
        '故障。30分かけて〈メカニック〉判定に成功するまで使用不可。', #5
        '故障。〈メカニック〉-20％の判定に成功するまで使用不可。', #6
        '故障。〈メカニック〉判定に成功するまで射撃不可', #7
        '作動不良。[アイテム使用]を2回行って修理するまで射撃不可', #8
        '作動不良。[アイテム使用]を行って修理するまで射撃不可', #9
        '足がもつれて倒れる。[転倒]', #10
        '無理な射撃姿勢で腕を痛める。[軽傷]-20％', #11
        '無理な射撃姿勢でどこかの筋を痛める。[軽傷]-10％', #12
        '武装を落とす。スリング（肩ひも）も切れる', #13
        '武装を落とす。スリング（肩ひも）があれば落とさない', #14
        '排莢された薬莢が服の中に。[ショック]-20％', #15
        '排莢された薬莢が顔に当たる。[ショック]-10％', #16
        '薬莢を踏んで態勢を崩す。[不安定]', #17
        'ペナルティー無し', #18
      ]
    when "M"
      type = '格闘'
      # 格闘ファンブル表
      table = [
        '自分に命中。[貫通D]', #0
        '自分に命中。[非貫通D]', #1
        '最も近い味方（射程内にいなければ自分）に[貫通D]', #2
        '最も近い味方（射程内にいなければ自分）に[非貫通D]', #3
        '頭を強く打ちつける。[朦朧]', #4
        '武装が壊れる。直せない。[格闘タイプ]なら[重傷]-20％', #5
        '武装がすっぽ抜ける。グレネードの誤差で落下先を決定', #6
        '武装が損傷。30分かけて〈手先〉判定に成功するまで使用不可。[格闘タイプ]なら[重傷]-10％', #7
        '武装がガタつく。〈手先〉判定（[格闘タイプ]なら〈強靭〉）に成功するまで使用不可。', #8
        '武装に違和感。[アイテム使用]を行って調整するまで、命中率-20％', #9
        '足がもつれる。[転倒]', #10
        '足がつる。2[ラウンド]の間、移動距離1/2', #11
        '無理な体勢で腕（あるいは脚）を痛める。[軽傷]-20％',   #12
        '無理な体勢でどこかの筋を痛める。[軽傷]-10％',      #13
        '武装を落とす', #14
        '武装で自分が負傷。[ショック]-20％', #15
        '武装の扱いを間違える。[ショック]-10％', #16
        '攻撃を避けられて体勢を崩す。[不安定]', #17
        'ペナルティー無し', #18
      ]
    when "T"
      type = '投擲'
      # 投擲ファンブル表
      table = [
        '勢いをつけすぎて転倒し、頭を打つ。[気絶]',         #0
        '自分に命中。（手榴弾なら自分の足元に落ちる）[貫通D]',   #1
        '自分に命中。（手榴弾なら自分の足元に落ちる）[非貫通D]', #2
        '暴投。射線に最も近い味方に命中。[貫通D]。手榴弾なら新たな中心点からさらに誤差が生じる', #3
        '暴投。射線に最も近い味方に命中。[非貫通D]。手榴弾なら新たな中心点からさらに誤差が生じる', #4
        '頭を強く打ちつける。[朦朧]', #5
        '肩の筋肉断裂。この腕を使う判定に、[重傷]-20％', #6
        'ヒジの筋肉断裂。この腕を使う判定に、[重傷]-10％', #7
        '肩の筋をひどく痛める。〈医療〉判定に成功するまで、この腕を使う判定に-20％', #8
        '肩の筋を痛める。[行動]を使って休めるまで、この腕を使う判定に-20％', #9
        '腰を痛める。[軽傷]-30％', #10
        '足がもつれて倒れる。[転倒]', #11
        '足がつる。2[ラウンド]の間、移動距離1/2', #12
        '無理な投擲体勢で腕（あるいは脚）を痛める。[軽傷]-20％', #13
        '無理な投擲体勢でどこかの筋を痛める。[軽傷]-10％', #14
        '肩に違和感。[ショック]-20％', #15
        'ヒジに違和感。[ショック]-10％', #16
        'つまずいて姿勢を崩す。[不安定]', #17
        'ペナルティー無し', #18
      ]
    else
      head = "S" # 間違ったら射撃扱い
      type, table = getFumbleTypeAndTable(head)
    end

    return type, table
  end
end
