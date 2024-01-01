import FIND from "../contracts/FIND.cdc"

access(all) fun main(user: Address) : [String] {
	let finLeases= getAuthAccount(user).borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
	return finLeases.getInvalidatedLeases()
}
