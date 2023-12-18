import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"

//Transaction that is signed by find to create a find market tenant for find
transaction() {
    prepare(account: auth(BorrowValue)  AuthAccountAccount) {
        //in finds case the
        account.save(<- FindMarket.createTenantClient(), to:FindMarket.TenantClientStoragePath)
        account.link<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath, target: FindMarket.TenantClientStoragePath)

        let ftCaps : [Capability<&{FungibleToken.Receiver}>] = []

        // setup Token for switchboard
        let flowReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        if !flowReceiver.check() {
            account.link<&{FungibleToken.Receiver}>( /public/flowTokenReceiver, target: /storage/flowTokenVault)
            account.link<&{FungibleToken.Balance}>( /public/flowTokenBalance, target: /storage/flowTokenVault)
        }
        ftCaps.append(flowReceiver)

        let fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        if !fusdReceiver.check() {
            let fusd <- FUSD.createEmptyVault()
            account.save(<- fusd, to: /storage/fusdVault)
            account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
            account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
        }
        ftCaps.append(fusdReceiver)

        let usdcCap = account.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
        if !usdcCap.check() {
            account.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
            account.link<&FiatToken.Vault{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
            account.link<&FiatToken.Vault{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
            account.link<&FiatToken.Vault{FungibleToken.Balance}>( FiatToken.VaultBalancePubPath, target:FiatToken.VaultStoragePath)
        }
        ftCaps.append(usdcCap)

        // setup switch board
        var checkSB = account.borrow<&FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)
        if checkSB == nil {
            account.save(<- FungibleTokenSwitchboard.createSwitchboard(), to: FungibleTokenSwitchboard.StoragePath)
            account.link<&FungibleTokenSwitchboard.Switchboard{FungibleTokenSwitchboard.SwitchboardPublic}>(FungibleTokenSwitchboard.PublicPath, target: FungibleTokenSwitchboard.StoragePath)
            account.link<&FungibleTokenSwitchboard.Switchboard{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath, target: FungibleTokenSwitchboard.StoragePath)
            checkSB = account.borrow<&FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)
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
