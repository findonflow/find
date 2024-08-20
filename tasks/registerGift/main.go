package main

import (
	"github.com/bjartek/overflow/v2"
)

func main() {
	o := overflow.Overflow(overflow.WithNetwork("migrationnet"))

	addresses := map[string]string{
		"0xb92dd41eee7b3bfd": "testing",
	}

	for account, name := range addresses {
		o.Tx("adminRegisterName",
			overflow.WithSigner("find-admin"),
			overflow.WithArg("names", []string{name}),
			overflow.WithArg("user", account),
		).Print()
	}
}
