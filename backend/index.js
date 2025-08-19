// backend/index.js
require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const helmet = require('helmet');
const mysql = require('mysql2/promise');

const app = express();
app.use(helmet());
app.use(cors());
app.use(bodyParser.json());

// DB pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'voting_system',
  waitForConnections: true,
  connectionLimit: 10
});

// simple test route
app.get('/', (req, res) => res.send('Voting backend running'));

// attach routes (we will create files)
const voterRoutes = require('./routes/voters')(pool);
app.use('/api/voters', voterRoutes);
const voteRoutes = require('./routes/votes')(pool);
app.use('/api/votes', voteRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
