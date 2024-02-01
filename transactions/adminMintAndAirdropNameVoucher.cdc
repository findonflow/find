
import Admin from "../contracts/Admin.cdc"
import NameVoucher from "../contracts/NameVoucher.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FindAirdropper from "../contracts/FindAirdropper.cdc"

transaction(users: [Address], minCharLength: UInt64) {

    prepare(account:auth(BorrowValue, FungibleToken.Withdraw) &Account) {

        let client= account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

        let vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)!
        let paymentVault <- vaultRef.withdraw(amount: 0.01 * UFix64(users.length)) 
        let repayment = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!

        let paymentVaultRef = &paymentVault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault}
        for user in users {
            let id = client.mintNameVoucherToFind(
                minCharLength: minCharLength
            )

            let authPointer = client.getAuthPointer(pathIdentifier: "nameVoucher", id: id)
            FindAirdropper.forcedAirdrop(
                pointer: authPointer,
                receiver: user,
                path: NameVoucher.CollectionPublicPath,
                context: {
                    "tenant" : "find"
                },
                storagePayment: paymentVaultRef,
                flowTokenRepayment: repayment,
                deepValidation: false
            )
        }

        vaultRef.deposit(from: <- paymentVault)

    }

}
