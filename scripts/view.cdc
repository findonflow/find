import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

//Fetch a single view from a nft on a given path
pub fun main(user: Address, path:PublicPath, id: UInt64, identifier: String) : AnyStruct? {

	let address = user
	let account=getAccount(address)

	let collection= getAccount(address).getCapability(path).borrow<&{ViewResolver.ResolverCollection}>()!

	let nft=collection.borrowViewResolver(id: id)

	return nft.resolveView(CompositeType(identifier)!)

}

