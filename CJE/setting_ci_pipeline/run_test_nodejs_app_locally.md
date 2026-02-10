Here's a comprehensive `README.md` file based on your content:

```markdown
# Solar System Node.js Application - Manual Execution Demo

This document provides a step-by-step guide for manually setting up and running the Solar System Node.js application, including troubleshooting steps for MongoDB connectivity.

## Prerequisites
- Ubuntu/Linux environment
- Basic knowledge of terminal commands
- Docker installed (for MongoDB container)

## Application Reference
- **GitHub Repository**: [sidd-harth/solar-system-gitea](https://github.com/sidd-harth/solar-system-gitea)
- **Application**: Solar System information portal with MongoDB backend

## Step 1: Installation

### 1.1 Install Node.js and npm
```bash
sudo apt update
sudo apt install nodejs
sudo apt install npm
```

### 1.2 Clone and Setup Application
```bash
git clone https://github.com/sidd-harth/solar-system-gitea.git
cd solar-system-gitea
```

### 1.3 Install Dependencies
```bash
npm install
```
This creates a `node_modules` folder with all required dependencies.

## Step 2: MongoDB Setup

### 2.1 The MongoDB Connection Issue
When running `npm test`, you may encounter this error:
```
MongooseServerSelectionError: connect ECONNREFUSED 127.0.0.1:27017
```
This indicates MongoDB is not running locally.

### 2.2 Run MongoDB via Docker
```bash
docker run -d \
  --name mongodb \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=testUser \
  -e MONGO_INITDB_ROOT_PASSWORD=testPass \
  mongo:latest
```

### 2.3 Verify Container Status
```bash
docker ps
```

### 2.4 Access MongoDB Shell
```bash
docker exec -it mongodb /bin/bash
mongosh -u testUser -p testPass --authenticationDatabase admin
```

## Step 3: Understanding the MongoDB Connection String

In `app.js`, the connection string is:
```javascript
const MONGO_URI = 'mongodb://testUser:testPass@127.0.0.1:27017/solarSystemDB?authSource=admin';
```

**Breakdown:**
- `mongodb://` - MongoDB protocol
- `testUser:testPass@` - Authentication credentials
- `127.0.0.1:27017` - Host and port
- `/solarSystemDB` - Database name (auto-created if doesn't exist)
- `?authSource=admin` - Specifies where credentials are stored

## Step 4: Running Tests

### 4.1 Unit Testing
```bash
npm test
```
**Expected Output:**
```
🚀 Server successfully running on port 3000
✅ Connected to MongoDB: mongodb://testUser:testPass@127.0.0.1:27017/solarSystemDB?authSource=admin
ℹ️ Planets already exist (8 entries).
```
This generates `test-results.xml` with test outcomes.

### 4.2 Code Coverage
```bash
npm run coverage
```
**Expected Output:**
```
🚀 Server successfully running on port 3000

  Planets API Suite
    Fetching Planet Details
✅ Connected to MongoDB: mongodb://testUser:testPass@127.0.0.1:27017/solarSystemDB?authSource=admin
ℹ️ Planets already exist (8 entries).
      ✔ it should fetch a planet named Mercury
      ... (all 8 planets)
  
  11 passing (77ms)

ERROR: Coverage for lines (74.5%) does not meet global threshold (90%)
```
This creates:
- `coverage/` folder with various reports (XML, JSON, HTML)
- `.nyc_output/` folder with raw coverage data

**Note:** The coverage threshold is set to 90% in `package.json`. Current coverage is ~74.5%.

## Step 5: Seed Planet Data

### 5.1 Access MongoDB and Insert Data
```bash
docker exec -it mongodb /bin/bash
mongosh -u testUser -p testPass --authenticationDatabase admin
```

### 5.2 Execute in MongoDB Shell
```javascript
use solarSystemDB
db.planets.deleteMany({})
db.planets.insertMany([
  {
    id: 1,
    name: "Mercury",
    description: "The smallest planet and closest to the Sun. Mercury has a rocky surface covered with craters.",
    image: "https://upload.wikimedia.org/wikipedia/commons/4/4a/Mercury_in_true_color.jpg"
  },
  {
    id: 2,
    name: "Venus",
    description: "Venus is the hottest planet with thick clouds of sulfuric acid and a surface hot enough to melt lead.",
    image: "https://upload.wikimedia.org/wikipedia/commons/e/e5/Venus-real_color.jpg"
  },
  {
    id: 3,
    name: "Earth",
    description: "Our home planet, the only known world to harbor life, with vast oceans and diverse ecosystems.",
    image: "https://upload.wikimedia.org/wikipedia/commons/9/97/The_Earth_seen_from_Apollo_17.jpg"
  },
  {
    id: 4,
    name: "Mars",
    description: "Known as the Red Planet, Mars has the tallest volcano and deepest canyon in the solar system.",
    image: "https://upload.wikimedia.org/wikipedia/commons/0/02/OSIRIS_Mars_true_color.jpg"
  },
  {
    id: 5,
    name: "Jupiter",
    description: "The largest planet, a gas giant known for its Great Red Spot and dozens of moons.",
    image: "https://upload.wikimedia.org/wikipedia/commons/e/e2/Jupiter.jpg"
  },
  {
    id: 6,
    name: "Saturn",
    description: "Famous for its stunning rings, Saturn is a gas giant composed mostly of hydrogen and helium.",
    image: "https://upload.wikimedia.org/wikipedia/commons/c/c7/Saturn_during_Equinox.jpg"
  },
  {
    id: 7,
    name: "Uranus",
    description: "An ice giant with a pale blue hue due to methane in its atmosphere, Uranus rotates on its side.",
    image: "https://upload.wikimedia.org/wikipedia/commons/3/3d/Uranus2.jpg"
  },
  {
    id: 8,
    name: "Neptune",
    description: "The farthest planet from the Sun, Neptune has supersonic winds and a deep blue color.",
    image: "https://upload.wikimedia.org/wikipedia/commons/5/56/Neptune_Full.jpg"
  }
])
```

### 5.3 Verify Data
```javascript
db.planets.find().pretty()
show collections
```

## Step 6: Run the Application

```bash
npm start
```

## Step 7: Access Application Endpoints

### 7.1 Main Application
- **Homepage**: `http://localhost:3000/index.html`
  - Displays solar system planets with images and descriptions

### 7.2 API Endpoints
- **OS Details**: `http://localhost:3000/os`
  ```json
  { "os": "LAPTOP-49SH4K4V" }
  ```

- **Liveness Probe**: `http://localhost:3000/live`
  ```json
  { "status": "live" }
  ```

- **Readiness Probe**: `http://localhost:3000/ready`
  ```json
  { "status": "ready" }
  ```

## MongoDB Quick Reference

### Common Commands
| Task | MongoDB Command |
|------|-----------------|
| Show databases | `show dbs` |
| Use database | `use solarSystemDB` |
| Show collections | `show collections` |
| Find all documents | `db.planets.find()` |
| Pretty print results | `db.planets.find().pretty()` |
| Filter documents | `db.planets.find({ id: 3 })` |
| Insert document | `db.planets.insertOne({...})` |
| Delete document | `db.planets.deleteOne({ id: 3 })` |
| Update document | `db.planets.updateOne({ id: 3 }, { $set: {...} })` |

### SQL to MongoDB Comparison
| Task | SQL | MongoDB |
|------|-----|---------|
| Select database | `USE solarSystemDB;` | `use solarSystemDB` |
| Show tables | `SHOW TABLES;` | `show collections` |
| Select all rows | `SELECT * FROM planets;` | `db.planets.find()` |
| Filter rows | `SELECT * FROM planets WHERE id = 3;` | `db.planets.find({ id: 3 })` |
| Insert row | `INSERT INTO planets VALUES (...);` | `db.planets.insertOne({...})` |
| Delete row | `DELETE FROM planets WHERE id = 3;` | `db.planets.deleteOne({ id: 3 })` |
| Update row | `UPDATE planets SET ... WHERE id=3;` | `db.planets.updateOne({ id: 3 }, { $set: {...} })` |

## Troubleshooting

### Issue 1: MongoDB Connection Failed
**Error**: `ECONNREFUSED 127.0.0.1:27017`
**Solution**:
1. Ensure MongoDB container is running: `docker ps`
2. If not running: `docker start mongodb`
3. Check port mapping: `docker port mongodb`

### Issue 2: Authentication Failed
**Error**: `Authentication failed`
**Solution**:
1. Verify credentials match those in Docker run command
2. Ensure `authSource=admin` is included in connection string
3. Check user exists: In MongoDB shell: `db.getUsers()`

### Issue 3: Tests Failing
**Solution**:
1. Ensure MongoDB is running before tests
2. Clear and reseed planet data
3. Check application logs for detailed errors

## Next Steps for Improvement
1. Increase code coverage from 74.5% to meet 90% threshold
2. Integrate with CI/CD pipeline (Jenkins)
3. Use coverage reports for quality gates
4. Containerize the Node.js application

## References
- [MongoDB Docker Documentation](https://www.mongodb.com/resources/products/compatibilities/docker)
- [Mongoose Documentation](https://mongoosejs.com/)
- [Mocha Testing Framework](https://mochajs.org/)
- [Istanbul Code Coverage](https://istanbul.js.org/)
```