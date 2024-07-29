import FIND from "../contracts/FIND.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"


transaction(name: String, addon:String, amount:UFix64) {

    let leases : &FIND.LeaseCollection?
    let vaultRef : &FlowToken.Vault? 

    prepare(account: AuthAccount) {

        self.leases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
        self.vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        FIND.validateAddonPrice(addon: addon, flow: amount)

    }

    pre{
        self.leases != nil : "Could not borrow reference to the leases collection"
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.vaultRef!.balance > amount : "Balance of vault is not high enough ".concat(self.vaultRef!.balance.toString())
    }

    execute {
        let vault <- self.vaultRef!.withdraw(amount: amount) as! @FlowToken.Vault
        self.leases!.buyAddon(name: name, addon: addon, vault: <- vault)
    }
}

