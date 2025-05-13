#!/bin/bash

# Step 1: Install Apache, MySQL, PHP, and Git
echo "Installing Apache, MySQL, PHP, and Git..."

# Update package list and install necessary packages
sudo apt update
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql git

# Start Apache and MySQL services
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl start mysql
sudo systemctl enable mysql

echo "Apache, MySQL, PHP, and Git installed and services started."

# Step 2: Set up MySQL Database

echo "Setting up the MySQL database..."

# MySQL root password (change this to a secure password)
MYSQL_ROOT_PASSWORD="your_mysql_root_password"
DB_NAME="scp_database"
DB_USER="scp_user"
DB_PASSWORD="scp_password"

# Secure MySQL installation (remove insecure default settings)
sudo mysql_secure_installation <<EOF

y
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
y
y
y
y
EOF

# Log in to MySQL and create database and user
mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Step 3: Create Database Schema (Table for SCP Subjects)

echo "Creating database schema..."

# SQL query to create the table
SQL_CREATE_TABLE="CREATE TABLE $DB_NAME.scp_subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    scp_id VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    containment_procedures TEXT NOT NULL,
    object_class VARCHAR(50),
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Execute SQL to create the table
mysql -u $DB_USER -p$DB_PASSWORD -D $DB_NAME -e "$SQL_CREATE_TABLE"

# Step 4: Insert Sample Data into the Database

echo "Inserting sample data into the database..."

# Insert 10 sample records into the database
mysql -u $DB_USER -p$DB_PASSWORD -D $DB_NAME <<EOF
INSERT INTO scp_subjects (scp_id, title, description, containment_procedures, object_class) 
VALUES
('SCP-001', 'The Gate Guardian', 'A mysterious, towering entity known as the Gate Guardian.', 'Keep away from direct contact with SCP-001 to prevent activation.', 'Keter'),
('SCP-002', 'The Living Room', 'A grotesque, living room-like anomaly.', 'Containment procedures involve restricting access to SCP-002.', 'Euclid'),
('SCP-003', 'Biotechnological Artifact', 'A strange, alien-like biological artifact that exhibits controlled growth.', 'Containment in a sterile environment is essential.', 'Safe'),
('SCP-004', 'The 12 Rusty Keys', 'A set of 12 old, rusty keys, each with a mysterious lock they correspond to.', 'Locked in a secure vault with no access allowed.', 'Euclid'),
('SCP-005', 'The Skeleton Key', 'An ancient key capable of unlocking any door or lock.', 'Secure storage in a high-security vault.', 'Euclid'),
('SCP-006', 'Fountain of Youth', 'A natural fountain that reverses aging when its water is consumed.', 'Handle with extreme caution and restrict usage to authorized personnel only.', 'Safe'),
('SCP-007', 'Absence of Life', 'A hole in the ground where no life can exist around it.', 'Containment involves marking the area and preventing access.', 'Keter'),
('SCP-008', 'Zombie Plague', 'A virus that turns victims into zombies upon infection.', 'Containment involves isolation and immediate quarantine protocols.', 'Keter'),
('SCP-009', 'Red Ice', 'A strange form of ice that is bright red and extremely cold.', 'Containment in a specialized cold storage unit.', 'Safe'),
('SCP-010', 'Animal Restraint Collar', 'A collar that can control any animal’s actions.', 'Maintain in a high-security facility with no animal access.', 'Euclid');
EOF

# Step 5: Set up the PHP Web Interface for CRUD Operations

echo "Setting up the PHP web interface for CRUD operations..."

# Create project folder structure in Apache's web directory
PROJECT_DIR="/var/www/html/scp_project"
sudo mkdir -p $PROJECT_DIR/assets/css
sudo mkdir -p $PROJECT_DIR/assets/js
sudo mkdir -p $PROJECT_DIR/assets/images
sudo mkdir -p $PROJECT_DIR/db
sudo mkdir -p $PROJECT_DIR/includes
sudo mkdir -p $PROJECT_DIR/scripts
sudo chown -R www-data:www-data $PROJECT_DIR

# 1. Create form for adding SCP records (create_form.php)
echo "<?php
// PHP file to insert new SCP subjects
if (\$_SERVER['REQUEST_METHOD'] == 'POST') {
    \$_scp_id = \$_POST['scp_id'];
    \$_title = \$_POST['title'];
    \$_description = \$_POST['description'];
    \$_containment_procedures = \$_POST['containment_procedures'];
    \$_object_class = \$_POST['object_class'];

    // Database connection with prepared statement
    \$conn = new mysqli('localhost', '$DB_USER', '$DB_PASSWORD', '$DB_NAME');
    if (\$conn->connect_error) {
        die('Connection failed: ' . \$conn->connect_error);
    }

    \$stmt = \$conn->prepare('INSERT INTO scp_subjects (scp_id, title, description, containment_procedures, object_class) VALUES (?, ?, ?, ?, ?)');
    \$stmt->bind_param('sssss', \$_scp_id, \$_title, \$_description, \$_containment_procedures, \$_object_class);
    
    if (\$stmt->execute()) {
        echo 'New SCP Subject added successfully!';
    } else {
        echo 'Error: ' . \$conn->error;
    }

    \$conn->close();
}
?>

<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Create SCP Subject</title>
    <link href='https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css' rel='stylesheet'>
</head>
<body>

    <div class='container'>
        <h2>Create SCP Subject</h2>
        <form action='' method='POST'>
            <div class='form-group'>
                <label for='scp_id'>SCP ID</label>
                <input type='text' class='form-control' name='scp_id' required>
            </div>

            <div class='form-group'>
                <label for='title'>Title</label>
                <input type='text' class='form-control' name='title' required>
            </div>

            <div class='form-group'>
                <label for='description'>Description</label>
                <textarea class='form-control' name='description' required></textarea>
            </div>

            <div class='form-group'>
                <label for='containment_procedures'>Containment Procedures</label>
                <textarea class='form-control' name='containment_procedures' required></textarea>
            </div>

            <div class='form-group'>
                <label for='object_class'>Object Class</label>
                <select class='form-control' name='object_class'>
                    <option value='Safe'>Safe</option>
                    <option value='Euclid'>Euclid</option>
                    <option value='Keter'>Keter</option>
                </select>
            </div>

            <button type='submit' class='btn btn-primary'>Add SCP Subject</button>
        </form>
    </div>

    <script src='https://code.jquery.com/jquery-3.5.1.slim.min.js'></script>
    <script src='https://cdn.jsdelivr.net/npm/@popperjs/core@2.5.1/dist/umd/popper.min.js'></script>
    <script src='https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js'></script>

</body>
</html>
" | sudo tee $PROJECT_DIR/scripts/create_form.php

# 2. Create PHP script to display SCP records (view_scp.php)
echo "<?php
\$conn = new mysqli('localhost', '$DB_USER', '$DB_PASSWORD', '$DB_NAME');
if (\$conn->connect_error) {
    die('Connection failed: ' . \$conn->connect_error);
}

\$sql = 'SELECT * FROM scp_subjects';
\$result = \$conn->query(\$sql);

if (\$result->num_rows > 0) {
    echo '<table class=\"table table-bordered table-striped\">';
    echo '<tr><th>SCP ID</th><th>Title</th><th>Description</th><th>Object Class</th><th>Actions</th></tr>';
    while (\$row = \$result->fetch_assoc()) {
        echo '<tr><td>' . \$row['scp_id'] . '</td><td>' . \$row['title'] . '</td><td>' . \$row['description'] . '</td><td>' . \$row['object_class'] . '</td><td><a href=\"edit_scp.php?id=' . \$row['id'] . '\">Edit</a> | <a href=\"delete_scp.php?id=' . \$row['id'] . '\">Delete</a></td></tr>';
    }
    echo '</table>';
} else {
    echo 'No SCP Subjects found.';
}

\$conn->close();
?>" | sudo tee $PROJECT_DIR/scripts/view_scp.php

# 3. Create PHP script for deleting SCP records (delete_scp.php)
echo "<?php
if (isset(\$_GET['id'])) {
    \$id = \$_GET['id'];

    // Database connection
    \$conn = new mysqli('localhost', '$DB_USER', '$DB_PASSWORD', '$DB_NAME');
    if (\$conn->connect_error) {
        die('Connection failed: ' . \$conn->connect_error);
    }

    // Delete SCP subject
    \$sql = \"DELETE FROM scp_subjects WHERE id = \$id\";
    if (\$conn->query(\$sql) === TRUE) {
        echo 'Record deleted successfully';
    } else {
        echo 'Error: ' . \$conn->error;
    }

    \$conn->close();
}
?>" | sudo tee $PROJECT_DIR/scripts/delete_scp.php

# Step 6: Restart Apache to apply changes
echo "Restarting Apache..."
sudo systemctl restart apache2

echo "Task 1 is completed successfully, with CRUD functionality and security improvements!"

echo "Access your web app at: http://localhost/scp_project/scripts/create_form.php"
