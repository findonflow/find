import LostAndFoundHelper from "../contracts/standard/LostAndFoundHelper.cdc"
import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main(user: String) : Report {

	if let address = FIND.resolve(user) {
		let runTimeType = Type<@NonFungibleToken.NFT>()

		let ticketsInfo = FindLostAndFoundWrapper.getTickets(user: address, specificType: runTimeType)

		let ticketIds : {String : [UInt64]} = {}
		let NFTCatalogTicketInfo : {String : [LostAndFoundHelper.Ticket]} = {}
		for type in ticketsInfo.keys {
			// check if this type is in NFTCatalog
			let nftCatalog = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: type)
			var inNFTCatalog : Bool = true 
			if nftCatalog == nil {
				inNFTCatalog = false
			}

			// append id in array
			let id : [UInt64] = []
			for ticket in ticketsInfo[type]! {
				if ticket.ticketID != nil {
					id.append(ticket.ticketID!)
				}
			}
			ticketIds[type] = id

			// If it is in NFT Catalog, add it in NFTCatalogTicketInfo
			if inNFTCatalog {
				NFTCatalogTicketInfo[type] = ticketsInfo.remove(key: type)
			}
		}

		return Report(nftCatalogTicketInfo : NFTCatalogTicketInfo, ticketInfo : ticketsInfo, ticketIds : ticketIds, error: nil)
	}
	return logErr("Cannot resolve user. User : ".concat(user))
}


pub struct Report {

	pub let nftCatalogTicketInfo : {String : [LostAndFoundHelper.Ticket]}
	pub let ticketInfo : {String : [LostAndFoundHelper.Ticket]}
	pub let ticketIds : {String : [UInt64]}
	pub let error : String?

	init(nftCatalogTicketInfo : {String : [LostAndFoundHelper.Ticket]}, ticketInfo : {String : [LostAndFoundHelper.Ticket]}, ticketIds : {String : [UInt64]}, error: String?) {
		self.nftCatalogTicketInfo = nftCatalogTicketInfo
		self.ticketInfo = ticketInfo
		self.ticketIds = ticketIds
		self.error = error
	}
}

pub fun logErr(_ err: String) : Report {
	return Report(nftCatalogTicketInfo: {}, ticketInfo : {}, ticketIds : {} , error: err)
}