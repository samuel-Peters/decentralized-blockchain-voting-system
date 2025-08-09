CREATE DATABASE voting_system;
USE voting_system;

CREATE TABLE Organization 
(
    org_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE Voter
(
    voter_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    public_key VARCHAR(255) NOT NULL,
    org_id INT,
    FOREIGN KEY (org_id) REFERENCES Organization(org_id)
);

CREATE TABLE Election
(
    election_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    org_id INT,
    FOREIGN KEY (org_id) REFERENCES Organization(org_id)
);

CREATE TABLE Candidate
(
    candidate_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    election_id INT,
    FOREIGN KEY (election_id) REFERENCES Election(election_id)
);

CREATE TABLE Vote
(
    vote_id INT AUTO_INCREMENT PRIMARY KEY,
    voter_id INT,
    candidate_id INT,
    hash VARCHAR(64) NOT NULL,
    timestamp DATETIME NOT NULL,
    FOREIGN KEY (voter_id) REFERENCES Voter(voter_id),
    FOREIGN KEY (candidate_id) REFERENCES Candidate(candidate_id)
);

-- Performance indexes for faster queries
CREATE INDEX idx_voter_id ON Vote(voter_id);
CREATE INDEX idx_candidate_id ON Vote(candidate_id);

-- Security index to prevent duplicate public keys
CREATE UNIQUE INDEX idx_public_key ON Voter(public_key);

//

-- ensuring that a voter can only vote once per election
CREATE TRIGGER prevent_duplicate_vote
BEFORE INSERT ON Vote
FOR EACH ROW
BEGIN
    DECLARE vote_count INT;
    SELECT COUNT(*) INTO vote_count
    FROM Vote
    WHERE voter_id = NEW.voter_id
    AND candidate_id IN
    (
        SELECT candidate_id FROM Candidate
        WHERE election_id =
        (
        SELECT election_id FROM Candidate WHERE candidate_id = NEW.candidate_id
        )
    );
    IF vote_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This voter has already voted in this election!!';
    END IF;
END;
//

-- ensuring that a candidate can only be added to an election once
CREATE TRIGGER prevent_duplicate_candidate
BEFORE INSERT ON Candidate
FOR EACH ROW
BEGIN
    DECLARE candidate_count INT;
    SELECT COUNT(*) INTO candidate_count
    FROM Candidate
    WHERE first_name = NEW.first_name
    AND last_name = NEW.last_name
    AND position = NEW.position
    AND election_id = NEW.election_id;
    IF candidate_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This candidate already exists for this election';
    END IF;
END;
//

-- ensuring that an organization name is unique
CREATE TRIGGER prevent_duplicate_organization
BEFORE INSERT ON Organization
FOR EACH ROW
BEGIN
    DECLARE org_count INT;
    SELECT COUNT(*) INTO org_count
    FROM Organization
    WHERE name = NEW.name;
    IF org_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This organization name already exists';
    END IF;
END;
//

-- ensuring that a voter can only be registered once with the same public key
CREATE TRIGGER prevent_duplicate_voter
BEFORE INSERT ON Voter
FOR EACH ROW
BEGIN
    DECLARE voter_count INT;
    SELECT COUNT(*) INTO voter_count
    FROM Voter
    WHERE public_key = NEW.public_key;
    IF voter_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A voter with this public key already exists';
    END IF;
END;
//

-- ensuring that the election dates are valid
CREATE TRIGGER validate_election_dates
BEFORE INSERT ON Election
FOR EACH ROW
BEGIN
    IF NEW.start_date >= NEW.end_date THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Start date must be before end date';
    END IF;
END;
//

-- ensuring that the election is associated with an organization
CREATE TRIGGER validate_election_org
BEFORE INSERT ON Election
FOR EACH ROW
BEGIN
    IF NEW.org_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Election must be linked with their respective organization';
    END IF;
END;
//

-- ensuring that the candidate is linked with an election
CREATE TRIGGER validate_candidate_election
BEFORE INSERT ON Candidate
FOR EACH ROW
BEGIN
    IF NEW.election_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The candidate must be involved in an election';
    END IF;
END;
//

-- ensuring that the voter is linked with their respective organization
CREATE TRIGGER validate_voter_org
BEFORE INSERT ON Voter
FOR EACH ROW
BEGIN
    IF NEW.org_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You cant vote out of your organization';
    END IF;
END;
//

-- ensuring that the candidate's position is not empty
CREATE TRIGGER validate_candidate_position
BEFORE INSERT ON Candidate
FOR EACH ROW
BEGIN
    IF NEW.position IS NULL OR NEW.position = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR: !!Candidate position cannot be empty!!';
    END IF;
END;
//

-- ensuring that the candidate's name is not empty
CREATE TRIGGER validate_candidate_name
BEFORE INSERT ON Candidate
FOR EACH ROW
BEGIN
    IF NEW.first_name IS NULL OR NEW.first_name = '' OR NEW.last_name IS NULL OR NEW.last_name = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Candidate name cannot be empty!!';
    END IF;
END;
//

-- ensuring that the voter's name is not empty
CREATE TRIGGER validate_voter_name
BEFORE INSERT ON Voter
FOR EACH ROW
BEGIN
    IF NEW.first_name IS NULL OR NEW.first_name = '' OR NEW.last_name IS NULL OR NEW.last_name = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voter name cannot be empty!!';
    END IF;
END;
//

-- ensuring that the voter's public key is not empty
CREATE TRIGGER validate_voter_public_key
BEFORE INSERT ON Voter
FOR EACH ROW
BEGIN
    IF NEW.public_key IS NULL OR NEW.public_key = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voter public key cannot be empty!!';
    END IF;
END;
//

-- ensuring that the organization name is not empty
CREATE TRIGGER validate_organization_name
BEFORE INSERT ON Organization
FOR EACH ROW
BEGIN
    IF NEW.name IS NULL OR NEW.name = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Organization must have a name!!';
    END IF;
END;
//

-- ensuring that the election name is not empty
CREATE TRIGGER validate_election_name
BEFORE INSERT ON Election
FOR EACH ROW
BEGIN
    IF NEW.name IS NULL OR NEW.name = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Election name cannot be empty';
    END IF;
END;
//

-- ensuring that the election's organization exists
CREATE TRIGGER validate_election_org_exists
BEFORE INSERT ON Election
FOR EACH ROW
BEGIN
    DECLARE org_exists INT;
    SELECT COUNT(*) INTO org_exists
    FROM Organization
    WHERE org_id = NEW.org_id;
    IF org_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Organization does not exist for this election';
    END IF;
END;
//

-- ensuring that the candidate's election exists
CREATE TRIGGER validate_candidate_election_exists
BEFORE INSERT ON Candidate
FOR EACH ROW
BEGIN
    DECLARE election_exists INT;
    SELECT COUNT(*) INTO election_exists
    FROM Election
    WHERE election_id = NEW.election_id;
    IF election_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Election does not exist for this candidate';
    END IF;
END;
//

-- ensuring that the voter's organization exists
CREATE TRIGGER validate_voter_org_exists
BEFORE INSERT ON Voter
FOR EACH ROW
BEGIN
    DECLARE org_exists INT;
    SELECT COUNT(*) INTO org_exists
    FROM Organization
    WHERE org_id = NEW.org_id;
    IF org_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Organization does not exist for this voter';
    END IF;
END;
//

-- ensuring that the vote's voter exists
CREATE TRIGGER validate_vote_voter_exists
BEFORE INSERT ON Vote
FOR EACH ROW
BEGIN
    DECLARE voter_exists INT;
    SELECT COUNT(*) INTO voter_exists
    FROM Voter
    WHERE voter_id = NEW.voter_id;
    IF voter_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voter does not exist for this vote!!';
    END IF;
END;
//

-- ensuring that the vote's candidate exists
CREATE TRIGGER validate_vote_candidate_exists
BEFORE INSERT ON Vote
FOR EACH ROW
BEGIN
    DECLARE candidate_exists INT;
    SELECT COUNT(*) INTO candidate_exists
    FROM Candidate
    WHERE candidate_id = NEW.candidate_id;
    IF candidate_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Candidate does not exist for this vote';
    END IF;
END;
//

-- ensuring that the vote's hash is not empty
CREATE TRIGGER validate_vote_hash
BEFORE INSERT ON Vote
FOR EACH ROW
BEGIN
    IF NEW.hash IS NULL OR NEW.hash = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vote hash cannot be empty';
    END IF;
END;
//

-- ensuring that the vote's timestamp is not in the future
CREATE TRIGGER validate_vote_timestamp
BEFORE INSERT ON Vote
FOR EACH ROW
BEGIN
    IF NEW.timestamp > NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vote timestamp cannot be in the future';
    END IF;
END;
//

-- ensuring that the vote's timestamp is not in the past
CREATE TRIGGER validate_vote_timestamp_not_past
BEFORE INSERT ON Vote
FOR EACH ROW
BEGIN
    IF NEW.timestamp < '2025-06-07 00:00:00' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vote timestamp cannot be in the past';
    END IF;
END;
//

-- ensuring that the vote's timestamp is within the election period
CREATE TRIGGER validate_vote_timestamp_within_election
BEFORE INSERT ON Vote
FOR EACH ROW
BEGIN
    DECLARE election_start DATE;
    DECLARE election_end DATE;
    SELECT start_date, end_date INTO election_start, election_end
    FROM Election
    WHERE election_id =
    (
        SELECT election_id FROM Candidate WHERE candidate_id = NEW.candidate_id
    );
    IF NEW.timestamp < election_start OR NEW.timestamp > election_end THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vote timestamp must be within the election period';
    END IF;
END;
//

-- ensuring that the vote's candidate is valid for the election
CREATE TRIGGER validate_vote_candidate_valid
BEFORE INSERT ON Vote
FOR EACH ROW
BEGIN
    DECLARE candidate_election_id INT;
    SELECT election_id INTO candidate_election_id
    FROM Candidate
    WHERE candidate_id = NEW.candidate_id;
    IF candidate_election_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Candidate is not valid for this election';
    END IF;
END;
//

-- ensuring that the vote's voter is valid for the election
CREATE TRIGGER validate_vote_voter_valid
BEFORE INSERT ON Vote
FOR EACH ROW
BEGIN
    DECLARE voter_org_id INT;
    SELECT org_id INTO voter_org_id
    FROM Voter
    WHERE voter_id = NEW.voter_id;
    IF voter_org_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voter is not valid for this election';
    END IF;
END;
//

-- ensuring that the vote's candidate is not already voted for by the voter in the same election
CREATE TRIGGER validate_vote_candidate_not_already_voted
BEFORE INSERT ON Vote
FOR EACH ROW
BEGIN
    DECLARE already_voted INT;
    SELECT COUNT(*) INTO already_voted
    FROM Vote
    WHERE voter_id = NEW.voter_id
    AND candidate_id = NEW.candidate_id
    AND timestamp >=
    (
        SELECT start_date FROM Election WHERE election_id = (
        SELECT election_id FROM Candidate WHERE candidate_id = NEW.candidate_id
        )
    )
    AND timestamp <=
    (
        SELECT end_date FROM Election WHERE election_id =
        (
        SELECT election_id FROM Candidate WHERE candidate_id = NEW.candidate_id
        )
    );
    IF already_voted > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voter has already voted for this candidate in the current election';
    END IF;
END;
//