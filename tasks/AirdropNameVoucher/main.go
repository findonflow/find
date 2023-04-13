package main

import . "github.com/bjartek/overflow"

func main() {
	o := Overflow(
		WithNetwork("mainnet"),
		WithGlobalPrintOptions(),
	)

	list := map[uint64][]string{
		3: {"0x7f97054dc583b63c"},
		4: {"0x7f97054dc583b63c"},
		5: {"0x7f97054dc583b63c"},
	}

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
