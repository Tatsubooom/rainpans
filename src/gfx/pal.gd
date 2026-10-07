class_name Pal
## Fixed palette. Everything in the world is painted from these swatches so the
## scene reads as one piece: cold rain blues, concrete, rust and lamp amber.
## Ramps are hue-shifted (after slynyrd's palette notes): shadows lean toward
## blue-violet and are a little more saturated, highlights lean warm and
## desaturate, so neighbouring steps differ in hue as well as value.

# night / rain blues (dark -> light)
static var INK := Color("07090e")
static var NIGHT0 := Color("0d1019")
static var NIGHT1 := Color("121826")
static var NIGHT2 := Color("172034")
static var NIGHT3 := Color("1f2b43")
static var NIGHT4 := Color("293954")
static var FOG0 := Color("384964")
static var FOG1 := Color("4e6079")
static var FOG2 := Color("697c93")
static var RAIN := Color("92a5b8")
static var RAIN_HI := Color("c6d3e0")

# concrete
static var CON0 := Color("15151f")
static var CON1 := Color("1e2029")
static var CON2 := Color("292c35")
static var CON3 := Color("383b44")
static var CON4 := Color("4c4e56")
static var CON5 := Color("6a6869")
static var CON6 := Color("85837e")

# rust / earth
static var RUST0 := Color("26141a")
static var RUST1 := Color("40211c")
static var RUST2 := Color("5e331e")
static var RUST3 := Color("8a4c29")
static var RUST4 := Color("c07a3e")

# moss
static var MOSS0 := Color("142026")
static var MOSS1 := Color("23352a")
static var MOSS2 := Color("37503a")
static var MOSS3 := Color("6a7d4a")

# lamp light (bright -> deep)
static var LAMP0 := Color("fff1c9")
static var LAMP1 := Color("ffd68a")
static var LAMP2 := Color("f2a65a")
static var LAMP3 := Color("d1743a")
static var LAMP4 := Color("8f4527")

static var BONE := Color("e8e1d2")

# extras for finer detail
static var WET := Color("2b3546") # rain-dark concrete with a blue sheen
static var WOOD0 := Color("2a1614")
static var WOOD1 := Color("48271a")
static var WOOD2 := Color("644027")
static var WOOD3 := Color("765f42")
static var CLOTH0 := Color("392b3c")
static var CLOTH1 := Color("644264")
static var CLOTH2 := Color("877280")
