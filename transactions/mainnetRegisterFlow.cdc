import FiatToken from "../contracts/standard/FiatToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import SwapRouter from "../contracts/community/SwapRouter.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(
    name: String, 
    amountInMax: UFix64,
    exactAmountOut: UFix64,
) {

    let payVault : @FiatToken.Vault
    let leases : &FIND.LeaseCollection?
    let price : UFix64


    prepare(userAccount: auth(BorrowValue) &Account) {

        self.price=FIND.calculateCost(name)
        self.leases=userAccount.storage.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)

        let deadline = getCurrentBlock().timestamp + 1000.0
        let tokenInVaultPath = /storage/flowTokenVault
        let tokenOutReceiverPath = /public/USDCVaultReceiver

        let inVaultRef = userAccount.storage.borrow<&{FungibleToken.Vault}>(from: tokenInVaultPath) ?? panic("Could not borrow reference to the owner's in FT.Vault")

        let path = [ "A.1654653399040a61.FlowToken", "A.b19436aae4d94622.FiatToken" ]

        let vaultInMax <- inVaultRef.withdraw(amount: amountInMax)
        let swapResVault <- SwapRouter.swapTokensForExactTokens(
            vaultInMax: <-vaultInMax,
            exactAmountOut: exactAmountOut,
            tokenKeyPath: path,
            deadline: deadline
        )

        let tempVault <- swapResVault.removeFirst() 
        self.payVault <- tempVault as! @FiatToken.Vault
        let vaultInLeft <- swapResVault.removeLast()
        destroy swapResVault
        inVaultRef.deposit(from: <-vaultInLeft)
    }

    pre{
        self.leases != nil : "Could not borrow reference to find lease collection"
        self.price == exactAmountOut : "Calculated cost : ".concat(self.price.toString()).concat(" does not match expected cost : ").concat(exactAmountOut.toString())
    }

    execute{
        self.leases!.registerUSDC(name: name, vault: <- self.payVault)
    }

}
