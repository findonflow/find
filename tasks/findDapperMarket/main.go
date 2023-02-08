package main

import (
	. "github.com/bjartek/overflow"
	"github.com/findonflow/find/findGo"
)

func main() {

	o := Overflow(WithNetwork("testnet"), WithGlobalPrintOptions())

	ot := findGo.OverflowUtils{
		O: o,
	}

	ot.UpgradeFindDapperTenantSwitchboard()

}
