const Web3 = require("web3");
var web3   = new Web3("ADD INFURA WEBSOCKET ENDPOINT + PROJECT ID HERE");

contractAddress = "ADD CONTRACT ADDRESS HERE";

listenForEvent();
async function listenForEvent(){
	console.log("Waiting for event");
	var subscription = web3.eth.subscribe('logs', {
		address: contractAddress,
	}, function(error, result){
		if (!error)
			console.log(result);
	});
}
