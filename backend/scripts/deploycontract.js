const fs = require('fs');
const path = require('path');
const { ethers } = require('ethers');
require('dotenv').config();

async function main() {
  // provider (Ganache)
const provider = new ethers.providers.JsonRpcProvider(process.env.GANACHE_RPC);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const abiPath = path.join(__dirname, '../build/VoteRegistry.abi.json');
const binPath = path.join(__dirname, '../build/VoteRegistry.bin');

const abi = JSON.parse(fs.readFileSync(abiPath, 'utf8'));
const bytecode = fs.readFileSync(binPath, 'utf8').toString();

const factory = new ethers.ContractFactory(abi, bytecode, wallet);
const contract = await factory.deploy();
await contract.deployed();
console.log('Contract deployed to:', contract.address);

  // Save address to .env or a file
fs.writeFileSync(path.join(__dirname, '../contract-address.txt'), contract.address);
}

main().catch(console.error);
