package main

import (
	"github.com/bjartek/overflow"
	"github.com/davecgh/go-spew/spew"
)

func main() {

	o := overflow.NewOverflowMainnet().Start()

	funds := []string{
		"0x8630fa754bf11151",
		"0x3fd034c13156a6ce",
		"0x368b4f175831543a",
		"0x196c1869b10635b1",
		"0x081f897e8b5dc9f9",
		"0x5a16175a09403578",
		"0x9627d55ad751fdf3",
		"0xe24b9226f4fc1ffa",
	}

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

	spew.Dump(funds)
	for account, name := range addresses {
		o.TransactionFromFile("registerAdmin").
			SignProposeAndPayAs("find-admin").
			Args(o.Arguments().StringArray(name).RawAccount(account)).
			RunPrintEventsFull()

	}
}
