import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String) :  Profile.UserReport? {
	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return nil}
	let address = resolveAddress!

	var profileReport = getAccount(address)
		.getCapability<&{Profile.Public}>(Profile.publicPath)
		.borrow()?.asReport()

	if profileReport != nil && profileReport!.findName != FIND.reverseLookup(address) {
		profileReport = Profile.UserReport(
			findName: "",
			address: profileReport!.address,
			name: profileReport!.name,
			gender: profileReport!.gender,
			description: profileReport!.description,
			tags: profileReport!.tags,
			avatar: profileReport!.avatar,
			links: profileReport!.links,
			wallets: profileReport!.wallets, 
			following: profileReport!.following,
			followers: profileReport!.followers,
			allowStoringFollowers: profileReport!.allowStoringFollowers,
			createdAt: profileReport!.createdAt
		)
	}

	return profileReport


}
