const { setup, teardown } = require('./helpers');

const mockData = {
    'users/userId1': {
        rank: 'Queen Bee',
        joinedGroups: []
    },
    'users/userId2': {
        rank: 'Queen Bee',
        joinedGroups: ['groupId1', 'groupId2']
    },
    'users/userId3': {
        rank: 'Admin',
        joinedGroups: []
    },
    'groups/groupId1': {
        createdBy: 'userId2',
        privateGroup: false,
        userRequestToJoin: []
    },
    'groups/groupId2': {
        createdBy: 'userId2',
        privateGroup: true,
        userRequestToJoin: []
    }
};  

describe('groups collection rules', () => {
    var database;
    var collection;

    afterAll(async () => {
        await teardown();
    });

    // MARK: - Read

    // MARK: - /groups/{groupId}

    test('allow reading to unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('groups');

        await expect(collection.get()).toAllow();
        await expect(collection.doc('groupId1').get()).toAllow();
    });

    test('allow reading to authenticated users not apart of group', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').get()).toAllow();
    });

    test('allow reading to authenticated users apart of group', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').get()).toAllow();
    });

    test('allow reading to admin users', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').get()).toAllow();
    });

    // MARK: - /groups/{groupId}/groupQuestions/{question}

    test('allow reading to public groups', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').collection('groupQuestions').doc('questionId1').get()).toAllow();
    });

    test('allow reading to private groups if user is apart of the group', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId2').collection('groupQuestions').doc('questionId1').get()).toAllow();
    });

    test('deny reading to private groups if user is not apart of the group', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId2').collection('groupQuestions').doc('questionId1').get()).toDeny();
    });

    // MARK: - Create

    // MARK: - /groups/{groupId}

    test('deny creating to unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('groups');

        await expect(collection.add({})).toDeny();
    });

    test('allow creating to Queen Bee users', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('groups');

        await expect(collection.add({})).toAllow();
    });

    test('allow creating to Admins', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('groups');

        await expect(collection.add({})).toAllow();
    });

    // MARK: - /groups/{groupId}/groupQuestions/{question}

    test('deny creating to non group members', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').collection('groupQuestions').add({})).toDeny();
    });

    test('allow creating to group members', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').collection('groupQuestions').add({})).toAllow();
    });

    test('allow creating to admins', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').collection('groupQuestions').add({})).toAllow();
    });

    // MARK: - Update

    // MARK: - /groups/{groupId}

    test('deny updating to unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').set({ 'userRequestToJoin': ['userId5'] })).toDeny()
    });

    test('allow updating to authenticated users not apart of group', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').set({ 'userRequestToJoin': ['userId5'] })).toAllow()
    });

    test('allow updating to authenticated users apart of group', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').set({ 'userRequestToJoin': ['userId5'] })).toAllow()
    });

    test('allow updating to Queen Bee users', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').set({ 'userRequestToJoin': ['userId5'] })).toAllow()
    });

    test('allow creating to Admins', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').set({ 'userRequestToJoin': ['userId5'] })).toAllow()
    });

    // MARK: - /groups/{groupId}/groupQuestions/{question}

    test('deny updating to non post owner', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').collection('groupQuestions').doc('questionId1').set({ title: 'changed' })).toDeny();
    });

    test('allow updating to post owner', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').collection('groupQuestions').doc('questionId1').set({ title: 'changed' })).toAllow();
    });

    test('allow updating to admins', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').collection('groupQuestions').doc('questionId1').set({ title: 'changed' })).toAllow();
    });

    // MARK: - Delete

    // MARK: - /groups/{groupId}

    test('deny deleting for unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').delete()).toDeny();
    });

    test('deny deleting for non group owner', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').delete()).toDeny();
    });

    test('allow deleting for group owner', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').delete()).toAllow();
    });

    test('allow deleting for Admins', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').delete()).toAllow();
    });

    // MARK: - /groups/{groupId}/groupQuestions/{question}

    test('deny deleting to non post owner', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').collection('groupQuestions').doc('questionId1').delete()).toDeny();
    });

    test('allow deleting to post owner', async () => {
        const mockData2 = {
            'users/userId2': {
                rank: 'Queen Bee',
                joinedGroups: ['groupId1']
            },
            'groups/groupId1': {
                createdBy: 'userId2',
                privateGroup: false,
                userRequestToJoin: []
            },
            'groups/groupId1/groupQuestions/questionId1': {
                createdBy: 'userId2',
            }
        };  
        
        database = await setup({ uid: 'userId2' }, mockData2);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').collection('groupQuestions').doc('questionId1').delete()).toAllow();
    });

    test('allow deleting to admins', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('groups');

        await expect(collection.doc('groupId1').collection('groupQuestions').doc('questionId1').delete()).toAllow();
    });
});