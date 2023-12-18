import Admin from "../contracts/Admin.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: auth(BorrowValue) &Account){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute{
        let type: Type = Type<@DapperUtilityCoin.Vault>()
        self.adminRef.setFTInfo(alias: "DUC", type: type, tag:["dapper utility coin", "dapper"] , icon: "https://assets.website-files.com/5bf4437b68f8b29e67b7ebdc/61a159f8899a41507bc46bcb_feature%20image%20dapper%20post.png", receiverPath: /public/dapperUtilityCoinReceiver, balancePath: /public/dapperUtilityCoinBalance, vaultPath: /storage/dapperUtilityCoinVault)
    }
}
