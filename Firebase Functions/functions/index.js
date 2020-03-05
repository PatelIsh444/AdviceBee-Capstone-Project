/** 
*	Firebase Functions for AdviceBee
*/

const functions = require('firebase-functions')
const admin = require('firebase-admin')
admin.initializeApp()

/*
*	Notify user whenever another user response to a post
*	or likes a post
*/
exports.sendNotificationPost = functions.firestore
.document('topics/{topics}/topicQuestions/{post}')
.onUpdate((change, context) => {
	//get reference to new and old data
	const newData = change.after.data()
	const oldData = change.before.data()
	
	//get owner of the post name and id
	const posterId=newData.createdBy
	const posterName=newData.userDisplayName
	
	//numbers of responses for a post
	const responseNumBefore= oldData.numOfResponses
	const responseNumAfter= newData.numOfResponses

	//likes of a given post
	const newLikes = newData.likes
	const oldLikes = oldData.likes

	//check if there is a new response to a post
	if(responseNumAfter>responseNumBefore){
		console.log(posterName+" has a new response");
		const payload = {
			notification: {
				title: `AdviceBee`,
				body: "You have a new comment on you post",
				badge: '1',
				sound: 'default'
			}
		}
		notify(payload, posterId)
	}else{
		//check for a new like and its user
		for (const user in newLikes){
			//compare old likes with new likes
			if(newLikes[user]!==oldLikes[user]){
				//if there is a new like set up payload to notify user
				if(newLikes[user]===true){

					//get name of the user who liked the post
					admin.firestore().collection('users').doc(user).get()
					.then(doc => {	
						//set message for user
						const likerName= doc.data().displayName;
						console.log(doc.data().displayName+" liked "+posterName+" post")
						//create payload for new notification
						const payload = {
							notification: {
								title: `AdviceBee`,
								body: `${likerName} liked your post`,
								badge: '1',
								sound: 'default'
							}
						}
						notify(payload, posterId)
						return null
					}).catch(err => {
						console.log("Error: "+err);
						return null
					});
				}else{
					//if we reach here it means someone dislaked the post
					return null
				}
			}
		}

	}
	return null
});


/**
 *  Notify group owner when a new user asks to join
 * 	or when there is a new post in the group
 */
exports.sendNotificationGroupJoinRequest = functions.firestore
.document('groups/{group}')
.onUpdate((change, context) => {
	//get reference to new and old data
	const newData = change.after.data()
	const oldData = change.before.data()

	//list of requests to join
	const oldRequests=oldData.userRequestToJoin
	const newRequests=newData.userRequestToJoin
	
	const groupOwner = newData.createdBy
	const groupName =  newData.groupName

	//if there are newer request
	if(newRequests.length>oldRequests.length){
		//look for newest request
		const userRequesting =  newRequests[newRequests.length-1]

		//get user name 
		admin.firestore().collection('users').doc(userRequesting).get()
		.then(doc => {	
			//set message for user
			const userRequestingName= doc.data().displayName;
			console.log(userRequestingName+" requested to join the group " + groupName)
			//create payload for new notification
			const payload = {
				notification: {
					title: `AdviceBee`,
					body: `${userRequestingName} asked to join your group ${groupName}`,
					badge: '1',
					sound: 'default'
				}
			}
			notify(payload, groupOwner)
			return null
		}).catch(err => {
			console.log("Error: "+err);
			return null
		})
	}
	return null
});

/**
 *	send user  
 */
exports.sendNotificationGroupJoinAccepted = functions.firestore
.document('users/{user}')
.onUpdate((change, context) => {
	//old and new data
	const oldData= change.before.data()
	const newData = change.after.data()

	const pushToken= newData.pushToken
	const displayName= newData.displayName
	
	//old joined group and new ones
	const groupJoinedAfter= newData.joinedGroups
	const groupJoinedBefore= oldData.joinedGroups
	
	//followers
	const oldFollowers = oldData.followers
	const newFollowers = newData.followers

	//if there is a new group joined, check if it was private
	if (groupJoinedAfter>groupJoinedBefore){
		const newGroupJoined = groupJoinedAfter[groupJoinedAfter.length-1]
		admin.firestore().collection('groups').doc(newGroupJoined).get()
		.then(doc => {
			
			console.log(displayName+" joined new group ")
			//if it was private send notification
			if(doc.data().privateGroup===true){
				const groupName= doc.data().groupName
				console.log(displayName+" joined the private group "+groupName )
				const payload = {
					notification: {
						title: `AdviceBee`,
						body: `Your request to join ${groupName} has been accepted`,
						badge: '1',
						sound: 'default'
					}
				}
				admin.messaging().sendToDevice(pushToken, payload)
				.then(response => {
					console.log('Successfully sent message:', response)
					return null;
        		}).catch(error => {
					console.log('Error sending message:', error)
				})
			}
			return null
		}).catch(error =>{
			console.log('Error sending message:', error)
			return null
		})
	}else if(newFollowers>oldFollowers){
		const newFollower = newFollowers[newFollowers.length-1]
		console.log(displayName+" has a new follower")
		admin.firestore().collection('users').doc(newFollower).get()
		.then(doc => {
			const newFollowerName = doc.data().displayName
			console.log(newFollowerName+" started following "+ displayName)
			const payload = {
				notification: {
					title: `AdviceBee`,
					body: `${newFollowerName} started following you`,
					badge: '1',
					sound: 'default'
				}
			}
			admin.messaging().sendToDevice(pushToken, payload)
			.then(response => {
				console.log('Successfully sent message:', response)
				return null;
			}).catch(error => {
				console.log('Error sending message:', error)
			})
			return null
		}).catch(error =>{
			console.log('Error sending message:', error)
		})
	}
	return null;
});

/**
 * 
 * @param  payload: content of message
 * @param  userId : user ID of the person getting the notification
 * 
 */
function notify(payload,userId){
	//get user to send notification to 
	admin
	.firestore()
	.collection('users')
	.doc(userId)
	.get()
	.then(doc => {	
		
		//send notification
		admin
		.messaging()
        .sendToDevice(doc.data().pushToken, payload)
		.then(response => {
			console.log('Successfully sent message:', response)
			return null;
        })
        .catch(error => {
			console.log('Error sending message:', error)
        })
		return null
	
	}).catch(err => {
		console.log("Error: "+err);
	});
}


exports.sendNewChatMessageNotification = functions.firestore
  .document('messages/{groupId1}/{groupId2}/{message}')
  .onCreate((snap, context) => {

    const doc = snap.data()
	const senderId = doc.idFrom
	const receiverID = doc.idTo
	const content = doc.content

	admin.firestore().collection('users').doc(senderId).get()
	.then(document => {
		const senderName= document.data().displayName;
		console.log(senderName)
		//console.log(document)
		const payload = {
			notification: {
				title: `${senderName}`,
				body: `${content}`,
				badge: '1',
				sound: 'default'
			}
		}
		notify(payload, receiverID)
		return null
	}).catch(err => {
		console.log("Error: "+err);
	})
	
    return null
  })
