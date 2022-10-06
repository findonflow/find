import FungibleToken from "./standard/FungibleToken.cdc"
import DapperUtilityCoin from "./standard/DapperUtilityCoin.cdc"
import TokenForwarding from "./standard/TokenForwarding.cdc"

pub contract FindIOU {

	pub event IOUCreated(uuid: UInt64, by:Address?, type: String, amount: UFix64)
	pub event IOUToppedUp(uuid: UInt64, by:Address?, type: String, amount: UFix64, fromAmount: UFix64, toAmount: UFix64)
	pub event IOURedeemed(uuid: UInt64, by:Address?, type: String, amount: UFix64)
	pub event IOUWithdrawn(uuid: UInt64, from: Address?, type: String, amount: UFix64)
	pub event IOUDesposited(uuid: UInt64, to: Address?, type: String, amount: UFix64)

	pub let CollectionStoragePath : StoragePath 
	pub let CollectionPublicPath : PublicPath

	pub resource IOU {
		pub let vaultType : Type 
		pub var balance : UFix64 
		access(self) let vault : @FungibleToken.Vault

		init(_ vault: @FungibleToken.Vault) {
			self.vaultType = vault.getType()
			self.balance = vault.balance
			self.vault <- vault
		}

		destroy() {
			pre {
				self.vault.balance == 0.0 : "balance of vault in IOU cannot be non-zero when destroy"
			}
			destroy self.vault
		}

		pub fun createEmptyVault() : @FungibleToken.Vault {
			return <- self.vault.withdraw(amount: 0.0)
		}

		pub fun topUp(_ vault: @FungibleToken.Vault) {
			pre{
				self.vaultType == vault.getType() : "The vault type passed in does not match with the redeeming iou. Required vault type : ".concat(self.vaultType.identifier)
			}
			emit IOUToppedUp(uuid: self.uuid, by: self.owner?.address, type: self.vaultType.identifier, amount: vault.balance, fromAmount: self.balance, toAmount: self.balance + vault.balance)
			self.balance = self.balance + vault.balance

			if self.vaultType == Type<@DapperUtilityCoin.Vault>() {
				// Handle Dapper stuff here
				let receiver = FindIOU.borrowDUCReceiver()
				receiver.deposit(from: <- vault) 

			} else {
				self.vault.deposit(from: <- vault)
			}
		}

		access(contract) fun redeem() : @FungibleToken.Vault {
			return <- self.vault.withdraw(amount: self.vault.balance)
		}

	}

	pub resource interface CollectionPublic {
		pub let IOUTypes : {Type : [UInt64]}
		pub fun getIOUs() : [UInt64]
		pub fun containsIOU(_ id: UInt64) : Bool 
		pub fun deposit(_ token: @IOU)
	}

	pub resource Collection : CollectionPublic { 
		access(self) let ownedIOUs : @{UInt64 : IOU}

		pub let IOUTypes : {Type : [UInt64]}

		init(){
			self.ownedIOUs <- {} 
			self.IOUTypes = {}
		}

		destroy() {
			destroy self.ownedIOUs
		}

		pub fun getIOUs() : [UInt64] {
			return self.ownedIOUs.keys
		}
		
		pub fun containsIOU(_ id: UInt64) : Bool {
			return self.ownedIOUs.containsKey(id)
		}

		pub fun deposit(_ token: @IOU) {
			emit IOUDesposited(uuid: token.uuid, to: self.owner?.address, type: token.vaultType.identifier, amount: token.balance)

			let iouTypes = self.IOUTypes[token.vaultType] ?? []
			iouTypes.append(token.uuid)
			self.IOUTypes[token.vaultType] = iouTypes

			self.ownedIOUs[token.uuid] <-! token
		}

		pub fun withdraw(_ id: UInt64) : @IOU {
			pre{
				self.ownedIOUs.containsKey(id) : "Does not contain IOU with uuid : ".concat(id.toString())
			}
			let token <- self.ownedIOUs.remove(key: id)! 
			emit IOUWithdrawn(uuid: token.uuid, from: self.owner?.address, type: token.vaultType.identifier, amount: token.balance)
			return <- token
		}

		pub fun createEscrowedIOU(_ vault: @FungibleToken.Vault) : @IOU {
			pre {
				vault.getType() != Type<@DapperUtilityCoin.Vault>() : "Please call createDapperIOU on Dapper Utility Coin Vaults"
			}
			let iou <- create IOU(<- vault)
			emit IOUCreated(uuid: iou.uuid, by: self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance)
			return <- iou
		}

		pub fun createDapperIOU(_ vault: @FungibleToken.Vault) : @IOU {
			pre {
				vault.getType() == Type<@DapperUtilityCoin.Vault>() : "Please call createEscrowIOU on non-DUC Vaults"
			}
			let iou <- create IOU(<- vault)
			emit IOUCreated(uuid: iou.uuid, by: self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance)
			let receiver = FindIOU.borrowDUCReceiver()
			receiver.deposit(from: <- iou.redeem()) 
			return <- iou
		}

		pub fun create(_ vault: @FungibleToken.Vault) : @IOU {
			if vault.getType() == Type<@DapperUtilityCoin.Vault>() {
				return <- self.createDapperIOU( <- vault)
			}
			return <- self.createEscrowedIOU(<- vault)
		}

		pub fun topUp(id: UInt64, vault: @FungibleToken.Vault) {
			let iou = self.borrowIOU(id)
			iou.topUp(<- vault)
		}

		pub fun borrowIOU(_ id: UInt64) : &IOU {
			pre{
				self.ownedIOUs.containsKey(id) : "Does not contain IOU with uuid : ".concat(id.toString())
			}
			return (&self.ownedIOUs[id] as &IOU?)!
		}

		pub fun redeemEscrowIOU(_ id: UInt64) : @FungibleToken.Vault {
			pre {
				self.ownedIOUs.containsKey(id) : "Does not contain IOU with uuid : ".concat(id.toString())
			}
			let iou <- self.ownedIOUs.remove(key: id)!
			if iou.vaultType == Type<@DapperUtilityCoin.Vault>() {
				panic("Please call redeemDapperIOU on Dapper Utility Coin Vaults")
			}
			emit IOURedeemed(uuid: iou.uuid, by:self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance)
			let vault <- iou.redeem()
			destroy iou 
			return <- vault
		}

		pub fun redeemDapperIOU(id: UInt64, vault: @FungibleToken.Vault) : @FungibleToken.Vault {
			pre {
				self.ownedIOUs.containsKey(id) : "Does not contain IOU with uuid : ".concat(id.toString())
			}
			let iou <- self.ownedIOUs.remove(key: id)!
			if iou.vaultType != Type<@DapperUtilityCoin.Vault>() {
				panic("Please call redeemEscrowIOU on non-DUC Vaults")
			}
			if vault.getType() != Type<@DapperUtilityCoin.Vault>() || vault.balance != iou.balance {
				panic("Please pass in a DUC Vault with exact redeeming balance : ".concat(iou.balance.toString()))
			}
			emit IOURedeemed(uuid: iou.uuid, by:self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance)
			destroy iou 
			return <- vault
		}

		pub fun redeem(id: UInt64, vault: @FungibleToken.Vault?) :  @FungibleToken.Vault {
			let iou = self.borrowIOU(id)
			if iou.vaultType == Type<@DapperUtilityCoin.Vault>() {
				if vault != nil {
					let returningVault <- self.redeemDapperIOU(id: id, vault: <- vault!)
					return <- returningVault
				}
				panic("Please pass in a DUC Vault with exact redeeming balance : ".concat(iou.balance.toString()))
			}
			if vault == nil {
				destroy vault
				let returningVault <- self.redeemEscrowIOU(id)
				return <- returningVault
			}
			destroy vault
			panic("Please do not pass in any vault when redeeming non-Dapper IOU")
		}


	}

	pub fun createEmptyCollection() : @Collection {
		return <- create Collection()
	}

	access(contract) fun borrowDUCReceiver() : &{FungibleToken.Receiver} {
		let receiver = FindIOU.account.borrow<&{FungibleToken.Receiver}>(from: /storage/dapperUtilityCoinReceiver)
			?? panic("Cannot borrow DUC receiver vault balance from FIND.")

		return receiver
	}

	init(){
		self.CollectionStoragePath = /storage/FindIOU
		self.CollectionPublicPath = /public/FindIOU
	}

}