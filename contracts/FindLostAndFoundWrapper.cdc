import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import LostAndFound from "./standard/LostAndFound.cdc"
import FIND from "./FIND.cdc"
import FindViews from "./FindViews.cdc"


pub contract FindLostAndFoundWrapper {

    pub event NFTDeposited(receiver: Address, receiverName: String?, sender: Address?, senderName: String?, type: String, id: UInt64?, uuid: UInt64?, memo: String?, name: String?, description: String?, thumbnail: String?, collectionName: String?, collectionImage: String?)
    pub event TicketDeposited(receiver: Address, receiverName: String?, sender: Address, senderName: String?, ticketID: UInt64, type: String, id: UInt64, uuid: UInt64, memo: String?, name: String?, description: String?, thumbnail: String?, collectionName: String?, collectionImage: String?, flowStorageFee: UFix64)
    pub event TicketRedeemed(receiver: Address, ticketID: UInt64, type: String)

    // Mapping of vault uuid to vault.  
    // A method to get around passing the "Vault" reference to Lost and Found to ensure it cannot be hacked. 
    // All vaults should be destroyed after deposit function
    pub let storagePaymentVaults : @{UInt64 : FungibleToken.Vault}
    pub let emptyCollections : @{String : NonFungibleToken.Collection}

    pub struct TicketInfo {
        pub let name : String?
        pub let description : String?
        pub let thumbnail : String?
        pub let memo : String?
        pub let type: Type
        pub let typeIdentifier: String
        pub let ticketID: UInt64

        init(_ ref: &LostAndFound.Ticket, ticketID: UInt64) {
            self.name = ref.display?.name
            self.description = ref.display?.description
            self.thumbnail = ref.display?.thumbnail?.uri()
            self.memo = ref.memo
            self.type = ref.type
            self.typeIdentifier = ref.type.identifier
            self.ticketID = ticketID
        }
    }

    // Deposit 
    pub fun depositNFT(
        receiverCap: Capability<&{NonFungibleToken.Receiver}>,
        item: FindViews.AuthNFTPointer,
        memo: String?,
        storagePayment: @FungibleToken.Vault,
        flowTokenRepayment: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    ) {

        let receiverName = FIND.reverseLookup(receiverCap.address)
        let sender = item.owner()
        let senderName = FIND.reverseLookup(sender)

        let display = item.getDisplay()
        let collectionDisplay = item.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as? MetadataViews.NFTCollectionDisplay
        let id = item.id 
        let uuid = item.uuid
        let type = item.getItemType()

        // Try to send before using Lost & FIND
        if receiverCap.check() {
            receiverCap.borrow()!.deposit(token: <- item.withdraw())
            emit NFTDeposited(receiver: receiverCap.address, receiverName: receiverName, sender: sender, senderName: senderName, type: type.identifier, id: id, uuid: uuid, memo: memo, name: display.name, description: display.description, thumbnail: display.thumbnail.uri(), collectionName: collectionDisplay?.name, collectionImage: collectionDisplay?.squareImage?.file?.uri())
            let flowRepayment = flowTokenRepayment.borrow() ?? panic("Flow repayment capability passed in is not valid. Account : ".concat(flowTokenRepayment.address.toString()))
            flowRepayment.deposit(from: <- storagePayment)
            return
        }

        // Put the payment vault in dictionary and get it's reference
        let vaultUUID = storagePayment.uuid 
        let vaultRef = FindLostAndFoundWrapper.depositVault(<- storagePayment)

        let flowStorageFee = vaultRef.balance
        let ticketID = LostAndFound.deposit(
            redeemer: receiverCap.address,
            item: <- item.withdraw(),
            memo: memo,
            display: display,
            storagePayment: vaultRef,
            flowTokenRepayment: flowTokenRepayment
        )
        // Destroy the vault after the payment. The vault should be 0 in balance
        FindLostAndFoundWrapper.destroyVault(vaultUUID)

        emit TicketDeposited(receiver: receiverCap.address, receiverName: receiverName, sender: sender, senderName: senderName, ticketID: ticketID, type: type.identifier, id: id, uuid: uuid, memo: memo, name: display.name, description: display.description, thumbnail: display.thumbnail.uri(), collectionName: collectionDisplay?.name, collectionImage: collectionDisplay?.squareImage?.file?.uri(), flowStorageFee: flowStorageFee)
    }

    // Redeem 
    pub fun redeemNFT(type: Type, ticketID: UInt64, receiver: Capability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>) {

        if receiver.check() {
            panic("invalid capability")
        }

        let shelf = LostAndFound.borrowShelfManager().borrowShelf(redeemer: receiver.address) ?? panic("No items to redeem for this user: ".concat(receiver.address.toString()))

        let bin = shelf.borrowBin(type: type) ?? panic("No items to redeem for this user: ".concat(receiver.address.toString()))
        let ticket = bin.borrowTicket(id: ticketID) ?? panic("No items to redeem for this user: ".concat(receiver.address.toString()))
        let nftID = ticket.getNonFungibleTokenID() ?? panic("The item you are trying to redeem is not an NFT")


        shelf.redeem(type: type, ticketID: ticketID, receiver: receiver)

        let item = FindViews.ViewReadPointer(cap: receiver, id: nftID)
        let collectionDisplay = item.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as? MetadataViews.NFTCollectionDisplay

        let sender = ticket.getFlowRepaymentAddress()
        var senderName : String? = nil 
        if sender != nil {
            senderName = FIND.reverseLookup(sender!)
        }
        emit NFTDeposited(receiver: receiver.address, receiverName: FIND.reverseLookup(receiver.address), sender: sender, senderName: senderName, type: type.identifier, id: nftID, uuid: item.uuid, memo: ticket.memo, name: ticket.display?.name, description: ticket.display?.description, thumbnail: ticket.display?.thumbnail?.uri(), collectionName: collectionDisplay?.name, collectionImage: collectionDisplay?.squareImage?.file?.uri())
        emit TicketRedeemed(receiver: receiver.address, ticketID: ticketID, type: type.identifier)

    }

    // Check 
    pub fun getTickets(user: Address, specificType: Type?) : {String : [FindLostAndFoundWrapper.TicketInfo]} {

        let allTickets : {String : [FindLostAndFoundWrapper.TicketInfo]} = {}

        let ticketTypes = LostAndFound.getRedeemableTypes(user) 
        for type in ticketTypes {
            if specificType != nil {
                if !type.isSubtype(of: specificType!) {
                    continue
                }
            }

            let ticketInfo : [FindLostAndFoundWrapper.TicketInfo] = []
            let tickets = LostAndFound.borrowAllTicketsByType(addr: user, type: type)

            let shelf = LostAndFound.borrowShelfManager().borrowShelf(redeemer: user)!

            let bin = shelf.borrowBin(type: type)!
            let ids = bin.getTicketIDs()
            for id in ids {
            let ticket = bin.borrowTicket(id: id)!
                ticketInfo.append(FindLostAndFoundWrapper.TicketInfo(ticket, ticketID: id))
            }
            allTickets[type.identifier] = ticketInfo
        }

        return allTickets
    }

    // Helper function
    access(contract) fun depositVault(_ vault: @FungibleToken.Vault) : &FungibleToken.Vault {
        let uuid = vault.uuid
        self.storagePaymentVaults[uuid] <-! vault
        return (&self.storagePaymentVaults[uuid] as &FungibleToken.Vault?)!
    }

    access(contract) fun destroyVault(_ uuid: UInt64) {
        let vault <- self.storagePaymentVaults.remove(key: uuid) ?? panic("Invalid vault UUID. UUID: ".concat(uuid.toString()))
        if vault.balance != nil {
            panic("Cannot destroy non-zero balance vault.")
        }
        destroy vault
    }

    pub fun shuffleStringArray(_ array: [String]) : [String] {
        let newArray : [String] = []
        while array.length > 1 {
            let random = unsafeRandom() % UInt64(array.length)
            newArray.append(array.remove(at: random))
        }
        newArray.append(array.remove(at: 1))
        return newArray
    }

    init() {
        self.storagePaymentVaults <- {}
        self.emptyCollections <- {}
    }

}
 