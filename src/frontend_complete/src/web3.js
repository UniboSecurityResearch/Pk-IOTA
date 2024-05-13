import Web3 from 'web3';
import configIOTA from './config.json';
console.log(configIOTA.iotaNetwork)
const web3 = new Web3(new Web3.providers.WebsocketProvider(configIOTA.iotaNetwork));

export default web3;
