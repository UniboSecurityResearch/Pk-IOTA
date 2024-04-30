import Web3 from 'web3';
import { iotaNetwork } from './config.json';

const web3 = new Web3(new Web3.providers.WebsocketProvider(iotaNetwork));

export default web3;
