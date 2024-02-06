import "FindMarket"
import "FungibleToken"
import "FlowToken"
import "FUSD"
//import "FiatToken"
import "FungibleTokenSwitchboard"

transaction() {
    prepare(account: auth(BorrowValue, SaveValue, IssueAccountCapabilityController, PublishCapability) &Account) {
        //in finds case the
        account.storage.save(<- FindMarket.createTenantClient(), to:FindMarket.TenantClientStoragePath)

        let capb = account.capabilities.storage.issue<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientStoragePath)
        account.capabilities.publish(capb, at: FindMarket.TenantClientPublicPath)

        let ftCaps : [Capability<&{FungibleToken.Receiver}>] = []

        //this has to be here, if not something is very wrong
        let flowReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        ftCaps.append(flowReceiver)


        var fusdReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        if fusdReceiver == nil {
            let fusd <- FUSD.createEmptyVault()

            account.storage.save(<- fusd, to: /storage/fusdVault)
            var cap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/fusdVault)
            account.capabilities.publish(cap, at: /public/fusdReceiver)
            let capb = account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/fusdVault)
            account.capabilities.publish(capb, at: /public/fusdBalance)
            fusdReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        }
        ftCaps.append(fusdReceiver!)

        let usdcCap = account.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
        if !usdcCap.check() {
            account.storage.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
            account.link<&FiatToken.Vault{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
            account.link<&FiatToken.Vault{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
            account.link<&FiatToken.Vault{FungibleToken.Balance}>( FiatToken.VaultBalancePubPath, target:FiatToken.VaultStoragePath)
        }
        ftCaps.append(usdcCap)

        // setup switch board
        var checkSB = account.storage.borrow<&FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)
        if checkSB == nil {
            account.storage.save(<- FungibleTokenSwitchboard.createSwitchboard(), to: FungibleTokenSwitchboard.StoragePath)

            var cap = account.capabilities.storage.issue<&{FungibleTokenSwitchboard.SwitchboardPublic}>(FungibleTokenSwitchboard.StoragePath)
            account.capabilities.publish(cap, at: FungibleTokenSwitchboard.PublicPath)

            var capr = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.StoragePath)
            account.capabilities.publish(capr, at: FungibleTokenSwitchboard.ReceiverPublicPath)
            checkSB = account.storage.borrow<&FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)
        }

        let sb = checkSB!
        let supportTypes = sb.getVaultTypes()
        for cap in ftCaps {
            let ref = cap.borrow()!
            let typ = ref.getType()
            if supportTypes.contains(typ) {
                continue
            }

            sb.addNewVault(capability: cap)
        }
    }
}
