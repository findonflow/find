import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"
import Admin from "../contracts/Admin.cdc"

//mint an art and add it to a users collection
transaction(
    name: String,
    image: String,
    thumbnail: String,
    originUrl: String,
    description: String,
    recipient: Address
) {
    let receiverCap: Capability<&{NonFungibleToken.Collection}>
    let client: &Admin.AdminProxy

    prepare(account: auth(BorrowValue) &Account) {
        self.client= account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
        self.receiverCap= getAccount(recipient).capabilities.get<&{NonFungibleToken.Collection}>(CharityNFT.CollectionPublicPath)
    }

    execute {
        let metadata = {"name" : name, "image" : image, "thumbnail": thumbnail, "originUrl": originUrl, "description":description}
        self.client.mintCharity(metadata: metadata, recipient: self.receiverCap)
    }
}

