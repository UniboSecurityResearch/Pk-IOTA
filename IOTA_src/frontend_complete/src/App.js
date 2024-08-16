//TEST TIME
import React, { useEffect, useState } from "react";
import "./App.css";
import web3 from "./web3";
import _ from 'underscore';
import scbackend from "./scbackend";
import AddCert from "./components/AddCert";
import GetCert from "./components/GetCert";
import GetAllCerts from "./components/GetAllCerts";
import WalletForm from "./components/WalletForm";
import RevokeCert from "./components/RevokeCert";
import RevokeCertByID from "./components/RevokeCertByID";
import Test from "./components/Test-manuale";
import { wait } from "@testing-library/user-event/dist/cjs/utils/index.js";
import Testmanuale from "./components/Test-manuale";

var done = false;
// Subscriber method
const subscribeNewCert = (contract, eventName) => {
  const eventJsonInterface = _.find(
    contract._jsonInterface,
    o => o.name === eventName && o.type === 'event',
  )
  const subscription = web3.eth.subscribe('logs', {
    address: contract.options.address,
    topics: [eventJsonInterface.signature]
  }, (error, result) => {
    if (!error) {
      console.log("Event newcert received")
      const eventObj = web3.eth.abi.decodeLog(
        eventJsonInterface.inputs,
        result.data,
        result.topics.slice(1)
      )
      if(eventObj[0]==0){
        var eventString = "A certificate is sent, but with invalid parameters:  " + eventObj[1];
        document.getElementById("whereToPrint").innerHTML += "<p>"+eventString+"</p>";
      }
      else{
        var eventString = "<b>NEW CERTIFICATE</b>:  " + eventObj[0] + " <br> with expire date: "+ eventObj[1];
        document.getElementById("whereToPrint").innerHTML += "<p>"+eventString+"</p>";
      }
    }
    else{
      var eventString = "Error with the handle of event" + result
      console.log("error subscribe add");
      document.getElementById("whereToPrint").innerHTML += "<p>"+eventString+"</p>";
    }
  })
};

const subscribeRevoke = (contract, eventName) => {
  const eventJsonInterface = _.find(
    contract._jsonInterface,
    o => o.name === eventName && o.type === 'event',
  )
  const subscription = web3.eth.subscribe('logs', {
    address: contract.options.address,
    topics: [eventJsonInterface.signature]
  }, (error, result) => {
    if (!error) {
      console.log("Event revoke received")
      const eventObj = web3.eth.abi.decodeLog(
        eventJsonInterface.inputs,
        result.data,
        result.topics.slice(1)
      )
      if(eventObj[0]==0){
        var eventString = "An invalid certificated was rekoved:  " + eventObj[1];
        document.getElementById("whereToPrint").innerHTML += "<p>"+eventString+"</p>";
      }
      else{
        var eventString = "<b>NEW REVOKE</b> This certificate:  " + eventObj[0] + " <br> with expire date: "+ eventObj[1] + " has been revoked";
        document.getElementById("whereToPrint").innerHTML += "<p>"+eventString+"</p>";
      }
    }
    else{
      var eventString = "Error with the handle of event" + result
      console.log("error subscribe revoke");
      document.getElementById("whereToPrint").innerHTML += "<p>"+eventString+"</p>";
    }
  })
};


function App() {
  
  var [loaded, setLoaded] = useState(false);
  const [message, setMessage] = useState("");
  const [backend, setBackend] = useState("");
  const [backendBalance, setBalance] = useState("");

  const agetBalance = async() => {
    const balance = await web3.eth.getBalance(web3.eth.defaultAccount);
    setBalance(balance);
  }

  if(!done && loaded)
    {
      done = true;
      console.log("subscription...");
      agetBalance();
      setTimeout(()=> {subscribeNewCert(scbackend,"sendCertificate");},3000);
      setTimeout(()=> {subscribeRevoke(scbackend,"revokedCertificate");},7000);
      
      
    }

  useEffect(() => {
    async function fetchManager() {
      const backend = await scbackend.methods.getBackend().call();
      setBackend(backend);
    }
    fetchManager();
  });

  return (
    <div>
      <h1>[Pk-IOTA] IIoT IOTA CERTIFICATE MANAGEMENT</h1>
      <h2>Frontend to interact with the Smart Contract</h2>
      <p>This contract is deployed by <b>{backend}</b></p>
      <p>
        You have {web3.utils.fromWei(backendBalance, "ether")} IOTA!
      </p>
      <hr />
      <WalletForm setMessage={setMessage} setLoaded={setLoaded}/>
      <hr />
      List of events:
      <hr />
      <pre id="whereToPrint"></pre>
      <hr />
      <hr />
      <h3>{message}</h3>
      <hr />
      <AddCert setMessage={setMessage} />
      <hr />
      <br></br>
      <hr />
      <RevokeCert setMessage={setMessage} />
      <hr />
      <hr />
      <RevokeCertByID setMessage={setMessage} />
      <hr />
      <br></br>
      <GetCert setMessage={setMessage} />
      <br></br>
      <hr />
      <GetAllCerts setMessage={setMessage} />
      <hr />
      <br></br>
      <br></br>
      <Testmanuale setMessage={setMessage} />
      <hr />
      <h4>@beawareoftheg GG</h4>
    </div>
  );
}

export default App;
