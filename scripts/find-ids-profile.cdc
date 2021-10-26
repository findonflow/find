import Profile from "../contracts/Profile.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"

pub fun main(address: Address, path: String) : [UInt64] {

	let account=getAccount(address)

	let collections= getAccount(address)
	.getCapability(Profile.publicPath)
	.borrow<&{Profile.Public}>()!
	.getCollections()

	for col in collections {
		if col.name == path && col.type == Type<&{TypedMetadata.ViewResolverCollection}>() {
			let cap = col.collection.borrow<&{TypedMetadata.ViewResolverCollection}>()! as &{TypedMetadata.ViewResolverCollection}
			return cap.getIDs()
		}
	}
	return []
}

