import React, { useState } from "react";
import web3 from "../web3";
import scbackend from "../scbackend";
import _ from "underscore";
import { saveAs } from 'file-saver';
import certTxt from '../cert.txt';
import certPem from '../cert.pem';


function Testmanuale({ setMessage }) {
  const [number, setNumber] = useState(0);
  var test_pem_time = useState("");
  var certificate_txt = useState("");
  fetch(certTxt).then(r => r.text()).then(text => {
    //console.log('text decoded:', text);
    certificate_txt = (' ' + text).slice(1);
  });
  const sleep = ms => new Promise(r => setTimeout(r, ms));

  const onTestHandler = async () => {
    //var certificate_pem = "-----BEGINCERTIFICATE-----MIID0jCCArqgAwIBAgIUPsi4pgBuvNEiI2FiZtDGvrXbJYswDQYJKoZIhvcNAQELBQAwTjELMAkGA1UEBhMCSVQxEDAOBgNVBAcMB0JvbG9nbmExDjAMBgNVBAoMBVVuaWJvMQ8wDQYDVQQLDAZVbGlzc2UxDDAKBgNVBAMMA291dDAeFw0yNDAyMDExNTUwMThaFw0zNDAxMjkxNTUwMThaME4xCzAJBgNVBAYTAklUMRAwDgYDVQQHDAdCb2xvZ25hMQ4wDAYDVQQKDAVVbmlibzEPMA0GA1UECwwGVWxpc3NlMQwwCgYDVQQDDANvdXQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDIi/SL4nJ3NBkNyqXbQucsGAMhuHvBMgrR73Mspk2+Fhrg+DHpJ1Syh0pxayiRhRN+lfNkV7bFxGu60OiXuYgVPARWz8JSOKUPH5C/vofgsUCtMaBkqdSvEGftsEqCs4q2l12cFZWNYR6uAVMdAJD5SZbAVBejo/wYOe6eCPE/ykS2QSoYvFwHLaRXZJvpiJNTwyYOA5g/94ykyA7W2/5ZCsFS7XSJAzZEGWjC7ckk0/e/eNmZmGsXjf2VxvfdcAS8P517KITr2dpjWGf9I+l4Q80yBSY0EGV5pgxdDXayV9ernJ1tVA6fnSzxSH1MCwjvA285vX9fjnxR5FwyjP0VAgMBAAGjgacwgaQwDAYDVR0TAQH/BAIwADALBgNVHQ8EBAMCAvQwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMEkGA1UdEQRCMECGKXVybjpNYWNCb29rLVByby0yLmxvY2FsOlVsaXNzZTpHRFNfY2xpZW50ghNNYWNCb29rLVByby0yLmxvY2FsMB0GA1UdDgQWBBRdbmFzC+oSR0Hgq4WsDTb9DWeyQTANBgkqhkiG9w0BAQsFAAOCAQEAYBohy0qruYp5Y3oAOzFuwhQLj+jk3N+JVP3FuY8g0gV2VjF2M3n8n7alEEXhIgWh5aGoj1u1Z6iJ5crZ/FW7yBTByTbPdBcaJGmbJzAJL7VFljhhGKESzjhznf+daJRbxwjSBeKi4IoDNdpmsGjoq5PJQ06VpBGVDLQA8wTgHSCpS4Q6z6olmAc8TqjToS3mFwCRXsQh2F8N1OBcER2tHNed6XzhmnFJq6PmD/2pv0XKTRIM8eF2LXiMStNZSKzKlT3IMRfya+O+ecOjjYgAqtAxfST0QLPpiV13xk0rUvJ2H/GaoeJ8EtU9SmzQOsLbTUOUkexD7m4JtQoS8v6ctQ==-----ENDCERTIFICATE-----"
   var expireDate = 2022162618;
   //console.log(certificate_txt);
   for(var i = 0; i < number; i++){
      setMessage("Running test n." + i);
      test_pem_time += i + " - " + Date.now() + " - ";
      try {
         await scbackend.methods.addCertificate(certificate_txt,expireDate).send({
           from: web3.eth.defaultAccount,
           gas: '10000000',
       });
       test_pem_time += "sent "+Date.now() + " - ";
       } catch (err) {
         setMessage("ERROR (did you remember to previously load the wallet?)");
         console.log(err)
       }
       sleep(2000);
       test_pem_time += "\n";    
   }
   setMessage("TESTS" + number + " done");
   console.log(test_pem_time);
  };

  const handleDownload = () => {
   const file = new Blob([test_pem_time], { type: 'text/plain;charset=utf-8' });
   saveAs(file, 'test_txt.txt');
 };

  return (
    <div>
      <h4>Run time tests</h4>
      <label htmlFor="enter-value">Insert the number of send and receive tests:</label>
        <input
          number="number-value"
          value={number}
          onChange={(event) => setNumber(event.target.value)}
        />
      <br></br>
      <br></br>
      <button className="button" onClick={onTestHandler}>Run tests</button>
      <br></br>
      <br></br>
      <button className="button" onClick={handleDownload}> Download results </button>
    </div>
    
  );
}

export default Testmanuale;
