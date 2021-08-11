all: demo

#run the demo script on devnet
.PHONY: send
send: deploy
	go run ./tasks/send/main.go

.PHONY: setup
setup: deploy
	go run ./tasks/setup/main.go

#this goal deployes all the contracts to emulator
.PHONY: deploy
deploy:
	flow project deploy 


.PHONY: emulator
emulator:
	flow project start-emulator -v


.phony: test
test:
	go test fin_test.go
