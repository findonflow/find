import "FIND"
import "Profile"

transaction(name:String, description: String, avatar: String, tags:[String], allowStoringFollowers: Bool, linkTitles : {String: String}, linkTypes: {String:String}, linkUrls : {String:String}, removeLinks : [String]) {
	
	let profile : &Profile.User

	prepare(account: auth(BorrowValue, StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {

		self.profile =account.storage.borrow<&Profile.User>(from:Profile.storagePath) ?? panic("You do not have a profile set up, initialize the user first")

		let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection!.check() {
			account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)

		}

	}

	execute{
		self.profile.setName(name)
		self.profile.setDescription(description)
		self.profile.setAvatar(avatar)
		self.profile.setTags(tags)

		for link in removeLinks {
			self.profile.removeLink(link)
		}

		for titleName in linkTitles.keys {
			let title=linkTitles[titleName]!
			let url = linkUrls[titleName]!
			let type = linkTypes[titleName]!

			self.profile.addLinkWithName(name:titleName, link: Profile.Link(title: title, type: type, url: url))
		}
		self.profile.emitUpdatedEvent()
	}
}

