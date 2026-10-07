class_name Visitors
extends Node
## Now and then something that is not a person passes through: a stray cat
## sheltering from the rain, an old maintenance robot still doing its rounds
## (it taps each drum to check it), a heron wading the canal, a deer that
## wandered into the glasshouse. One at a time, quietly, then gone again.
##
## Each visitor is a Visitor node placed in the y-sorted drum layer so it
## passes in front of and behind drums properly.

signal note(text: String)

## Which visitors each area can get.
const KINDS := {
	"roof": ["cat", "robot", "cat"],
	"rail": ["cat", "robot"],
	"glass": ["deer", "robot", "cat"],
	"canal": ["heron", "robot"],
}
const ARRIVE := {
	"cat": "どこからか猫が来た。雨宿りだろうか",
	"robot": "古い整備ロボットが巡回に来た",
	"heron": "鷺がひとり、水辺に降りた",
	"deer": "鹿が一頭、温室に迷いこんでいる",
}

var stage: Node
var area_id := ""
var floor_rect := Rect2()
var current: Visitor
var _wait := 0.0


func setup(st: Node, a: Dictionary, id: String) -> void:
	stage = st
	area_id = id
	floor_rect = a.floor
	_wait = randf_range(150.0, 300.0)


func _process(delta: float) -> void:
	if is_instance_valid(current):
		return
	current = null
	_wait -= delta
	if _wait <= 0.0:
		_wait = randf_range(240.0, 540.0)
		var kinds: Array = KINDS.get(area_id, ["robot"])
		spawn(kinds[randi() % kinds.size()])


## Sends a visitor in now (also the debug hook).
func spawn(kind: String, arrived := false) -> Visitor:
	if is_instance_valid(current):
		current.queue_free()
	var v := Visitor.new()
	v.kind = kind
	v.stage = stage
	v.floor_rect = floor_rect
	stage.drums_node.add_child(v)
	v.begin()
	if arrived:
		v.arrive()
	current = v
	note.emit(ARRIVE.get(kind, ""))
	return v
