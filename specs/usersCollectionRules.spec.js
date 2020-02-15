const { setup, teardown } = require('./helpers');
const { assertFails, assertSucceeds } = require('@firebase/testing');

const mockData = {
    '/Notification/someUserId': {},
    '/groups/someGroupId': {},
    '/reports/someUserId': {},
    '/topics/someTopic': {},
    'users/someUserId': {}
};  

describe('users collection rules', () => {
    var database;
    var collection;

    afterAll(async () => {
        await teardown();
    });
    test('allow reading to unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('users');

        await expect(collection.get()).toAllow();
    });

    test('allow reading to authenticated users', async () => {
        database = await setup({ uid: 'userAuthToken' }, mockData);
        collection = database.collection('users');

        await expect(collection.get()).toAllow();
    });

    test('deny writing to unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('users');

        await expect(collection.add({})).toDeny();
    })

    test('allow writing to authenticated users ', async () => {     
        database = await setup({ uid: 'userAuthToken' }, mockData);
        collection = database.collection('users');

        await expect(collection.add({})).toAllow();
    });
});