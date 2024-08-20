import "NonFungibleToken"
import "MetadataViews"
import "FIND"

//Fetch a single view from a nft on a given path
access(all) fun main(user: Address, path:PublicPath, id: UInt64, identifier: String) : AnyStruct? {

	let address = user
	let account=getAccount(address)

	let collection= getAccount(address).getCapability(path).borrow<&{ViewResolver.ResolverCollection}>()!

	let nft=collection.borrowViewResolver(id: id)

	return nft.resolveView(CompositeType(identifier)!)

}

