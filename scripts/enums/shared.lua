local mod = GreedSpecialRooms

mod.enum = {}

mod.enum.CAIN_ARCADE = RoomType.ROOM_ARCADE + 100

mod.SpecialRoom = {
	[RoomType.ROOM_ARCADE] = {variant = DoorVariant.DOOR_LOCKED, string = "arcade"},
	[RoomType.ROOM_CHALLENGE] = {variant = DoorVariant.DOOR_UNLOCKED, string = "challenge"},
	[RoomType.ROOM_LIBRARY] = {variant = DoorVariant.DOOR_LOCKED, string = "library"},
	[RoomType.ROOM_SACRIFICE] = {variant = DoorVariant.DOOR_UNLOCKED, string = "sacrifice"},
	[RoomType.ROOM_ISAACS] = {variant = DoorVariant.DOOR_LOCKED_CRACKED, string = "isaacs"},
	[RoomType.ROOM_BARREN] = {variant = DoorVariant.DOOR_LOCKED_CRACKED, string = "barren"},
	[RoomType.ROOM_CHEST] = {variant = DoorVariant.DOOR_LOCKED_DOUBLE, string = "chest"},
	[RoomType.ROOM_DICE] = {variant = DoorVariant.DOOR_LOCKED_DOUBLE, string = "dice"},
	[RoomType.ROOM_PLANETARIUM] = {variant = DoorVariant.DOOR_LOCKED, string = "planetarium"},

	[mod.enum.CAIN_ARCADE] = {variant = DoorVariant.DOOR_LOCKED, string = "arcade"},
}
