//❯ flow scripts execute scripts/getProfileTest.cdc 0x70df6ccc9632a4dd -n migrationnetimport
import "Profile"

access(all) fun main(address: Address) :  AnyStruct {
    var wallets = getAccount(address).capabilities.borrow<&{Profile.Public}>(Profile.publicPath)?.getWallets() ?? []

    for wallet in wallets {
        if wallet.name == "USDC" {
            return wallet.balance.id
        }
    }
    return nil
}
