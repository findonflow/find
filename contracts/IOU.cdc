import FungibleToken from "./standard/FungibleToken.cdc"
import DapperUtilityCoin from "./standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "./standard/FlowUtilityToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"

// This is a contract that specifies the IOU.Vault resource 
// IOUs are resources of proof of payments. Payments in an IOU is always sent to the user it was created for regardless who holds it now 
// Pass in a vault to create an equal balance IOU, and redeem the IOU to get the money back. 
pub contract IOU {

	pub event IOUCreated(uuid: UInt64, by:Address?, type: String, amount: UFix64)
	pub event IOUToppedUp(uuid: UInt64, by:Address?, type: String, amount: UFix64, fromAmount: UFix64, toAmount: UFix64)
	pub event IOURedeemed(uuid: UInt64, by:Address?, type: String, amount: UFix64)
	pub event IOUWithdrawn(uuid: UInt64, from: Address?, type: String, amount: UFix64)

	pub var DapperCoinTypes : [Type]
	pub let IOUTypePathMap : {Type : String}

	pub resource Vault { 
		pub let vaultType : Type 
		pub var balance : UFix64 
		pub let receiver : Capability<&{FungibleToken.Receiver}>

		init(vault: @FungibleToken.Vault, receiver: Capability<&{FungibleToken.Receiver}>) {
			self.receiver = receiver
			self.vaultType = vault.getType()
			self.balance = vault.balance

			//We deposit the funds back to dapper again and emit an event
			IOU.borrowDapperAccountReceiver(self.vaultType).deposit(from: <- vault)

			emit IOUCreated(uuid: self.uuid, by: self.receiver.address, type: self.vaultType.identifier, amount: self.balance)
		}

		pub fun topUp(_ vault: @FungibleToken.Vault) {
			pre{
				self.vaultType == vault.getType() : "The vault type passed in does not match with the redeeming iou. Required vault type : ".concat(self.vaultType.identifier)
			}
			emit IOUToppedUp(uuid: self.uuid, by: self.receiver.address, type: self.vaultType.identifier, amount: vault.balance, fromAmount: self.balance, toAmount: self.balance + vault.balance)
			self.balance = self.balance + vault.balance
			IOU.borrowDapperAccountReceiver(self.vaultType).deposit(from: <- vault)
		}

		//when we redeem a IOU we _have_ to send in the vault with the funds, it has to match the type and amount
		//the funds is then sent to the capability stored, not the resource owner
		pub fun redeem(_ vault: @FungibleToken.Vault) {
			pre {
				self.vaultType == vault.getType() : "Vault passed in is not in type of IOU. Type required : ".concat(self.vaultType.identifier)
				self.balance == vault.balance : "Vault passed in is not in same balance of IOU. Balance required : ".concat(self.balance.toString())
			}

			emit IOURedeemed(uuid: self.uuid, by:self.receiver.address, type: self.vaultType.identifier, amount: self.balance)
			self.receiver.borrow()!.deposit(from: <- vault)
			self.balance=0.0
		}

		destroy() {
			if self.balance!=0.0 {
				emit IOUWithdrawn(uuid: self.uuid, from: self.receiver.address, type: self.vaultType.identifier, amount: self.balance)
			}
		}
	}

	access(account) fun changeDapperCoinTypes(_ types : [Type]) {
		self.DapperCoinTypes = types
	}

	access(account) fun addTypePath(type : Type, path: String) {

		self.IOUTypePathMap[type] = path
	}

	pub fun getPathFromType(_ type: Type) : String {
			let identifier=type.identifier

		var i=0
		var newIdentifier=""
		while i < identifier.length {

			let item= identifier.slice(from: i, upTo: i+1) 
			if item=="." {
				newIdentifier=newIdentifier.concat("_")
			} else {
				newIdentifier=newIdentifier.concat(item)
			}
			i=i+1
		}
		return newIdentifier
	}

	//The main receiver is _always_ last
	//TODO; take into consideration minimum ammounts...
	pub fun createVaults(vault: @FungibleToken.Vault, receiver: Capability<&{FungibleToken.Receiver}>, royalties: MetadataViews.Royalties) : @[IOU.Vault] {

		let vaults : @[IOU.Vault] <- []
		let amount = vault.balance
		for key, royalty in royalties.getRoyalties() {
			vaults.append(<- create IOU.Vault(vault: <- vault.withdraw(amount: amount * royalty.cut), receiver: royalty.receiver))
		}
		vaults.append(<- create IOU.Vault(vault:<- vault, receiver: receiver))
		return <- vaults
	}

	access(contract) fun borrowDapperAccountReceiver(_ type: Type) : &{FungibleToken.Receiver} {
		switch type {
			case Type<@DapperUtilityCoin.Vault>() : 
				return IOU.account.borrow<&{FungibleToken.Receiver}>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow reference to DUC receiver")

			case Type<@FlowUtilityToken.Vault>() : 
				return IOU.account.borrow<&{FungibleToken.Receiver}>(from: /storage/flowUtilityTokenVault) ?? panic("Cannot borrow reference to DUC receiver")
		}
		panic("Type passed in is not supported. Type : ".concat(type.identifier))
	}

	init(){
		//TODO this should be map from type to path
		self.DapperCoinTypes=[
			Type<@DapperUtilityCoin.Vault>(),
			Type<@FlowUtilityToken.Vault>()
		]

		self.IOUTypePathMap = {}
	}
}
