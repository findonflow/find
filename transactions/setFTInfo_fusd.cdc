import Admin from "../contracts/Admin.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute{
        let type: Type = Type<@FUSD.Vault>()
        self.adminRef.setFTInfo(alias: "FUSD", type: type, tag:["stablecoin"], icon: nil, receiverPath: /public/fusdReceiver, balancePath: /public/fusdBalance, vaultPath: /storage/fusdVault)
    }
}
