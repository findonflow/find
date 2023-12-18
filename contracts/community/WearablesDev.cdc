//This contract is for testing only and should not be deployed elsewhere

import NonFungibleToken from "../standard/NonFungibleToken.cdc"
import MetadataViews from "../standard/MetadataViews.cdc"
import Wearables from "./Wearables.cdc"

pub contract WearablesDev {

	pub var initiated: Bool

	pub fun mintWearablesForTest(receiver: Address) {
		self.initialize()
		let account = getAccount(receiver)
		let wearable= account.getCapability<&Wearables.Collection{NonFungibleToken.Receiver}>(Wearables.CollectionPublicPath).borrow() ?? panic("cannot borrow werable cap")
		Wearables.mintNFT(
			recipient: wearable,
			template: 1,
			context: {"purpose":"testing"}
		)
	}

	// Register Templates here
	access(contract) fun initialize(){

		if self.initiated {
			return
		}

		let set = Wearables.Set(
			id:1,
			name:"testingSet",
			creator: "find",
			royalties: []
		)
		Wearables.addSet(set)

		let position = Wearables.Position(
			id:1,
			name:"testingPosition"
		)
		Wearables.addPosition(position)

		let template = Wearables.Template(
			id:1,
			set: 1,
			position: 1,
			name: "testingTemplate",
			tags:[],
			thumbnail: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "testing", path: nil), mediaType: "image"),
			image: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "testing", path: nil), mediaType: "image"),
			hidden: false,
			plural: false
		)
		Wearables.addTemplate(template)
		self.initiated = true
	}

	init(){
		self.initiated = false
	}

}
