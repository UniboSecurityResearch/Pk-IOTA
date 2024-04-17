import React, { useState } from "react";
import web3 from "../web3";
import scbackend from "../scbackend";

function render(text) {
  return (
  <div>
      {text.split("\n").map((i,key) => {
          return <div key={key}>{i}</div>;
      })}
  </div>);
}

function GetAllCerts({ setMessage }) {
  const onGetAllCertsHandler = async () => {
    const accounts = await web3.eth.getAccounts();
    var certString = "";

    setMessage("Waiting on transaction success...");

    const certificates = await scbackend.methods.getAllCertificates().call({
        from: accounts[0]
    });

    var i = 0;

    for (i = 0; i < certificates.length; i++){
      const certificate = await scbackend.methods.getCertificateByID(certificates[i]).call({
        from: accounts[0]
    });

    
    certString+="Certificate data: ID: "+certificates[i]+" \
    certificate: "+certificate[0]+"   \
    expire Date: "+certificate[1]+ "\n";
   }
   setMessage(render(certString));

  };

  return (
    <div>
      <h4>Extract all the certificates</h4>
      <button class="button" onClick={onGetAllCertsHandler}>Get All</button>
    </div>
  );
}

export default GetAllCerts;
