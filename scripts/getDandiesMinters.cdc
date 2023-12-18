import Dandy from "../contracts/Dandy.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) main(user: String) : [String] {
	let address = FIND.resolve(user)
	if address == nil {
		return []
	}
	let account = getAccount(address!)
	if account.balance == 0.0 {
		return []
	}
	let cap = account.getCapability<&Dandy.Collection{Dandy.CollectionPublic}>(Dandy.CollectionPublicPath)
	let ref = cap.borrow() ?? panic("Cannot borrow reference to Dandy Collection. Account address : ".concat(address!.toString()))

	return ref.getMinters()
}