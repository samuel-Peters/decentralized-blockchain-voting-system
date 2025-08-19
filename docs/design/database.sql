CREATE DATABASE IF NOT EXISTS voting_system;
USE voting_system;

CREATE TABLE organization (
    org_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE voter (
    voter_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(30),
    org_id INT NOT NULL,
    public_key TEXT NOT NULL,
    encrypted_public_key TEXT,
    status ENUM('pending','active','deactivated') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (org_id) REFERENCES organization(org_id)
);

CREATE TABLE election (
    election_id INT AUTO_INCREMENT PRIMARY KEY,
    org_id INT NOT NULL,
    name VARCHAR(200) NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    status ENUM('draft','open','closed','archived') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (org_id) REFERENCES organization(org_id)
);

CREATE TABLE candidate (
    candidate_id INT AUTO_INCREMENT PRIMARY KEY,
    election_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (election_id) REFERENCES election(election_id)
);

CREATE TABLE vote (
    vote_id INT AUTO_INCREMENT PRIMARY KEY,
    voter_id INT NOT NULL,
    candidate_id INT NOT NULL,
    election_id INT NOT NULL,
    vote_hash VARCHAR(128) NOT NULL,
    tx_hash VARCHAR(128),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (voter_id) REFERENCES voter(voter_id),
    FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id),
    FOREIGN KEY (election_id) REFERENCES election(election_id)
);

CREATE TABLE blockchain_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action VARCHAR(100),
    tx_hash VARCHAR(128),
    payload TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance and uniqueness
CREATE INDEX idx_voter_id ON vote(voter_id);
CREATE INDEX idx_candidate_id ON vote(candidate_id);
CREATE UNIQUE INDEX idx_public_key ON voter(public_key);

-- Triggers and constraints (adapted to new schema)
-- ensuring that a voter can only vote once per election
DELIMITER //
CREATE TRIGGER prevent_duplicate_vote
BEFORE INSERT ON vote
FOR EACH ROW
BEGIN
    DECLARE vote_count INT;
    SELECT COUNT(*) INTO vote_count
    FROM vote
    WHERE voter_id = NEW.voter_id
    AND election_id = NEW.election_id;
    IF vote_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This voter has already voted in this election!';
    END IF;
END;
//

-- ensuring that a candidate can only be added to an election once
CREATE TRIGGER prevent_duplicate_candidate
BEFORE INSERT ON candidate
FOR EACH ROW
BEGIN
    DECLARE candidate_count INT;
    SELECT COUNT(*) INTO candidate_count
    FROM candidate
    WHERE name = NEW.name
    AND election_id = NEW.election_id;
    IF candidate_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This candidate already exists for this election';
    END IF;
END;
//

-- ensuring that an organization name is unique (already enforced by UNIQUE constraint)

-- ensuring that a voter can only be registered once with the same public key (already enforced by UNIQUE index)

-- ensuring that the election dates are valid
CREATE TRIGGER validate_election_dates
BEFORE INSERT ON election
FOR EACH ROW
BEGIN
    IF NEW.start_time >= NEW.end_time THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Start time must be before end time';
    END IF;
END;
//

-- ensuring that the election is associated with an organization
CREATE TRIGGER validate_election_org
BEFORE INSERT ON election
FOR EACH ROW
BEGIN
    IF NEW.org_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Election must be linked with an organization';
    END IF;
END;
//

-- ensuring that the candidate is linked with an election
CREATE TRIGGER validate_candidate_election
BEFORE INSERT ON candidate
FOR EACH ROW
BEGIN
    IF NEW.election_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Candidate must be involved in an election';
    END IF;
END;
//

-- ensuring that the voter's name is not empty
CREATE TRIGGER validate_voter_name
BEFORE INSERT ON voter
FOR EACH ROW
BEGIN
    IF NEW.first_name IS NULL OR NEW.first_name = '' OR NEW.last_name IS NULL OR NEW.last_name = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voter name cannot be empty!';
    END IF;
END;
//

-- ensuring that the voter's public key is not empty
CREATE TRIGGER validate_voter_public_key
BEFORE INSERT ON voter
FOR EACH ROW
BEGIN
    IF NEW.public_key IS NULL OR NEW.public_key = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voter public key cannot be empty!';
    END IF;
END;
//

-- ensuring that the organization name is not empty
CREATE TRIGGER validate_organization_name
BEFORE INSERT ON organization
FOR EACH ROW
BEGIN
    IF NEW.name IS NULL OR NEW.name = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Organization must have a name!';
    END IF;
END;
//

-- ensuring that the election name is not empty
CREATE TRIGGER validate_election_name
BEFORE INSERT ON election
FOR EACH ROW
BEGIN
    IF NEW.name IS NULL OR NEW.name = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Election name cannot be empty';
    END IF;
END;
//

-- ensuring that the candidate's name is not empty
CREATE TRIGGER validate_candidate_name
BEFORE INSERT ON candidate
FOR EACH ROW
BEGIN
    IF NEW.name IS NULL OR NEW.name = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Candidate name cannot be empty!';
    END IF;
END;
//

DELIMITER ;