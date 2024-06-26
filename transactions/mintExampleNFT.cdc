import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction(user: String,
		name: String,
        description: String,
        thumbnail: String,
        soulBound: Bool ,
        traits: [UInt64]
		) {
	let address : Address
	let cap : Capability<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>

	prepare(account: AuthAccount) {
		self.address = FIND.resolve(user) ?? panic("Cannot find user with this name / address")
		self.cap = getAccount(self.address).getCapability<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>(ExampleNFT.CollectionPublicPath)
	}

	pre{
		self.cap.check() : "Cannot borrow reference to receiver Collection. Receiver account : ".concat(self.address.toString())
	}

	execute{
		let r : MetadataViews.Royalties = MetadataViews.Royalties([])
		let nft <- ExampleNFT.mintNFT(name: name, description: description, thumbnail: thumbnail, soulBound: soulBound, traits: traits, royalties: r)
		self.cap.borrow()!.deposit(token: <- nft)
	}
}
