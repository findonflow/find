import Admin from "../contracts/Admin.cdc"

transaction(name: String, forgeType: Type, minterCut: UFix64?, description: String, externalURL: String, squareImage: String, bannerImage: String, socials: {String : String}){
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        adminRef.adminSetMinterPlatform(name: name, forgeType: forgeType, minterCut: minterCut, description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials)
    }
}

