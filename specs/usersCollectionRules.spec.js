const { setup, teardown } = require('./helpers');
const { assertFails, assertSucceeds } = require('@firebase/testing');

const mockData = {
    'users/userId1': {
        rank: 'Worker Bee'
    },
    'users/userId2': {
        rank: 'Queen Bee'
    },
    'users/userId3': {
        rank: 'Admin'
    }
};  

describe('users collection rules', () => {
    var database;
    var collection;

    afterAll(async () => {
        await teardown();
    });

    // MARK: - Read

    test('allow reading to unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('users');

        await expect(collection.doc('userId1').get()).toAllow();
    });

    test('allow reading to authenticated users', async () => {
        database = await setup({ uid: 'userAuthToken' }, mockData);
        collection = database.collection('users');

        await expect(collection.doc('userId1').get()).toAllow();
    });

    // MARK: - Create

    test('deny creating to unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('users');

        await expect(collection.add({ 'userId4': {} })).toDeny();
    })

    test('allow creating to authenticated users ', async () => {     
        database = await setup({ uid: 'userAuthToken' }, mockData);
        collection = database.collection('users');

        await expect(collection.add({ 'userId4': {} })).toAllow();
    });

    // MARK: - Update

    test('deny updating to unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('users');

        await expect(collection.doc('userId1').set({role: "Queen Bee"})).toDeny();
    });

    test('deny updating to a user that is not the document owner', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('users');
        await expect(collection.doc('userId1').set({rank: "Queen Bee"})).toDeny();
    });

    test('deny updating to a user that is the document owner but tries to change the rank', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('users');
        await expect(collection.doc('userId1').set({ rank: 'Queen Bee' })).toDeny();
    });

    test('allow updating to a user that is the document owner', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('users');
        await expect(collection.doc('userId1').set({ name: 'Billy', rank: 'Worker Bee' })).toAllow();
    });

    test('allow admin to update a different users data', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('users');
        await expect(collection.doc('userId1').set({ name: 'Billy', rank: 'Worker Bee' })).toAllow();
    });

    // MARK: - Delete

    test('deny deleting to unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('users');
        await expect(collection.doc('userId1').delete()).toDeny();
    });

    test('deny deleting to a user that is not the document owner', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('users');
        await expect(collection.doc('userId1').delete()).toDeny();
    });

    test('allow deleting to a user that is the document owner', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('users');
        await expect(collection.doc('userId1').delete()).toAllow();
    });

    test('allow admin to delete any user', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('users');
        await expect(collection.doc('userId1').delete()).toAllow();
    });
});