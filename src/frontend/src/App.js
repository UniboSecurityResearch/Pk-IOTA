import React, { useEffect, useState } from "react";
import "./App.css";
import web3 from "./web3";
import scbackend from "./scbackend";
import AddCert from "./components/AddCert";
//import GetCert from "./components/GetCert";
//import GetAllCerts from "./components/GetAllCerts";


function App() {
  
  const [message, setMessage] = useState("");
  const [backend, setBackend] = useState("");
  //const [players, setPlayers] = useState([]);
  const [backendBalance, setBalance] = useState("");

  useEffect(() => {
    async function fetchManager() {
      const accounts = await web3.eth.getAccounts();
      console.log("aacount:" + scbackend.options.address)
      const backend = await scbackend.methods.getBackend().call({
        from: accounts[0]
    });
      //const players = await scbackend.methods.getPlayers().call();
      const balance = await web3.eth.getBalance(accounts[0]);
      setBackend(backend);
      //setPlayers(players);
      setBalance(balance);
    }
    fetchManager();
  });

  console.log(backend);
  //console.log(players);

  return (
    <div>
      <h2>Backend Contract</h2>
      <p>This contract is deployed by {backend}</p>
      <p>
                {web3.utils.fromWei(backendBalance, "ether")} ether!
      </p>
      <hr />
      <AddCert setMessage={setMessage} />
      <hr />
      <br></br><p>**********************************************</p><br></br>
      
      <hr />
      <hr />
      <h3>{message}</h3>
      <hr />
      <hr />
      <br></br><p>**********************************************</p><br></br>
      <hr />
      <h4>@beawareoftheg GG</h4>
    </div>
  );
}

export default App;
