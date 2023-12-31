import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction(address: Address, name: String, description: String, thumbnail: String) {
    let cap : Capability<&ExampleNFT.Collection>
    let minter: &ExampleNFT.NFTMinter

    prepare(account: auth(BorrowValue) &Account) {
        self.cap = getAccount(address).capabilities.get<&ExampleNFT.Collection>(/public/exampleNFTCollection)!
        self.minter=account.storage.borrow<&ExampleNFT.NFTMinter>(from: ExampleNFT.MinterStoragePath)!
    }

    pre{
        self.cap.check() : "Cannot borrow reference to receiver Collection. Receiver account : ".concat(address.toString())
    }

    execute{
        let nft <- self.minter.mintNFT(name: name, description: description, thumbnail: thumbnail, royalties: [])
        self.cap.borrow()!.deposit(token: <- nft)
    }
}
