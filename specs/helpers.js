const firestoreRulesPath = 'firestore.rules';

const firebase = require("@firebase/testing");
const fs = require("fs");

module.exports.setup = async (auth, data) => {
    // Everytime a test database is initialized
    // we need to give it a unique project id.
    const projectId = `rules-spec-${Date.now()}`;

    const app = await firebase.initializeTestApp({
        projectId,
        auth
    });

    const database = app.firestore();

    if (data) {
        for (const key in data) {
            const reference = database.doc(key);
            await reference.set(data[key]);
        }
    }

    await firebase.loadFirestoreRules({
        projectId,
        rules: fs.readFileSync(firestoreRulesPath)
    });

    return database;
};

module.exports.teardown = async () => {
    // Delete all the firebase apps that were created
    // in the test run once the tests are finished.
    Promise.all(firebase.app().map(app => app.delete()));
};
