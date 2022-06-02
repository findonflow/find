import Gaia from 0x8b148183c28ff88f

pub struct MetadataCollectionItem {
	pub let id:UInt64
	pub let name: String
	pub let image: String
	pub let url: String
	pub let listPrice: UFix64?
	pub let listToken: String?
	pub let contentType:String
	pub let rarity:String


	init(id:UInt64, name:String, image:String, url:String, listPrice: UFix64?, listToken:String?, contentType: String, rarity: String) {
		self.id=id
		self.name=name
		self.url=url
		self.image=image
		self.listToken=listToken
		self.listPrice=listPrice
		self.contentType=contentType
		self.rarity=rarity
	}
}

pub fun main() : AnyStruct? {

	//let address:Address=0xc208bb1d14ebc950
//	let address:Address=0x886f3aeaf848c535
	let address:Address=0xdc4d3e299c5c4553
	let account= getAccount(address)
	let gaiaCollection = account.getCapability<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath)
	if !gaiaCollection.check() {
		return nil
	}

	let items :[AnyStruct] = []
		let gaiaNfts = gaiaCollection.borrow()!.getIDs()
		for id in gaiaNfts {
			let nft = gaiaCollection.borrow()!.borrowGaiaNFT(id: id)!
			let metadata = Gaia.getTemplateMetaData(templateID: nft.data.templateID)!

			//For ballerz we can do this...
			var url="http://ongaia.com/"
			var name=metadata["title"]!

			if let seriesFullName=metadata["series"] {
				if seriesFullName=="Bryson DeChambeau - Vegas, Baby!" {
					//For golf there is yet another way
					url="http://ongaia.com/bryson/".concat(nft.data.mintNumber.toString())
					name=metadata["title"]!.concat(" #").concat(nft.data.mintNumber.toString())
				} else {
					//If the series is basketball with shareef we can do this
					url="http://ongaia.com/shareef/nft/".concat(id.toString())
					name=metadata["title"]!.concat(" #").concat(nft.data.mintNumber.toString())
				}
			}

			let newCollections= ["ballerz", "sneakerz"]
			if let mid = metadata["id"] {
				if let uri = metadata["uri"] {
					for c in newCollections {
						if uri == "/collection/".concat(c).concat("//").concat(mid) {
							url="http://ongaia.com/".concat(c).concat("/").concat(mid)
						}
					}
				}
			}


			let item= MetadataCollectionItem(
				id: id,
				name: name,
				image: metadata["img"]!,
				url: url,
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""
			)

			items.append(item)
		}

		return items
}

