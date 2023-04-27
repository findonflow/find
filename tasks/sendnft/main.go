package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithNetwork("testnet"))

	nftType := "A.3e5b4c627064625d.Flomies.NFT"
	receiverAddress := "0x70df6ccc9632a4dd"
	id := uint64(111502980)

	o.Tx("sendNFTs",
		WithSigner("find"),
		WithArg("nftIdentifiers", []string{nftType}),
		WithArg("allReceivers", []string{receiverAddress}),
		WithArg("ids", []uint64{id}),
		WithArg("memos", []string{"Maximus!!!"}),
		WithArg("donationTypes", `[nil]`),
		WithArg("donationAmounts", `[nil]`),
		WithArg("findDonationType", nil),
		WithArg("findDonationAmount", nil),
	).Print()
}
