import Profile from "../contracts/Profile.cdc"

//Check the status of a fin user
pub fun main(address: Address) :  Profile.UserProfile? {
	return getAccount(address)
		.getCapability<&{Profile.Public}>(Profile.publicPath)
		.borrow()?.asProfile()
}
