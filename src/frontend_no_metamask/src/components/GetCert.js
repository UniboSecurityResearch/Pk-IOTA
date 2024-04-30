import React, { useState } from "react";
import web3 from "../web3";
import scbackend from "../scbackend";

function GetCert({ setMessage }) {
  const [id, setId] = useState(0);
  const onGetCertHandler = async () => {
    const accounts = await web3.eth.getAccounts();

    setMessage("Waiting on transaction success...");

    const certificate = await scbackend.methods.getCertificateByID(id).call({
        from: accounts[0]
    });

    setMessage("Cert data: ID: "+id+" \
    Certificate: "+certificate[0]+"   \
    expire Date: "+certificate[1]);
  };

  return (
    <div>
      <h4>Retrieve certificate from blockchain</h4>
      <label htmlFor="enter-value">Insert the ID of the certificate:</label>
        <input
          id="id-value"
          value={id}
          onChange={(event) => setId(event.target.value)}
        /><br></br>
      <button class="button" onClick={onGetCertHandler}>Get Certificate data</button>
    </div>
  );
}

export default GetCert;
