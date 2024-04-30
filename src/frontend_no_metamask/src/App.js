import React, { useEffect, useState } from "react";
import "./App.css";
import web3 from "./web3";
import _, { map } from 'underscore';
import scbackend from "./scbackend";
import AddCert from "./components/AddCert";
import GetCert from "./components/GetCert";
import GetAllCerts from "./components/GetAllCerts";

var done = false;
var loaded = false;
// Subscriber method
const subscribeLogEvent = (contract, eventName) => {
  console.log(contract._jsonInterface)
  const eventJsonInterface = _.find(
    contract._jsonInterface,
    o => o.name === eventName && o.type === 'event',
  )
  const subscription = web3.eth.subscribe('logs', {
    address: contract.options.address,
    topics: [eventJsonInterface.signature]
  }, (error, result) => {
    if (!error) {
      console.log("CI SIAMO")
      const eventObj = web3.eth.abi.decodeLog(
        eventJsonInterface.inputs,
        result.data,
        result.topics.slice(1)
      )
      if(eventObj[1]==0){
        var eventString = "The booking of client " + eventObj[0] + " has failed: invalid parameters";
        document.getElementById("whereToPrint").innerHTML += "<p>"+eventString+"</p>";
      }
      else{
        var eventString = "The booking of client " + eventObj[0] + " has been confirmed with ID: "+ eventObj[1];
        document.getElementById("whereToPrint").innerHTML += "<p>"+eventString+"</p>";
      }
    }
    else{
      var eventString = "An event has not been fired :(" + result
      console.log("error subscribe");
      document.getElementById("whereToPrint").innerHTML += "<p>"+eventString+"</p>";
    }
  })
};


/*
async function listenForEvent(){
	console.log("Waiting for event");
	var subscription = web3.eth.subscribe('logs', {
		address: scbackend.options.address,
	}, function(error, result){
		if (!error)
			console.log(result);
    else console.log(error);
	});
}*/


function App() {
  
  const [message, setMessage] = useState("");
  const [backend, setBackend] = useState("");
  const [backendBalance, setBalance] = useState("");

  useEffect(() => {
    async function fetchManager() {
      const accounts = await web3.eth.getAccounts();
      const backend = await scbackend.methods.getBackend().call({
        from: accounts[0]
    });
      const balance = await web3.eth.getBalance(accounts[0]);
      setBackend(backend);
      setBalance(balance);
      loaded = true;
    }
    if(!done && loaded)
    {
      done = true;
      console.log("okletsgo");
      //subscribeLogEvent(scbackend,"sendCertificate");
      listenForEvent();
    }
    fetchManager();
    
  });

  
  

  return (
    <div>
      <h2>Backend Contract</h2>
      <p>This contract is deployed by {backend}</p>
      <p>
                {web3.utils.fromWei(backendBalance, "ether")} SMR!
      </p>
      <hr />
      <pre id="whereToPrint"></pre>
      <hr />
      <AddCert setMessage={setMessage} />
      <hr />
      <br></br>
      <GetCert setMessage={setMessage} />
      <br></br>
      <hr />
      <GetAllCerts setMessage={setMessage} />
      <hr />
      <br></br>
      <hr />
      <h3>{message}</h3>
      <hr />
      <br></br>
      <hr />
      <h4>@beawareoftheg GG</h4>
    </div>
  );
}

export default App;
