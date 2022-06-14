import Admin from "../contracts/Admin.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{
        let type: Type = Type<@ExampleNFT.NFT>()
        self.adminRef.setNFTInfo(alias: "ExampleNFT", type: type, icon: nil, providerPath: ExampleNFT.CollectionPrivatePath, publicPath: ExampleNFT.CollectionPublicPath, storagePath: ExampleNFT.CollectionStoragePath, allowedFTTypes: nil, address: 0xf8d6e0586b0a20c7, externalFixedUrl: "example.nft")

    }
}
