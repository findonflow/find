import "Profile"
import "FIND"

access(all) fun main(user: String) :  Profile.UserReport? {
	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return nil}
	let address = resolveAddress!
	let account = getAccount(address)
	if account.balance == 0.0 {
		return nil
	}

	var profileReport = account
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
