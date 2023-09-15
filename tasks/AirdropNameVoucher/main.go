package main

import . "github.com/bjartek/overflow"

func main() {
	o := Overflow(
		WithNetwork("mainnet"),
		WithGlobalPrintOptions(),
	)

	list := map[uint64][]string{
		3: {"0x380d59166ad2008d"},
		5: {
			"0x01e91f47de20ef05",
			"0x357c4382737b46a1",
			"0x76d988a29af9ea8d",
			"0xf5abd0ab244b6a78",
			"0x89a6febfce2215ae",
			"0xe11f527c4c013938",
		},
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
