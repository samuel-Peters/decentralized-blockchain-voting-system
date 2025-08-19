const express = require('express');
const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

module.exports = (pool) => {
const router = express.Router();

// Load ABI and contract address
const abi = JSON.parse(fs.readFileSync(path.join(__dirname, '../artifacts/VoteRegistry.json'), 'utf8')).abi;
const provider = new ethers.providers.JsonRpcProvider(process.env.GANACHE_RPC);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contractAddress = process.env.CONTRACT_ADDRESS; // set after deploy
const contract = new ethers.Contract(contractAddress, abi, wallet);

// Cast a vote (backend)
router.post('/cast', async (req, res) => {
    try {
    const { voter_id, candidate_id, election_id } = req.body;
// 1) Check voter active and not already voted in this election
      const [[voter]] = await pool.query('SELECT * FROM voter WHERE voter_id = ?', [voter_id]);
    if (!voter || voter.status !== 'active') return res.status(400).json({ message: 'Voter not active or not found' });

      const [[existing]] = await pool.query('SELECT * FROM vote WHERE voter_id = ? AND election_id = ?', [voter_id, election_id]);
    if (existing) return res.status(400).json({ message: 'Voter has already voted' });

// 2) Create vote hash (simple)
    const votePayload = `${voter_id}|${candidate_id}|${election_id}|${Date.now()}`;
    const voteHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(votePayload));

// 3) Store on-chain: call contract.storeVote(voteHash)
    const tx = await contract.storeVote(voteHash);
    const receipt = await tx.wait();

// 4) Save in DB
    await pool.query(`INSERT INTO vote (voter_id, candidate_id, election_id, vote_hash, tx_hash) VALUES (?, ?, ?, ?, ?)`,
        [voter_id, candidate_id, election_id, voteHash, receipt.transactionHash]);


+        // 5) Record blockchain_log
    await pool.query('INSERT INTO blockchain_log (action, tx_hash, payload) VALUES (?, ?, ?)', ['storeVote', receipt.transactionHash, voteHash]);

    res.json({ message: 'Vote cast', voteHash, txHash: receipt.transactionHash });

    } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error casting vote' });
    }
});

return router;
}
