import Admin from "../contracts/Admin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute{
        let type: Type = Type<@FlowUtilityToken.Vault>()
        self.adminRef.setFTInfo(alias: "FUT", type: type, tag:["flow utility token", "dapper"] , icon: "https://assets.website-files.com/5bf4437b68f8b29e67b7ebdc/61a159f8899a41507bc46bcb_feature%20image%20dapper%20post.png", receiverPath: /public/flowUtilityTokenReceiver, balancePath: /public/flowUtilityTokenBalance, vaultPath: /storage/flowUtilityTokenReceiver)
    }
}
