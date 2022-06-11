import Admin from "../contracts/Admin.cdc"
import Flovatar from 0x9392a4a7c3f49a0b

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{

        self.adminRef.setNFTInfo(alias: "Flovatar", type: Type<@Flovatar.NFT>(), icon: "https://styles.redditmedia.com/t5_5ikf79/styles/communityIcon_fraplt3tgk681.jpg", providerPath: /private/FlovatarCollection, publicPath: Flovatar.CollectionPublicPath, storagePath: Flovatar.CollectionStoragePath, allowedFTTypes: nil, address: 0x9392a4a7c3f49a0b, externalFixedUrl: "flovatar.com")

    }
}
