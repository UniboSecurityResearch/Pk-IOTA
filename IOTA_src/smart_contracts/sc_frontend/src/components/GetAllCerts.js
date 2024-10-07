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
    var certString = "";

    setMessage("Waiting on transaction success...");

    const certificates = await scbackend.methods.getAllCertificates().call({
        from: web3.eth.defaultAccount
    });

    var i = 0;

    for (i = 0; i < certificates.length; i++){
      const certificate = await scbackend.methods.getCertificateByID(certificates[i]).call({
        from: web3.eth.defaultAccount
      });
      if(certificates[i] != 0)
        {
          certString+="Certificate data: ID: "+certificates[i]+" \
          certificate: "+certificate[0]+"   \n \
          expire Date: "+certificate[1]+"   \n \
          revoked:"+ certificate[2] + "\n \n";
        }
        else if(i==0)
          {
            certString = "No valid certificates";
          }
      //if the next certificate IDs is 0, from the contract code v1, it means that there are no more valid certificates
      if (i < (certificates.length-1) && certificates[i+1] == 0)
      {
        break;
      }
   }
   setMessage(render(certString));

  };

  return (
    <div>
      <h4>Extract all the VALID certificates from the IOTA blockchain</h4>
      <button className="button" onClick={onGetAllCertsHandler}>Get All</button>
    </div>
  );
}

export default GetAllCerts;
