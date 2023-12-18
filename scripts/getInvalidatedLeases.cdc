import FIND from "../contracts/FIND.cdc"

pub fun main(user: Address) : [String] {
	let finLeases= getAuthAccount(user).borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
	return finLeases.getInvalidatedLeases()
}
