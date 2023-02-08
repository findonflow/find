import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"

transaction(dapperAddress: Address) {
	prepare(account: AuthAccount) {

		let ftCaps : [Capability<&{FungibleToken.Receiver}>] = []

		// setup Token for switchboard
		var flowReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		if !flowReceiver.check() {
			account.link<&FlowToken.Vault{FungibleToken.Receiver}>( /public/flowTokenReceiver, target: /storage/flowTokenVault)
			account.link<&FlowToken.Vault{FungibleToken.Balance}>( /public/flowTokenBalance, target: /storage/flowTokenVault)
			flowReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		}
		ftCaps.append(flowReceiver)

		var fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			account.save(<- fusd, to: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
			fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		}
		ftCaps.append(fusdReceiver)

		var usdcCap = account.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
		if !usdcCap.check() {
				account.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
				account.link<&FiatToken.Vault{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
				account.link<&FiatToken.Vault{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
				account.link<&FiatToken.Vault{FungibleToken.Balance}>( FiatToken.VaultBalancePubPath, target:FiatToken.VaultStoragePath)
				usdcCap = account.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
		}
		ftCaps.append(usdcCap)

		let dapper=getAccount(dapperAddress)
		// We will still init DUC and FUC receiver, but use the merch receiver capability in switchboard for now so both would work
		let selfDucReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		if !selfDucReceiver.check() {
			let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
			account.save(<-ducForwarder, to: /storage/dapperUtilityCoinVault)
			account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinVault)
		}

		let selfFutReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
		if !selfFutReceiver.check() {
			let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver))
			account.save(<-futForwarder, to: /storage/flowUtilityTokenVault)
			account.link<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver,target: /storage/flowUtilityTokenVault)
		}

		let ducReceiver = dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		ftCaps.append(ducReceiver)

		let futReceiver = dapper.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
		ftCaps.append(futReceiver)

		// setup switch board
		var checkSB = account.borrow<&FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)
		if checkSB == nil {
			account.save(<- FungibleTokenSwitchboard.createSwitchboard(), to: FungibleTokenSwitchboard.StoragePath)
			account.link<&FungibleTokenSwitchboard.Switchboard{FungibleTokenSwitchboard.SwitchboardPublic, FungibleToken.Receiver}>(FungibleTokenSwitchboard.PublicPath, target: FungibleTokenSwitchboard.StoragePath)
			account.link<&FungibleTokenSwitchboard.Switchboard{FungibleTokenSwitchboard.SwitchboardPublic, FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath, target: FungibleTokenSwitchboard.StoragePath)
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
