local mod = GreedSpecialRooms

mod.enum = {}

mod.enum.CAIN_ARCADE = RoomType.ROOM_ARCADE + 100
mod.enum.VOODOO_CURSE = RoomType.ROOM_CURSE + 100

mod.enum.DOWNPOUR_EXIT = RoomType.ROOM_SECRET_EXIT
mod.enum.MINES_EXIT = RoomType.ROOM_SECRET_EXIT + 100
mod.enum.MAUSOLEUM_EXIT = RoomType.ROOM_SECRET_EXIT + 200
mod.enum.CORPSE_EXIT = RoomType.ROOM_SECRET_EXIT + 300

mod.enum.SHOP_IDX = 70
mod.enum.CURSE_IDX = 83
mod.enum.EXIT_IDX = 110

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
	[mod.enum.VOODOO_CURSE] = {variant = DoorVariant.DOOR_UNLOCKED, string = "curse"},

	[mod.enum.DOWNPOUR_EXIT] = {variant = DoorVariant.DOOR_LOCKED, string = "secretexit"},
	[mod.enum.MINES_EXIT] = {variant = DoorVariant.DOOR_LOCKED, string = "secretexit"},
	[mod.enum.MAUSOLEUM_EXIT] = {variant = DoorVariant.DOOR_LOCKED, string = "secretexit"},
}

-- ROOM GEN
mod.adjindexes = {
	[RoomShape.ROOMSHAPE_1x1] = {
		[DoorSlot.LEFT0] = -1,
		[DoorSlot.UP0] = -13,
		[DoorSlot.RIGHT0] = 1,
		[DoorSlot.DOWN0] = 13
	},
	[RoomShape.ROOMSHAPE_IH] = {
		[DoorSlot.LEFT0] = -1,
		[DoorSlot.RIGHT0] = 1
	},
	[RoomShape.ROOMSHAPE_IV] = {
		[DoorSlot.UP0] = -13,
		[DoorSlot.DOWN0] = 13
	},
	[RoomShape.ROOMSHAPE_1x2] = {
		[DoorSlot.LEFT0] = -1,
		[DoorSlot.UP0] = -13,
		[DoorSlot.RIGHT0] = 1,
		[DoorSlot.DOWN0] = 26,
		[DoorSlot.LEFT1] = 12,
		[DoorSlot.RIGHT1] = 14
	},
	[RoomShape.ROOMSHAPE_IIV] = {
		[DoorSlot.UP0] = -13,
		[DoorSlot.DOWN0] = 26
	},
	[RoomShape.ROOMSHAPE_2x1] = {
		[DoorSlot.LEFT0] = -1,
		[DoorSlot.UP0] = -13,
		[DoorSlot.RIGHT0] = 2,
		[DoorSlot.DOWN0] = 13,
		[DoorSlot.UP1] = -12,
		[DoorSlot.DOWN1] = 14
	},
	[RoomShape.ROOMSHAPE_IIH] = {
		[DoorSlot.LEFT0] = -1,
		[DoorSlot.RIGHT0] = 3
	},
	[RoomShape.ROOMSHAPE_2x2] = {
		[DoorSlot.LEFT0] = -1,
		[DoorSlot.UP0] = -13,
		[DoorSlot.RIGHT0] = 2,
		[DoorSlot.DOWN0] = 26,
		[DoorSlot.LEFT1] = 12,
		[DoorSlot.UP1] = -12,
		[DoorSlot.RIGHT1] = 15,
		[DoorSlot.DOWN1] = 27
	},
	[RoomShape.ROOMSHAPE_LTL] = {
		[DoorSlot.LEFT0] = -1,
		[DoorSlot.UP0] = -1,
		[DoorSlot.RIGHT0] = 1,
		[DoorSlot.DOWN0] = 25,
		[DoorSlot.LEFT1] = 11,
		[DoorSlot.UP1] = -13,
		[DoorSlot.RIGHT1] = 14,
		[DoorSlot.DOWN1] = 26
	},
	[RoomShape.ROOMSHAPE_LTR] = {
		[DoorSlot.LEFT0] = -1,
		[DoorSlot.UP0] = -13,
		[DoorSlot.RIGHT0] = 1,
		[DoorSlot.DOWN0] = 26,
		[DoorSlot.LEFT1] = 12,
		[DoorSlot.UP1] = 1,
		[DoorSlot.RIGHT1] = 15,
		[DoorSlot.DOWN1] = 27
	},
	[RoomShape.ROOMSHAPE_LBL] = {
		[DoorSlot.LEFT0] = -1,
		[DoorSlot.UP0] = -13,
		[DoorSlot.RIGHT0] = 2,
		[DoorSlot.DOWN0] = 13,
		[DoorSlot.LEFT1] = 13,
		[DoorSlot.UP1] = -12,
		[DoorSlot.RIGHT1] = 15,
		[DoorSlot.DOWN1] = 27
	},
	[RoomShape.ROOMSHAPE_LBR] = {
		[DoorSlot.LEFT0] = -1,
		[DoorSlot.UP0] = -13,
		[DoorSlot.RIGHT0] = 2,
		[DoorSlot.DOWN0] = 26,
		[DoorSlot.LEFT1] = 12,
		[DoorSlot.UP1] = -12,
		[DoorSlot.RIGHT1] = 14,
		[DoorSlot.DOWN1] = 14
	}
}

mod.borderrooms = {
	[DoorSlot.LEFT0] = {0, 13, 26, 39, 52, 65, 78, 91, 104, 117, 130, 143, 156},
	[DoorSlot.UP0] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
	[DoorSlot.RIGHT0] = {12, 25, 38, 51, 64, 77, 90, 103, 116, 129, 142, 155, 168},
	[DoorSlot.DOWN0] = {156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168},
	[DoorSlot.LEFT1] = {0, 13, 26, 39, 52, 65, 78, 91, 104, 117, 130, 143, 156},
	[DoorSlot.UP1] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
	[DoorSlot.RIGHT1] = {12, 25, 38, 51, 64, 77, 90, 103, 116, 129, 142, 155, 168},
	[DoorSlot.DOWN1] = {156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168}
}

mod.oppslots = {
	[DoorSlot.LEFT0] = DoorSlot.RIGHT0,
	[DoorSlot.UP0] = DoorSlot.DOWN0,
	[DoorSlot.RIGHT0] = DoorSlot.LEFT0,
	[DoorSlot.LEFT1] = DoorSlot.RIGHT0,
	[DoorSlot.DOWN0] = DoorSlot.UP0,
	[DoorSlot.UP1] = DoorSlot.DOWN0,
	[DoorSlot.RIGHT1] = DoorSlot.LEFT0,
	[DoorSlot.DOWN1] = DoorSlot.UP0
}

mod.shapeindexes = {
	[RoomShape.ROOMSHAPE_1x1] = { 0 },
	[RoomShape.ROOMSHAPE_IH] = { 0 },
	[RoomShape.ROOMSHAPE_IV] = { 0 },
	[RoomShape.ROOMSHAPE_1x2] = { 0, 13 },
	[RoomShape.ROOMSHAPE_IIV] = { 0, 13 },
	[RoomShape.ROOMSHAPE_2x1] = { 0, 1 },
	[RoomShape.ROOMSHAPE_IIH] = { 0, 1 },
	[RoomShape.ROOMSHAPE_2x2] = { 0, 1, 13, 14 },
	[RoomShape.ROOMSHAPE_LTL] = { 1, 13, 14 },
	[RoomShape.ROOMSHAPE_LTR] = { 0, 13, 14 },
	[RoomShape.ROOMSHAPE_LBL] = { 0, 1, 14 },
	[RoomShape.ROOMSHAPE_LBR] = { 0, 1, 13 },
}
-- END OF ROOM GEN
