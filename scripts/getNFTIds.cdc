import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

pub fun main(address: Address, targetPaths: [String]): AnyStruct {

	let report : {String:[UInt64]}={}
	let account=getAuthAccount(address)
	for p in targetPaths {
		let storagePath = StoragePath(identifier:p)!
		var type = account.type(at: storagePath)!
		if type.isSubtype(of: Type<@NonFungibleToken.Collection>()) {
			let collection = account.borrow<&NonFungibleToken.Collection>(from: storagePath)!
			let ids = collection.getIDs()
			if ids.length > 0{
				report[p]=ids
			}
		}
	}
	return report
}
