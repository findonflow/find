import Admin from "../contracts/Admin.cdc"

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

    }
    execute{
		if let type = CompositeType("A.0afe396ebc8eee65.FLOAT.NFT") { // Testnet Address 
        	self.adminRef.setNFTInfo(alias: "FLOAT", type: type, icon: "https://testnet.floats.city/floatlogowebpage.png", providerPath: /private/FLOATCollectionPublicPath, publicPath: /public/FLOATCollectionPublicPath, storagePath: /storage/FLOATCollectionStoragePath, allowedFTTypes: nil, address: 0x0afe396ebc8eee65, externalFixedUrl: "testnet.floats.city")
        	
		} else if let type = CompositeType("A.2d4c3caffbeab845.FLOAT.NFT") {
        	self.adminRef.setNFTInfo(alias: "FLOAT", type: type, icon: "https://floats.city/floatlogowebpage.png", providerPath: /private/FLOATCollectionPublicPath, publicPath: /public/FLOATCollectionPublicPath, storagePath: /storage/FLOATCollectionStoragePath, allowedFTTypes: nil, address: 0x2d4c3caffbeab845, externalFixedUrl: "floats.city")
		}

    }
}
