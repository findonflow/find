import Admin from "../contracts/Admin.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import Dandy from "../contracts/Dandy.cdc"

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{
        let type: Type = Type<@Dandy.NFT>()
        self.adminRef.setNFTInfo(alias: "Dandy", type: type, icon: nil, providerPath: Dandy.CollectionPrivatePath, publicPath: Dandy.CollectionPublicPath, storagePath: Dandy.CollectionStoragePath, allowedFTTypes: nil, address: 0xf8d6e0586b0a20c7, externalFixedUrl: "find.xyz")

    }
}
