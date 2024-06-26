import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import LostAndFound from "./standard/LostAndFound.cdc"
import LostAndFoundHelper from "./standard/LostAndFoundHelper.cdc"
import FlowStorageFees from "./standard/FlowStorageFees.cdc"
import FIND from "./FIND.cdc"
import FindViews from "./FindViews.cdc"


pub contract FindLostAndFoundWrapper {

    pub event NFTDeposited(receiver: Address, receiverName: String?, sender: Address?, senderName: String?, type: String, id: UInt64?, uuid: UInt64?, memo: String?, name: String?, description: String?, thumbnail: String?, collectionName: String?, collectionImage: String?)
    pub event UserStorageSubsidized(receiver: Address, receiverName: String?, sender: Address, senderName: String?, forUUID: UInt64, storageFee: UFix64)
    pub event TicketDeposited(receiver: Address, receiverName: String?, sender: Address, senderName: String?, ticketID: UInt64, type: String, id: UInt64, uuid: UInt64?, memo: String?, name: String?, description: String?, thumbnail: String?, collectionName: String?, collectionImage: String?, flowStorageFee: UFix64)
    pub event TicketRedeemed(receiver: Address, receiverName: String?, ticketID: UInt64, type: String)
    pub event TicketRedeemFailed(receiver: Address, receiverName: String?, ticketID: UInt64, type: String, remark: String)

    // check if they have that storage 
    // npm module for NFT catalog, that can init the storage of the users.  
    // List of what you have in lost and found. 
    // a button to init the storage 

    // Mapping of vault uuid to vault.  
    // A method to get around passing the "Vault" reference to Lost and Found to ensure it cannot be hacked. 
    // All vaults should be destroyed after deposit function
    pub let storagePaymentVaults : @{UInt64 : FungibleToken.Vault}

    // Deposit 
    pub fun depositNFT(
        receiver: Address,
        collectionPublicPath: PublicPath,
        item: FindViews.AuthNFTPointer,
        memo: String?,
        storagePayment: &FungibleToken.Vault,
        flowTokenRepayment: Capability<&FlowToken.Vault{FungibleToken.Receiver}> ,
        subsidizeReceiverStorage: Bool
    ) : UInt64? {

        let receiverAddress = receiver

        let sender = item.owner()
        let senderName = FIND.reverseLookup(sender)

        let display = item.getDisplay()
        let collectionDisplay = MetadataViews.getNFTCollectionDisplay(item.getViewResolver())
        let id = item.id 
        let uuid = item.uuid
        let type = item.getItemType()

        // calculate the required storage and check sufficient balance 
        let senderStorageBeforeSend = getAccount(sender).storageUsed

        let item <- item.withdraw() 

        let requiredStorage = senderStorageBeforeSend - getAccount(sender).storageUsed
        let receiverAvailableStorage = getAccount(receiverAddress).storageCapacity - getAccount(receiverAddress).storageUsed

        // Try to send before using Lost & FIND
        let receiverCap = getAccount(receiverAddress).getCapability<&{NonFungibleToken.Receiver}>(collectionPublicPath)
        if receiverCap.check() {
            // If the receiver has sufficient storage, then subsidize it
            var readyToSend = true
            if receiverAvailableStorage < requiredStorage {
                readyToSend = false 
                if subsidizeReceiverStorage {
                    readyToSend = FindLostAndFoundWrapper.subsidizeUserStorage(requiredStorage: requiredStorage, receiverAvailableStorage: receiverAvailableStorage, receiver: receiver, vault: storagePayment, sender: sender, uuid: item.uuid)
                }
            }   

            if readyToSend {
                receiverCap.borrow()!.deposit(token: <- item)
                emit NFTDeposited(receiver: receiverCap.address, receiverName: FIND.reverseLookup(receiverAddress), sender: sender, senderName: senderName, type: type.identifier, id: id, uuid: uuid, memo: memo, name: display.name, description: display.description, thumbnail: display.thumbnail.uri(), collectionName: collectionDisplay?.name, collectionImage: collectionDisplay?.squareImage?.file?.uri())
                return nil
            }
        }

        let collectionPublicCap = getAccount(receiverAddress).getCapability<&{NonFungibleToken.CollectionPublic}>(collectionPublicPath)
        if collectionPublicCap.check() {
            // If the receiver has sufficient storage, then subsidize it
            var readyToSend = true
            if receiverAvailableStorage < requiredStorage {
                readyToSend = false 
                if subsidizeReceiverStorage {
                    readyToSend = FindLostAndFoundWrapper.subsidizeUserStorage(requiredStorage: requiredStorage, receiverAvailableStorage: receiverAvailableStorage, receiver: receiver, vault: storagePayment, sender: sender, uuid: item.uuid)
                }
            }   

            if readyToSend {
                collectionPublicCap.borrow()!.deposit(token: <- item)
                emit NFTDeposited(receiver: receiverCap.address, receiverName: FIND.reverseLookup(receiverAddress), sender: sender, senderName: senderName, type: type.identifier, id: id, uuid: uuid, memo: memo, name: display.name, description: display.description, thumbnail: display.thumbnail.uri(), collectionName: collectionDisplay?.name, collectionImage: collectionDisplay?.squareImage?.file?.uri())
                return nil
            }
        }

        // Calculate storage fees required 
        let estimate <- LostAndFound.estimateDeposit(
                            redeemer: receiverAddress,
                            item: <- item,
                            memo: memo,
                            display: display
                        )
        // we add 0.00005 here just incase it falls below
        // extra fees will be deposited back to the sender
        let vault <- storagePayment.withdraw(amount: estimate.storageFee + 0.00005)

        // Put the payment vault in dictionary and get it's reference, just for safety that we don't pass vault ref to other contracts that we do not control
        let vaultUUID = vault.uuid 

        let vaultRef = FindLostAndFoundWrapper.depositVault(<- vault)

        let flowStorageFee = vaultRef.balance
        let ticketID = LostAndFound.deposit(
            redeemer: receiverAddress,
            item: <- estimate.withdraw(),
            memo: memo,
            display: display,
            storagePayment: vaultRef,
            flowTokenRepayment: flowTokenRepayment
        )
        // Destroy the vault after the payment. The vault should be 0 in balance
        FindLostAndFoundWrapper.destroyVault(vaultUUID, cap: flowTokenRepayment)

        emit TicketDeposited(receiver: receiverAddress, receiverName: FIND.reverseLookup(receiverAddress), sender: sender, senderName: senderName, ticketID: ticketID, type: type.identifier, id: id, uuid: uuid, memo: memo, name: display.name, description: display.description, thumbnail: display.thumbnail.uri(), collectionName: collectionDisplay?.name, collectionImage: collectionDisplay?.squareImage?.file?.uri(), flowStorageFee: flowStorageFee)
        destroy estimate

        return ticketID
    }

    // Redeem 
    pub fun redeemNFT(type: Type, ticketID: UInt64, receiverAddress: Address, collectionPublicPath: PublicPath) {

        let metadataViewsCap = getAccount(receiverAddress).getCapability<&{MetadataViews.ResolverCollection}>(collectionPublicPath)

        let receiverCap = getAccount(receiverAddress).getCapability<&{NonFungibleToken.Receiver}>(collectionPublicPath)
        let collectionPublicCap = getAccount(receiverAddress).getCapability<&{NonFungibleToken.CollectionPublic}>(collectionPublicPath)

        if !receiverCap.check() && !collectionPublicCap.check() {
            emit TicketRedeemFailed(receiver: receiverAddress, receiverName: FIND.reverseLookup(receiverAddress), ticketID: ticketID, type: type.identifier, remark: "invalid capability")
            return
        }

        let shelf = LostAndFound.borrowShelfManager().borrowShelf(redeemer: receiverAddress) ?? panic("No items to redeem for this user: ".concat(receiverAddress.toString()))

        let bin = shelf.borrowBin(type: type) ?? panic("No items to redeem for this user: ".concat(receiverAddress.toString()))
        let ticket = bin.borrowTicket(id: ticketID) ?? panic("No items to redeem for this user: ".concat(receiverAddress.toString()))
        let nftID = ticket.getNonFungibleTokenID() ?? panic("The item you are trying to redeem is not an NFT")

        let sender = ticket.getFlowRepaymentAddress()
        let memo = ticket.memo

        // if receiverCap is valid, pass that in, otherwise pass collectionPublicCap
        shelf.redeem(type: type, ticketID: ticketID, receiver: receiverCap.check() ? receiverCap : collectionPublicCap)
        var item : FindViews.ViewReadPointer? = nil
        var display : MetadataViews.Display? = nil
        var collectionDisplay : MetadataViews.NFTCollectionDisplay? = nil

        if metadataViewsCap.check() {
            item = FindViews.ViewReadPointer(cap: metadataViewsCap, id: nftID)
            display = item!.getDisplay()
            collectionDisplay = MetadataViews.getNFTCollectionDisplay(item!.getViewResolver())
        }

        var senderName : String? = nil 
        if sender != nil {
            senderName = FIND.reverseLookup(sender!)
        }
        emit NFTDeposited(receiver: receiverAddress, receiverName: FIND.reverseLookup(receiverAddress), sender: sender, senderName: senderName, type: type.identifier, id: nftID, uuid: item?.uuid, memo: memo, name: display?.name, description: display?.description, thumbnail: display?.thumbnail?.uri(), collectionName: collectionDisplay?.name, collectionImage: collectionDisplay?.squareImage?.file?.uri())
        emit TicketRedeemed(receiver: receiverAddress, receiverName: FIND.reverseLookup(receiverAddress), ticketID: ticketID, type: type.identifier)

    }

    // Check 
    pub fun getTickets(user: Address, specificType: Type?) : {String : [LostAndFoundHelper.Ticket]} {

        let allTickets : {String : [LostAndFoundHelper.Ticket]} = {}

        let ticketTypes = LostAndFound.getRedeemableTypes(user) 
        for type in ticketTypes {
            if specificType != nil {
                if !type.isSubtype(of: specificType!) {
                    continue
                }
            }

            let ticketInfo : [LostAndFoundHelper.Ticket] = []
            let tickets = LostAndFound.borrowAllTicketsByType(addr: user, type: type)

            let shelf = LostAndFound.borrowShelfManager().borrowShelf(redeemer: user)!

            let bin = shelf.borrowBin(type: type)!
            let ids = bin.getTicketIDs()
            for id in ids {
            let ticket = bin.borrowTicket(id: id)!
                ticketInfo.append(LostAndFoundHelper.Ticket(ticket, id: id))
            }
            allTickets[type.identifier] = ticketInfo
        }

        return allTickets
    }

    pub fun getTicketIDs(user: Address, specificType: Type?) : {String : [UInt64]} {

        let allTickets : {String : [UInt64]} = {}

        let ticketTypes = LostAndFound.getRedeemableTypes(user) 
        for type in ticketTypes {
            if specificType != nil {
                if !type.isSubtype(of: specificType!) {
                    continue
                }
            }

            let ticketInfo : [UInt64] = []
            let tickets = LostAndFound.borrowAllTicketsByType(addr: user, type: type)

            let shelf = LostAndFound.borrowShelfManager().borrowShelf(redeemer: user)!

            let bin = shelf.borrowBin(type: type)!
            ticketInfo.appendAll(bin.getTicketIDs())

            allTickets[type.identifier] = ticketInfo
        }

        return allTickets
    }

    // Check for all types that are in Lost and found which are NFTs
    pub fun getSpecificRedeemableTypes(user: Address, specificType: Type?) : [Type] {
        let allTypes : [Type] = []
        if specificType != nil {
            for type in LostAndFound.getRedeemableTypes(user) {
                if type.isSubtype(of: specificType!) {
                    allTypes.append(type)
                } 
            }
        }
        return allTypes
    }

    // Helper function
    access(contract) fun depositVault(_ vault: @FungibleToken.Vault) : &FungibleToken.Vault {
        let uuid = vault.uuid
        self.storagePaymentVaults[uuid] <-! vault
        return (&self.storagePaymentVaults[uuid] as &FungibleToken.Vault?)!
    }

    access(contract) fun destroyVault(_ uuid: UInt64, cap: Capability<&FlowToken.Vault{FungibleToken.Receiver}>) {
        let vault <- self.storagePaymentVaults.remove(key: uuid) ?? panic("Invalid vault UUID. UUID: ".concat(uuid.toString()))
        if vault.balance != nil {
            let ref = cap.borrow() ?? panic("The flow repayment capability is not valid")
            ref.deposit(from: <- vault)
            return
        }
        destroy vault
    }

    access(contract) fun subsidizeUserStorage(requiredStorage: UInt64, receiverAvailableStorage: UInt64, receiver: Address, vault: &FungibleToken.Vault, sender: Address, uuid: UInt64) : Bool {
        let subsidizeCapacity = requiredStorage - receiverAvailableStorage
        let subsidizeAmount = FlowStorageFees.storageCapacityToFlow(FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(subsidizeCapacity))
        let flowReceiverCap = getAccount(receiver).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        if !flowReceiverCap.check() {
            return false
        }
        let flowReceiver = flowReceiverCap.borrow()! 
        if !flowReceiver.isInstance(Type<@FlowToken.Vault>()){
            return false
        }
        flowReceiver.deposit(from: <- vault.withdraw(amount: subsidizeAmount))

        emit UserStorageSubsidized(receiver: receiver, receiverName: FIND.reverseLookup(receiver), sender: sender, senderName: FIND.reverseLookup(sender), forUUID: uuid, storageFee: subsidizeAmount)
        return true
    }

    init() {
        self.storagePaymentVaults <- {}
    }

}
 
