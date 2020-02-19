const { setup, teardown } = require('./helpers');

const mockData = {
    'users/userId1': {
        rank: 'Worker Bee',
        myTopics: ['General']
    },
    'users/userId2': {
        rank: 'Admin',
        myTopics: ['Art']
    },
    'users/userId3': {
        rank: 'Worker Bee',
        myTopics: ['General']
    },
    'topics/General/topicQuestions/questionId1': {
        createdBy: 'userId1',
        numOfResponses: 0
    },
    'topics/General/topicQuestions/questionId2': {
        createdBy: 'userId1',
        numOfResponses: 1
    }
};  

describe('topics collection rules', () => {
    var database;
    var collection;

    afterAll(async () => {
        await teardown();
    });

    // MARK: - Read

    test('allow reading to unauthenticated users', async () => {
        database = await setup();
        collection = database.collection('topics');

        await expect(collection.get()).toAllow();
        await expect(collection.doc('General').get()).toAllow();
        await expect(collection.doc('General').collection('topicQuestions').get()).toAllow();
        await expect(collection.doc('General').collection('topicQuestions').doc('questionId1').get()).toAllow();
    });

    test('allow reading to authenticated users', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('topics');

        await expect(collection.get()).toAllow();
        await expect(collection.doc('General').get()).toAllow();
        await expect(collection.doc('General').collection('topicQuestions').get()).toAllow();
        await expect(collection.doc('General').collection('topicQuestions').doc('questionId1').get()).toAllow();
    });

    // MARK: - Create

    test('allow creating a new topic to admins', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('topics');

        await expect(collection.add({ 'Martial Arts': {} })).toAllow();
    });

    test('deny creating a new topics to non-admins', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('topics');

        await expect(collection.add({ 'Martial Arts': {} })).toDeny();
    });

    test('allow creating a new topic quest to members', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('General').collection('topicQuestions').add({})).toAllow();
    });

    test('allow creating a new topic quest to members if user is admin', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('General').collection('topicQuestions').add({})).toAllow();
    });

    test('deny creating a new topic quest to non-members', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('Art').collection('topicQuestions').add({})).toDeny();
    });

    // MARK: - Update

    test('allow updating a question if user is the creator', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('General').collection('topicQuestions').doc('questionId1').set({ 'question': 'A different title'})).toAllow();
    });

    test('allow updating a question if user an admin', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('General').collection('topicQuestions').doc('questionId1').set({ 'question': 'A different title'})).toAllow();
    });

    test('deny updating a question if user is not the creator', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('General').collection('topicQuestions').doc('questionId1').set({ 'question': 'A different title'})).toDeny();
    });

    test('deny updating a question if user is the creator but question has responses', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('General').collection('topicQuestions').doc('questionId2').set({ 'question': 'A different title'})).toDeny();
    });

    test('deny updating a question if user is not the creator and question has responses', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('General').collection('topicQuestions').doc('questionId2').set({ 'question': 'A different title'})).toDeny();
    });

    // MARK: - Delete

    test('allow deleting a topic if user an admin', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('topics');
        
        await expect(collection.doc('General').delete()).toAllow();
    });

    test('deny deleting a topic if user not an admin', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('topics');
        
        await expect(collection.doc('General').delete()).toDeny();
    });

    test('allow deleting a question if user is the creator', async () => {
        database = await setup({ uid: 'userId1' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('General').collection('topicQuestions').doc('questionId1').delete()).toAllow();
    });

    test('allow deleting a question if user an admin', async () => {
        database = await setup({ uid: 'userId2' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('General').collection('topicQuestions').doc('questionId1').delete()).toAllow();
    });

    test('deny deleting a question if user is not the creator', async () => {
        database = await setup({ uid: 'userId3' }, mockData);
        collection = database.collection('topics');

        await expect(collection.doc('General').collection('topicQuestions').doc('questionId1').delete()).toDeny();
    });

});