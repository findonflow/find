import Admin from "../contracts/Admin.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction() {

    let adminRef : auth(Admin.Owner) &Admin.AdminProxy

    prepare(account: auth(BorrowValue) &Account){
        self.adminRef = account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute{
        let type: Type = Type<@FUSD.Vault>()
        self.adminRef.setFTInfo(alias: "FUSD", type: type, tag:["stablecoin"], icon: "https://static.flowscan.org/mainnet/icons/A.3c5959b568896393.FUSD.png", receiverPath: /public/fusdReceiver, balancePath: /public/fusdBalance, vaultPath: /storage/fusdVault)
    }
}
