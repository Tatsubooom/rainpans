class_name Journal
## 雨の手帳: short lines that surface once at quiet milestones.
## Each entry: id, condition (evaluated by `reached`), text.

const ENTRIES := [
	["first_hit", "最初のひと粒が、缶の底で鳴った。"],
	["ten_hits", "雨の音は、ひと粒ずつ、ぜんぶ違う。"],
	["bucket", "バケツは少しだけ低い声で返事をする。"],
	["drip", "ひさしの縁から、同じ間隔でしずくが落ちる。時計みたいに。"],
	["helmet", "ヘルメットの持ち主のことは、考えないことにした。"],
	["harmony3", "三つの音が重なると、それはもう音楽だった。"],
	["pot", "鍋は、湯気よりも雨のほうが似合うのかもしれない。"],
	["night", "夜が深くなると、雨の音が近くなる。"],
	["bottle", "瓶の口に雨が当たると、遠くで鈴が鳴ったように聞こえた。"],
	["rain5", "空がようやく、本気で泣きはじめた。"],
	["full", "ここにはもう置けない。でも、並べかえることはできる。"],
	["drum", "ドラム缶の低い音は、足の裏から聞こえる。"],
	["rail", "線路の先は途切れている。それでも雨は向こうまで降っている。"],
	["kettle", "やかんの注ぎ口が、小さく口笛を吹いた。"],
	["pipes", "風が吹くたびに、パイプが勝手に歌いだす。"],
	["canal", "地下には雨が届かない。届くのは、穴から落ちてくるぶんだけ。"],
	["plate", "鉄の板が鳴ると、しばらく世界が黙る。"],
	["tarp", "いちばん低い音を敷くと、ほかの音が浮かんで聞こえた。"],
	["dawn", "雨のまま、朝が来た。"],
	["all", "集めた音はどこにも残らない。だから、ずっと聴いていられる。"],
	["ending", "雨上がりを、一度だけ見た。"],
]


static func text(id: String) -> String:
	for e in ENTRIES:
		if e[0] == id:
			return e[1]
	return ""


## Returns ids whose conditions now hold.
static func reached(hits: int) -> Array:
	var out := []
	var g = Engine.get_main_loop().root.get_node("/root/Game")
	if hits >= 1:
		out.append("first_hit")
	if hits >= 10:
		out.append("ten_hits")
	for id in ["bucket", "helmet", "pot", "bottle", "drum", "kettle", "pipes", "plate", "tarp"]:
		if g.owned.get(id, 0) > 0:
			out.append(id)
	if g.level("drip") > 0:
		out.append("drip")
	if g.distinct_placed() >= 3:
		out.append("harmony3")
	if g.level("rain") >= 5:
		out.append("rain5")
	if g.area_full():
		out.append("full")
	if "rail" in g.areas_open:
		out.append("rail")
	if "canal" in g.areas_open:
		out.append("canal")
	if g.level("time") > 0:
		var ph := fmod(g.play_time / 1440.0, 1.0)
		if ph > 0.3 and ph < 0.6:
			out.append("night")
		if ph > 0.76 and ph < 0.86:
			out.append("dawn")
	if g.owned.get("tarp", 0) > 0 and "canal" in g.areas_open and g.level("rain") >= 10:
		out.append("all")
	return out
