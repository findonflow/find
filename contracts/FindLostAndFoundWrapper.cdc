import FungibleToken from "./standard/FungibleToken.cdc"
import FlowStorageFees from "./standard//FlowStorageFees.cdc"
import FlowToken from "./standard//FlowToken.cdc"
import NonFungibleToken from "./standard//NonFungibleToken.cdc"
import MetadataViews from "./standard//MetadataViews.cdc"
import FeeEstimator from "./standard//FeeEstimator.cdc"
import LostAndFound from "./standard//LostAndFound.cdc"
import FIND from "./FIND.cdc"
import FindViews from "./FindViews.cdc"


pub contract FindLostAndFoundWrapper {

    pub event NFTDeposited(receiver: Address, receiverName: String?, sender: Address?, senderName: String?, type: String, id: UInt64?, uuid: UInt64?, memo: String?, name: String?, description: String?, thumbnail: String?)
    pub event TicketDeposited(receiver: Address, receiverName: String?, sender: Address, senderName: String?, ticketID: UInt64, type: String, id: UInt64, uuid: UInt64, memo: String?, name: String?, description: String?, thumbnail: String?)
    pub event TicketRedeemed(receiver: Address, ticketID: UInt64, type: String)

    pub let nftInfo : {UInt64 : NFTInfo}

    pub struct NFTInfo {
        pub let sender: Address 
        pub let id: UInt64 
        pub let uuid: UInt64 
        pub let type: Type 
        pub let display: MetadataViews.Display 
        pub let ticketID : UInt64
        
        init(sender: Address , id: UInt64 , uuid: UInt64, type: Type ,display: MetadataViews.Display, ticketID: UInt64) {
            self.sender=sender
            self.id=id
            self.uuid=uuid
            self.type=type
            self.display=display
            self.ticketID=ticketID
        }
    }

    pub struct TicketInfo {

        pub let name : String? 
        pub let description : String? 
        pub let thumbnail : String? 
        pub let memo : String? 
        pub let type: Type 
        pub let ticketID: UInt64
        pub let nftInfo: NFTInfo?

        init(_ ref: &LostAndFound.Ticket, ticketID: UInt64, nftInfo: NFTInfo?) {
            self.name = ref.display?.name
            self.description = ref.display?.description
            self.thumbnail = ref.display?.thumbnail?.uri()
            self.memo = ref.memo
            self.type = ref.type
            self.ticketID = ticketID
            self.nftInfo = nftInfo
        }

    }

    // Deposit 
    pub fun depositNFT(
        receiverCap: Capability<&{NonFungibleToken.Receiver}>,
        item: FindViews.AuthNFTPointer,
        memo: String?,
        storagePayment: &FungibleToken.Vault,
        flowTokenRepayment: Capability<&FlowToken.Vault{FungibleToken.Receiver}>?
    ) {

        let receiverName = FIND.reverseLookup(receiverCap.address)
        let sender = item.owner()
        let senderName = FIND.reverseLookup(sender)

        let display = item.getDisplay()
        let id = item.id 
        let uuid = item.uuid
        let type = item.getItemType()

        // Try to send before using Lost & FIND
        if receiverCap.check() {
            receiverCap.borrow()!.deposit(token: <- item.withdraw())
            emit NFTDeposited(receiver: receiverCap.address, receiverName: receiverName, sender: sender, senderName: senderName, type: type.identifier, id: id, uuid: uuid, memo: memo, name: display.name, description: display.description, thumbnail: display.thumbnail.uri())
            return
        }

        let estimated <- LostAndFound.estimateDeposit(redeemer: receiverCap.address,item: <- item.withdraw(),memo: memo,display: display)
        let ticketID = estimated.uuid + 1

        LostAndFound.deposit(
            redeemer: receiverCap.address,
            item: <-estimated.withdraw(),
            memo: memo,
            display: display,
            storagePayment: storagePayment,
            flowTokenRepayment: flowTokenRepayment
        )

        FindLostAndFoundWrapper.nftInfo[item.uuid] = FindLostAndFoundWrapper.NFTInfo(sender: sender , id: id , uuid: uuid, type: type ,display: display, ticketID:ticketID)

        // change this later 
        emit TicketDeposited(receiver: receiverCap.address, receiverName: receiverName, sender: sender, senderName: senderName, ticketID: ticketID, type: type.identifier, id: id, uuid: uuid, memo: memo, name: display.name, description: display.description, thumbnail: display.thumbnail.uri())
        destroy estimated
    }

    // Redeem 
    pub fun redeemNFT(type: Type, ticketID: UInt64, receiver: Capability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>) {

        if receiver.check() {
            panic("invalid capability")
        }

        let shelf = LostAndFound.borrowShelfManager().borrowShelf(redeemer: receiver.address) ?? panic("No items to redeem for this user: ".concat(receiver.address.toString()))

        let bin = shelf.borrowBin(type: type) ?? panic("No items to redeem for this user: ".concat(receiver.address.toString()))
        let ticket = bin.borrowTicket(id: ticketID) ?? panic("No items to redeem for this user: ".concat(receiver.address.toString()))


        shelf.redeem(type: type, ticketID: ticketID, receiver: receiver)
        if let nftInfo = FindLostAndFoundWrapper.nftInfo.remove(key: ticketID) {
            let senderName = FIND.reverseLookup(nftInfo.sender)
            emit NFTDeposited(receiver: receiver.address, receiverName: FIND.reverseLookup(receiver.address), sender: nftInfo.sender, senderName: senderName, type: type.identifier, id: nftInfo.id, uuid: nftInfo.uuid, memo: ticket.memo, name: ticket.display?.name, description: ticket.display?.description, thumbnail: ticket.display?.thumbnail?.uri())
        } else {
            emit NFTDeposited(receiver: receiver.address, receiverName: FIND.reverseLookup(receiver.address), sender: nil, senderName: nil, type: type.identifier, id: nil, uuid: nil, memo: ticket.memo, name: ticket.display?.name, description: ticket.display?.description, thumbnail: ticket.display?.thumbnail?.uri())
        }
        emit TicketRedeemed(receiver: receiver.address, ticketID: ticketID, type: type.identifier)

    }

    // Check 
    pub fun getTickets(user: Address, specificType: Type?) : {String : [FindLostAndFoundWrapper.TicketInfo]} {

        let allTickets : {String : [FindLostAndFoundWrapper.TicketInfo]} = {}

        let ticketTypes = LostAndFound.getRedeemableTypes(user) 
        for type in ticketTypes {
            if specificType != nil {
                if !type.isInstance(specificType!) {
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
                let nftInfo = FindLostAndFoundWrapper.nftInfo[id]
                ticketInfo.append(FindLostAndFoundWrapper.TicketInfo(ticket, ticketID: id, nftInfo: nftInfo))
            }
            allTickets[type.identifier] = ticketInfo
        }

        return allTickets
    }

    init() {
        self.nftInfo = {}
    }

}
 