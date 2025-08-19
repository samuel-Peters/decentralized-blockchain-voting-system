const express = require('express');
const mysql = require('mysql2/promise');
const Web3 = require('web3');
const app = express();
app.use(express.json());

// MySQL connection
const db = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'voting_system'
});

// Web3 setup for Ganache
const web3 = new Web3('http://127.0.0.1:7545');
const contractAddress = '0x4F339F243aDEF9E6c10e642b8CB652354975a1dA';
const contractABI = [/* Add ABI from compiled Voting.sol */];

// Validate OTP (simplified)
function validateOTP(otp) {
    return otp && otp.length === 6 && /^\d+$/.test(otp);
}

// Generate blockchain hash (simplified)
async function generateBlockchainHash(voter_id, candidate_id) {
    return web3.utils.sha3(voter_id + candidate_id + Date.now());
}

// Store hash on Ganache
async function storeHashOnGanache(hash) {
    const contract = new web3.eth.Contract(contractABI, contractAddress);
    const accounts = await web3.eth.getAccounts();
    await contract.methods.storeVote(hash).send({ from: accounts[0] });
}

// Login endpoint
app.post('/login', async (req, res) => {
    const { email, otp } = req.body;
    try {
        if (!validateOTP(otp)) {
            return res.status(400).json({ error: 'Invalid OTP' });
        }
        const [voters] = await db.query('SELECT * FROM voter WHERE email = ? AND status = "active"', [email]);
        if (voters.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        await db.query('INSERT INTO blockchain_log (action, payload) VALUES (?, ?)', 
            ['Login', JSON.stringify({ voter_id: voters[0].voter_id, email })]);
        res.json({ message: 'Login successful', voter_id: voters[0].voter_id });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Vote endpoint
app.post('/vote', async (req, res) => {
    const { voter_id, candidate_id } = req.body;
    try {
        const [voters] = await db.query('SELECT * FROM voter WHERE voter_id = ? AND status = "active"', [voter_id]);
        if (voters.length === 0) {
            return res.status(400).json({ error: 'Invalid voter' });
        }
        const [candidates] = await db.query('SELECT * FROM candidate WHERE candidate_id = ?', [candidate_id]);
        if (candidates.length === 0) {
            return res.status(400).json({ error: 'Invalid candidate' });
        }
        const election_id = candidates[0].election_id;
        const [elections] = await db.query('SELECT * FROM election WHERE election_id = ?', [election_id]);
        if (elections.length === 0) {
            return res.status(400).json({ error: 'Invalid election' });
        }
        const now = new Date();
        if (elections[0].status !== 'open' || now < elections[0].start_time || now > elections[0].end_time) {
            return res.status(400).json({ error: 'Election not open' });
        }
        const [votes] = await db.query('SELECT * FROM vote WHERE voter_id = ? AND election_id = ?', [voter_id, election_id]);
        if (votes.length > 0) {
            return res.status(400).json({ error: 'You have already voted in this election' });
        }
        const vote_hash = await generateBlockchainHash(voter_id, candidate_id);
        await db.query('INSERT INTO vote (voter_id, candidate_id, election_id, vote_hash) VALUES (?, ?, ?, ?)', 
            [voter_id, candidate_id, election_id, vote_hash]);
        await storeHashOnGanache(vote_hash);
        await db.query('INSERT INTO blockchain_log (action, payload) VALUES (?, ?)', 
            ['Stored vote', JSON.stringify({ voter_id, candidate_id, election_id, vote_hash })]);
        res.json({ message: 'Vote recorded' });
    } catch (err) {
        console.error('Vote error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Results endpoint
app.get('/results/:election_id', async (req, res) => {
    const { election_id } = req.params;
    try {
        const [results] = await db.query(
            `SELECT c.candidate_id, c.name, c.description, COUNT(v.vote_id) as vote_count
            FROM candidate c
            LEFT JOIN vote v ON c.candidate_id = v.candidate_id
            c.election_id = ?
            GROUP BY c.candidate_id, c.name, c.description
            ORDER BY vote_count DESC`, [election_id]
        );
        res.json(results);
    } catch (err) {
        console.error('Results error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.listen(3000, () => console.log('Server running on port 3000'));