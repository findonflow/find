package main

import . "github.com/bjartek/overflow"

func main() {
	o := Overflow(
		WithNetwork("testnet"),
	)

	list := map[uint64][]string{}

	AirdropNameVoucher(list, o)

}

func AirdropNameVoucher(list map[uint64][]string, o *OverflowState) {

	for characters, addrs := range list {
		o.Tx(
			"adminMintAndAirdropNameVoucher",
			WithSigner("find-admin"),
			WithAddresses("users", addrs...),
			WithArg("minCharLength", characters),
		)
	}

}
