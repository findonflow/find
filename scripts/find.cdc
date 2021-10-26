import TypedMetadata from "../contracts/TypedMetadata.cdc"
import Profile from "../contracts/Profile.cdc"


pub fun main(address: Address, path: String, id: UInt64, identifier: String) : AnyStruct? {

	let collections= getAccount(address).getCapability(Profile.publicPath)
	.borrow<&{Profile.Public}>()!
	.getCollections()

	for col in collections {
		if col.name == path && col.type == Type<&{TypedMetadata.ViewResolverCollection}>() {
			let cap = col.collection.borrow<&{TypedMetadata.ViewResolverCollection}>()! as &{TypedMetadata.ViewResolverCollection}
			let nft=cap.borrowViewResolver(id: id)
			for v in nft.getViews() {
				if v.identifier== identifier {
					return nft.resolveView(v)
				}
			}
		}
	}
	return nil
}

