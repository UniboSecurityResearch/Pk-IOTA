import web3 from "./web3";


const address = process.env.REACT_APP_SCBACKEND_ADDRESS;
const abitext = '[{"constant":false,"inputs":[{"name":"certificate","type":"string"},{"name":"expireDate","type":"uint256"}],"name":"addCertificate","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"certificate","type":"string"},{"name":"expireDate","type":"uint256"}],"name":"createStruct","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"name":"certificate","type":"string"},{"indexed":false,"name":"expireDate","type":"uint256"}],"name":"sendCertificate","type":"event"},{"constant":true,"inputs":[],"name":"backend","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"certificateIDs","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getAllCertificates","outputs":[{"name":"","type":"uint256[]"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"id","type":"uint256"}],"name":"getCertificateByID","outputs":[{"name":"","type":"string"},{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getCertificatesNumber","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]';
const abi = JSON.parse(abitext);
console.log(abi);
console.log(address);

export default new web3.eth.Contract(abi, address);
