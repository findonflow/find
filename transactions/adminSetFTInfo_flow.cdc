import "Admin"
import "FlowToken"

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: auth (BorrowValue) &Account){
        self.adminRef = account.storage.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute{
        let type: Type = Type<@FlowToken.Vault>()
        self.adminRef.setFTInfo(alias: "Flow", type: type, tag:["utility coin"] , icon: "https://static.flowscan.org/mainnet/icons/A.1654653399040a61.FlowToken.png", receiverPath: /public/flowTokenReceiver, balancePath: /public/flowTokenBalance, vaultPath: /storage/flowTokenVault)
    }
}
