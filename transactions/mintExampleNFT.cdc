import "NonFungibleToken"
import "FungibleToken"
import "ExampleNFT"
import "MetadataViews"

transaction(address: Address, name: String, description: String, thumbnail: String, soulBound: Bool) {
    let cap : Capability<&ExampleNFT.Collection>
    let royaltyCap : Capability<&{FungibleToken.Receiver}>

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, UnpublishCapability) &Account) {

        self.cap = getAccount(address).capabilities.get<&ExampleNFT.Collection>(ExampleNFT.CollectionPublicPath)!

        self.royaltyCap =getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
    }

    pre{
        self.cap.check() : "Cannot borrow reference to receiver Collection. Receiver account : ".concat(address.toString())
    }

    execute{

        let r  = MetadataViews.Royalty(receiver:self.royaltyCap, cut: 0.01, description: "creator")
        let royalties = MetadataViews.Royalties([r])
        let nft <- ExampleNFT.mintNFT(name: name, description: description, thumbnail: thumbnail, soulBound:soulBound, traits:[], royalties: royalties)
        self.cap.borrow()!.deposit(token: <- nft)
    }
}
