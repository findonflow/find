package main

import (
	"github.com/bjartek/overflow"
)

func main() {

	o := overflow.Overflow(overflow.WithNetwork("mainnet"))

	addresses := map[string]string{

		"0x7f785e9ddaf68333": "midnight",
		"0x549802c4c6edbd04": "golem",
		"0x3358c97ffb850b8b": "flown",
		"0x746e3935e2426b77": "pudge",
		"0xb7ffae8d70d85dda": "stepswon",
		"0x451459400329a010": "moloch",
		"0x059935060d6a1cda": "jarmy81",
		"0xb5413e1c4dc81b05": "dtopcu",
		"0xa7b4f0f556f7989e": "suenfts",
		"0x1bdb509d15f75f37": "copperz",
		"0xcc84bafc62de3b21": "nearthur",
		"0xf9e05616ccd4831a": "ezweezy",
		"0x5159075e4cd4324c": "arceus",
	}

	for account, name := range addresses {
		o.Tx("adminRegisterName",
			overflow.WithSigner("find-admin"),
			overflow.WithArg("names", []string{name}),
			overflow.WithArg("user", account),
		).Print()
	}
}
