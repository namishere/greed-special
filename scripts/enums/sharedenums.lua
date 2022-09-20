local mod = GreedSpecialRooms

mod.SpecialRoom = {
	[RoomType.ROOM_ARCADE] = {variant = DoorVariant.KEY, string = "arcade"},
	[RoomType.ROOM_CHALLENGE] = {variant = DoorVariant.OPENED, string = "challenge"},
	[RoomType.ROOM_LIBRARY] = {variant = DoorVariant.KEY, string = "library"},
	[RoomType.ROOM_SACRIFICE] = {variant = DoorVariant.OPENED, string = "sacrifice"},
	[RoomType.ROOM_ISAACS] = {variant = DoorVariant.BOMB2, string = "isaacs"},
	[RoomType.ROOM_BARREN] = {variant = DoorVariant.BOMB2, string = "barren"},
	[RoomType.ROOM_CHEST] = {variant = DoorVariant.KEY2, string = "chest"},
	[RoomType.ROOM_DICE] = {variant = DoorVariant.KEY2, string = "dice"},
	[RoomType.ROOM_PLANETARIUM] = {variant = DoorVariant.KEY, string = "planetarium"},

	[CAIN_ARCADE] = {variant = DoorVariant.KEY, string = "arcade"},
}
