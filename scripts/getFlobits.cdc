import FlovatarComponent from 0x921ea449dffec68a
import FlovatarMarketplace from  0x921ea449dffec68a

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

pub fun main(addr: Address) : [MetadataCollectionItem] {

	let flovatarComponents= FlovatarComponent.getComponents(address: addr)

	let templateNumbers : {UInt64: UInt64} = {}
	let templateData : {UInt64: FlovatarComponent.ComponentData} = {}
	for flovatar in flovatarComponents {

		let templateId= flovatar.templateId
		var number:UInt64=1
		if templateNumbers[templateId] == nil {
			templateNumbers[templateId] = (1 as UInt64)
			templateData[templateId]=flovatar
		} else {
			templateNumbers[templateId] = templateNumbers[templateId]! + 1
		}
	}


	let flovatarMarketComponents=FlovatarMarketplace.getFlovatarComponentSales(address:addr)

	for flovatar in flovatarMarketComponents {

		let templateId= flovatar.metadata.templateId
			var number:UInt64=1
			if templateNumbers[templateId] == nil {
				templateNumbers[templateId] = (1 as UInt64)
				templateData[templateId]=FlovatarComponent.getComponent(address:addr, componentId: flovatar.id)!
			} else {
				templateNumbers[templateId] = templateNumbers[templateId]! + 1
			}
	}


	let flovatarC : [MetadataCollectionItem] = []
	for templateId in templateData.keys {
		let template=templateData[templateId]!


		var name=template.name

		if templateId == 75 || templateId==74 || templateId == 73 {
			name=name.concat(" Booster")
		}

		if templateNumbers[templateId]! > 1 {
			name=name.concat(" x ").concat(templateNumbers[templateId]!.toString())
		} 

		let item=MetadataCollectionItem(
			id: template.id, 
			name: name, 
			image: "https://flovatar.com/api/image/template/".concat(templateId.toString()),
			url: "https://flovatar.com",
			listPrice: nil,
			listToken: nil,
			contentType: "image",
			rarity: template.rarity
		)

		flovatarC.append(item)
	}

	return flovatarC

}
