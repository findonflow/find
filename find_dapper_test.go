package test_main

import (
	"testing"

	. "github.com/bjartek/overflow/v2"
	"github.com/hexops/autogold"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestFINDDapper(t *testing.T) {
	ot.Run(t, "Should get expected output for register script", func(t *testing.T) {
		ot.O.Script("getMetadataForRegisterDapper",
			WithArg("merchAccount", "find"),
			WithArg("name", "william"),
			WithArg("amount", 5.0),
		).AssertWant(t, autogold.Want("getMetadataForRegisterDapper", map[string]interface{}{
			"amount": 5, "description": "Name :william for DUC 5.00000000",
			"id":       0,
			"imageURL": "https://ik.imagekit.io/xyvsisxky/tr:ot-william,ots-55,otc-58B792,ox-N166,oy-N24,ott-b/https://i.imgur.com/8W8NoO1.png",
			"name":     "william",
		}))
	})

	ot.Run(t, "Should get error if you try to register a name that is too short", func(t *testing.T) {
		ot.O.Tx("devRegisterDapper",
			WithSigner("user5"),
			WithPayloadSigner("dapper"),
			WithArg("merchAccount", "find"),
			WithArg("name", "ur"),
			WithArg("amount", 5.0),
		).AssertFailure(t, "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
	})

	ot.Run(t, "Should get error if you try to register a name that is already claimed", func(t *testing.T) {
		ot.O.Tx("devRegisterDapper",
			WithSigner("user5"),
			WithPayloadSigner("dapper"),
			WithArg("merchAccount", "dapper"),
			WithArg("name", "user1"),
			WithArg("amount", 5.0),
		).AssertFailure(t, "Name already registered")
	})

	ot.Run(t, "Should be able to send lease to another name", func(t *testing.T) {

    fmi, _ :=ot.O.QualifiedIdentifier("FIND", "Moved")
		ot.O.Tx("moveNameToDapper",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("receiver", "user2"),
		).
			AssertSuccess(t).
			AssertEvent(t, fmi , map[string]interface{}{
				"name": "user1",
			})
	})
}
