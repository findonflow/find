import TypedMetadata from "../contracts/TypedMetadata.cdc"
import Profile from "../contracts/Profile.cdc"


pub struct FindResult{

	pub let collection: String
	pub let id: UInt64
	pub let view: String
	pub let data: AnyStruct?

	init(collection: String, id:UInt64, view: String, data: AnyStruct?) {
		self.collection=collection
		self.id=id
		self.view=view
		self.data=data
	}
}
pub fun main(address: Address) : [FindResult] {

	var findResults :[FindResult] = []
	let collections= getAccount(address).getCapability(Profile.publicPath)
	.borrow<&{Profile.Public}>()!
	.getCollections()

	for col in collections {
		if col.type ==Type<&{TypedMetadata.ViewResolverCollection}>() {
			let name=col.name
			let vrc= col.collection.borrow<&{TypedMetadata.ViewResolverCollection}>()!
			for id in vrc.getIDs() {
				let nft=vrc.borrowViewResolver(id: id)
				for view in nft.getViews() {
					let resolved=nft.resolveView(view)
					findResults.append(FindResult(collection:name, id:id, view:view.identifier, data:resolved))
				}
			}
		}
	}
	return findResults
}

