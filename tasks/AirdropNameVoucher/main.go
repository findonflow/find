package main

import (
	. "github.com/bjartek/overflow"
	"github.com/samber/lo"
)

func main() {
	o := Overflow(
		WithNetwork("mainnet"),
		WithGlobalPrintOptions(),
	)

	users := lo.RepeatBy(3, func(_ int) string {
		return "0x99bd48c8036e2876"
	})

	list := map[uint64][]string{
		//		3: {""},
		//		4: {""},
		5: users,
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
