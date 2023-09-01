package main

import (
	"github.com/bjartek/overflow"
)

func main() {

	o := overflow.Overflow(overflow.WithNetwork("mainnet"))

	addresses := map[string]string{
		"0x97bf2205358ff29c": "gieft",
	}

	for account, name := range addresses {
		o.Tx("adminRegisterName",
			overflow.WithSigner("find-admin"),
			overflow.WithArg("names", []string{name}),
			overflow.WithArg("user", account),
		).Print()
	}
}
