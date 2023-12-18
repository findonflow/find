import MetadataViews from  "../contracts/standard/MetadataViews.cdc"
import PartyFavorz from "../contracts/PartyFavorz.cdc"

access(all) main(users:[Address]) : AnyStruct {

	let viewType= Type<MetadataViews.Display>()

	let addressNames : {Address : [String]} = {}
	let addresses:  {Address: [String] }={}
	for  user in users {
		let account=getAccount(user)
		let aeraCap = account.getCapability<&PartyFavorz.Collection{ViewResolver.ResolverCollection}>(
			PartyFavorz.CollectionPublicPath
		)
		if !aeraCap.check() {
			continue
		}
		let ref = aeraCap.borrow()!
		let names : [String] = []
		for id in ref.getIDs() {
			let resolver=ref.borrowViewResolver(id: id)
			if let display = MetadataViews.getDisplay(resolver) {
				names.append(display.name)
			}
		}

		addressNames[user]=names
	}
	return addressNames
}
