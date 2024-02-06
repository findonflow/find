import "Admin"
import "FiatToken"

transaction() {

    let adminRef : auth(Admin.Owner) &Admin.AdminProxy

    prepare(account: auth(BorrowValue) &Account){
        self.adminRef = account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute{
        let type: Type = Type<@FiatToken.Vault>()
        self.adminRef.setFTInfo(alias: "USDC", type: type, tag:["stablecoin"] , icon: "https://static.flowscan.org/mainnet/icons/A.b19436aae4d94622.FiatToken.png", receiverPath: FiatToken.VaultReceiverPubPath, balancePath: FiatToken.VaultBalancePubPath, vaultPath: FiatToken.VaultStoragePath)
    }
}
