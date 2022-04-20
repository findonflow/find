import Admin from "../contracts/Admin.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute{
        let type: Type = Type<@FlowToken.Vault>()
        self.adminRef.setFTInfo(alias: "Flow", type: type, tag:["utility coin"] , icon: nil, receiverPath: /public/flowTokenReceiver, balancePath: /public/flowTokenBalance, vaultPath: /storage/flowTokenVault)
    }
}
