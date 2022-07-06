import Admin from "../contracts/Admin.cdc"
import Dandy from 0x0afe396ebc8eee65

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{
        let type: Type = Type<@FLOAT.NFT>()
        self.adminRef.setNFTInfo(alias: "FLOAT", type: type, icon: "https://testnet.floats.city/floatlogowebpage.png", providerPath: /private/floatHasNoPrivatePath, publicPath: FLOAT.FLOATCollectionPublicPath, storagePath: FLOAT.FLOATCollectionStoragePath, allowedFTTypes: nil, address: 0x0afe396ebc8eee65, externalFixedUrl: "testnet.floats.city")

    }
}
