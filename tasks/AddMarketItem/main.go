package main

import (
	. "github.com/bjartek/overflow"
	"github.com/findonflow/find/findGo"
)

func main() {
	ot := findGo.OverflowUtils{
		O: Overflow(
			WithNetwork("testnet"),
		),
	}

	ot.AddItem("Dandy")
}
