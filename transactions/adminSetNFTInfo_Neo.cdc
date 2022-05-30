import Admin from "../contracts/Admin.cdc"
import NeoVoucher from 0xd6b39e5b5b367aad

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{

        self.adminRef.setNFTInfo(alias: "NeoVoucher", type: Type<@NeoVoucher.NFT>(), icon: "https://test.neocollectibles.xyz/pages/images/neo-collectibles-logo.webp", providerPath: /private/neoVoucherCollection, publicPath: NeoVoucher.CollectionPublicPath, storagePath: NeoVoucher.CollectionStoragePath, allowedFTTypes: nil, address: 0xd6b39e5b5b367aad, externalFixedUrl: "test.neocollectibles.xyx")

    }
}
