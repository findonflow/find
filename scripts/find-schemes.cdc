

import Profile from "../contracts/Profile.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"

pub fun main(address: Address, path: String, id:UInt64) : [String] {

	let account=getAccount(address)

	let collections= getAccount(address)
	.getCapability(Profile.publicPath)
	.borrow<&{Profile.Public}>()!
	.getCollections()

	for col in collections {
		if col.name == path && col.type == Type<&{TypedMetadata.ViewResolverCollection}>() {
			let cap = col.collection.borrow<&{TypedMetadata.ViewResolverCollection}>()! as &{TypedMetadata.ViewResolverCollection}
			let nft=cap.borrowViewResolver(id: id)
			let views=nft.getViews()
			var viewIdentifiers : [String] = []
			for v in views {
				viewIdentifiers.append(v.identifier)
			}
			return viewIdentifiers
		}
	}
	return []
}

