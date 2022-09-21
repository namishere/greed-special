local mod = GreedSpecialRooms

mod.enum = {}

mod.enum.CAIN_ARCADE = RoomType.ROOM_ARCADE + 100

mod.DoorVariant = {
	BOMB = 0,
	KEY = 1, -- subtype 1 is maus door and strange door??? may be general use
	KEY2 = 2,
	BOMB2 = 3, -- also used by knife door?
	BARRED = 4,
	LOCKED = 5, -- fallback behavior for invalid variants
	UNKNOWN = 6, -- shows bars fading when entering room?
	CLOSED = 7,
	OPENED = 8
}

mod.SpecialRoom = {
	[RoomType.ROOM_ARCADE] = {variant = mod.DoorVariant.KEY, string = "arcade"},
	[RoomType.ROOM_CHALLENGE] = {variant = mod.DoorVariant.OPENED, string = "challenge"},
	[RoomType.ROOM_LIBRARY] = {variant = mod.DoorVariant.KEY, string = "library"},
	[RoomType.ROOM_SACRIFICE] = {variant = mod.DoorVariant.OPENED, string = "sacrifice"},
	[RoomType.ROOM_ISAACS] = {variant = mod.DoorVariant.BOMB2, string = "isaacs"},
	[RoomType.ROOM_BARREN] = {variant = mod.DoorVariant.BOMB2, string = "barren"},
	[RoomType.ROOM_CHEST] = {variant = mod.DoorVariant.KEY2, string = "chest"},
	[RoomType.ROOM_DICE] = {variant = mod.DoorVariant.KEY2, string = "dice"},
	[RoomType.ROOM_PLANETARIUM] = {variant = mod.DoorVariant.KEY, string = "planetarium"},

	[mod.enum.CAIN_ARCADE] = {variant = mod.DoorVariant.KEY, string = "arcade"},
}
