import FIND from "../contracts/FIND.cdc"

access(all) main(user: Address) : [String] {
	let finLeases= getAuthAccount(user).borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
	return finLeases.getInvalidatedLeases()
}
