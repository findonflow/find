package main

import . "github.com/bjartek/overflow"

func main() {

	o := Overflow(WithNetwork("mainnet"), WithGlobalPrintOptions())

	o.Tx(`
import FLOAT from 0x2d4c3caffbeab845
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import GrantedAccountAccess from 0x2d4c3caffbeab845
import FlowStorageFees from 0xe467b9dd11fa00df

transaction(forHost: Address, eventId: UInt64, recipients: [Address]) {

	let FLOATEvents: &FLOAT.FLOATEvents
	let FLOATEvent: &FLOAT.FLOATEvent
	let RecipientCollections: [&FLOAT.Collection{NonFungibleToken.CollectionPublic}]

	prepare(acct: AuthAccount) {
		// SETUP COLLECTION
    if acct.borrow<&FLOAT.Collection>(from: FLOAT.FLOATCollectionStoragePath) == nil {
        acct.save(<- FLOAT.createEmptyCollection(), to: FLOAT.FLOATCollectionStoragePath)
        acct.link<&FLOAT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, FLOAT.CollectionPublic}>
                (FLOAT.FLOATCollectionPublicPath, target: FLOAT.FLOATCollectionStoragePath)
    }

    // SETUP FLOATEVENTS
    if acct.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath) == nil {
      acct.save(<- FLOAT.createEmptyFLOATEventCollection(), to: FLOAT.FLOATEventsStoragePath)
      acct.link<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic, MetadataViews.ResolverCollection}>
                (FLOAT.FLOATEventsPublicPath, target: FLOAT.FLOATEventsStoragePath)
    }

    // SETUP SHARED MINTING
    if acct.borrow<&GrantedAccountAccess.Info>(from: GrantedAccountAccess.InfoStoragePath) == nil {
        acct.save(<- GrantedAccountAccess.createInfo(), to: GrantedAccountAccess.InfoStoragePath)
        acct.link<&GrantedAccountAccess.Info{GrantedAccountAccess.InfoPublic}>
                (GrantedAccountAccess.InfoPublicPath, target: GrantedAccountAccess.InfoStoragePath)
    }

		if forHost != acct.address {
      let FLOATEvents = acct.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath)
                        ?? panic("Could not borrow the FLOATEvents from the signer.")
      self.FLOATEvents = FLOATEvents.borrowSharedRef(fromHost: forHost)
    } else {
      self.FLOATEvents = acct.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath)
                        ?? panic("Could not borrow the FLOATEvents from the signer.")
    }

		self.FLOATEvent = self.FLOATEvents.borrowEventRef(eventId: eventId) ?? panic("This event does not exist.")
		self.RecipientCollections = []
    for recipient in recipients {
      if FlowStorageFees.defaultTokenAvailableBalance(recipient) > 0.003 {
        if let recipientCollection = getAccount(recipient).getCapability(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection{NonFungibleToken.CollectionPublic}>() {
          self.RecipientCollections.append(recipientCollection)
        }
      }
    }
	}

	execute {
		//
		// Give the "recipients" a FLOAT from the event with "id"
		//

		self.FLOATEvent.batchMint(recipients: self.RecipientCollections)
		log("Distributed the FLOAT.")
	}
}
`,
		WithSigner("find"),
		WithArg("forHost", "find"),
		WithArg("eventId", 419046884),
		WithAddresses("recipients", "0x0ccc515c9eb2db31", "0x46d6fb10be71d261", "0x4260ef47d4b44336", "0x53eb546c815a91cc", "0x02d84224d1aa318e", "0x142935d2b08885bb", "0xcee95bd7c5bd993a", "0x22613f6a9fe740e8", "0xcee95bd7c5bd993a", "0x62c4557bf0e6f559", "0xea6b3b9e8df9164e", "0x47b1de37e8d86e29", "0x91b508315be4545c", "0x18d7e8fd44629257", "0x51664caf2b7550ef", "0x42f8becfea8d6c3b", "0x57ba2117c1c7132b", "0xaf8503b01cb78b2f", "0xb40f0bef13757ef8", "0xe54b9b714b15760c", "0x5dea7a65de215c37", "0x830c83654c015c76", "0xa67143ef9c32b407", "0x5fba88b1c1f692c4", "0x33c221718d0b93ca", "0xb8023f7992b2858d", "0xeb2fa201fa3a8fad", "0x1547db33067fdfd8", "0x06a4104a9fd67dd6", "0x58ce9dd1302b7941", "0x4155bbb6d3a18803", "0xd38e4d0b4ea7ae3d", "0xc85a332060b51589", "0x93d12322aa2f960b", "0xeb219b354507ea7d", "0xe6d95eb8a1356d19", "0x25c28d063e66365e", "0x4ecf6aaa3a6bfe3a"),
	)

}
