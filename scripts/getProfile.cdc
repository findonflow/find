import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String) :  Profile.UserReport? {
	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return nil}
	let address = resolveAddress!

	return getAccount(address)
		.getCapability<&{Profile.Public}>(Profile.publicPath)
		.borrow()?.asReport()
}
