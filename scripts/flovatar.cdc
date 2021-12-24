import Flovatar from 0x921ea449dffec68a

pub fun main(addr: Address) : [UInt8]{

	let flovatarList= Flovatar.getFlovatars(address: addr)
	var rare:UInt8=0
	var legendary:UInt8=0
	var epic:UInt8=0
	for flovatar in flovatarList {
		rare=rare+flovatar.metadata.rareCount
		epic=epic+flovatar.metadata.epicCount
		legendary=legendary+flovatar.metadata.legendaryCount
	}

	return [rare,epic, legendary]
}
