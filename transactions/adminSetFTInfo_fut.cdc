import "Admin"
import "FlowUtilityToken"

transaction() {

    let adminRef : auth(Admin.Owner) &Admin.AdminProxy

    prepare(account: auth(BorrowValue) &Account){
        self.adminRef = account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute{
        let type: Type = Type<@FlowUtilityToken.Vault>()
        self.adminRef.setFTInfo(alias: "FUT", type: type, tag:["flow utility token", "dapper"] , icon: "https://assets.website-files.com/5bf4437b68f8b29e67b7ebdc/61a159f8899a41507bc46bcb_feature%20image%20dapper%20post.png", receiverPath: /public/flowUtilityTokenReceiver, balancePath: /public/flowUtilityTokenBalance, vaultPath: /storage/flowUtilityTokenVault)
    }
}
