//
//  TZWeChatHeader.h
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/4/8.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#ifndef TZWeChatHeader_h
#define TZWeChatHeader_h

#import <Cocoa/Cocoa.h>

@interface MMTableView : NSTableView
@end

@interface MMTableDataSource : NSObject
@property(retain, nonatomic) NSMutableArray *items;
@property(nonatomic) __weak MMTableView *messageTableView;
- (long long)indexOfTableItem:(id)arg1;
@end

#pragma mark - TKkk

FOUNDATION_EXPORT double WeChatPluginVersionNumber;
FOUNDATION_EXPORT const unsigned char WeChatPluginVersionString[];

#pragma mark - 微信原始的部分类与方法

@interface MMBrandChatsViewController : NSObject
- (void)startChatWithContact:(id)arg1;
@end

@interface MMLoginOneClickViewController : NSViewController
@property(nonatomic) NSTextField *descriptionLabel;
- (void)onLoginButtonClicked:(id)arg1;
@property(nonatomic) NSButton *loginButton;
@end

@interface AccountService : NSObject
- (id)GetLastLoginUserName;
- (id)GetLastLoginAutoAuthKey;
- (BOOL)canAutoAuth;
- (void)AutoAuth;
- (void)ManualLogin:(id)arg1 withPassword:(id)arg2;
- (void)ManualLogout;
- (void)QRCodeLoginWithUserName:(id)arg1 password:(id)arg2;
@end

@interface MMLoginViewController : NSObject
@property(retain, nonatomic) MMLoginOneClickViewController *oneClickViewController;
@end

@interface MMMainWindowController : NSWindowController
@property(retain, nonatomic) MMLoginViewController *loginViewController;
- (void)onAuthOK;
- (void)onLogOut;
@end

@class MessageData;
@interface MessageService : NSObject
- (void)onRevokeMsg:(id)arg1;
- (void)OnSyncBatchAddMsgs:(NSArray *)arg1 isFirstSync:(BOOL)arg2;
- (id)SendTextMessage:(id)arg1 toUsrName:(id)arg2 msgText:(id)arg3 atUserList:(id)arg4;
- (id)GetMsgData:(id)arg1 svrId:(long)arg2;
- (void)AddLocalMsg:(id)arg1 msgData:(id)arg2;
- (void)TranscribeVoiceMessage:(id)arg1 completion:(void (^)(void))arg2;
- (BOOL)ClearUnRead:(id)arg1 FromID:(unsigned int)arg2 ToID:(unsigned int)arg3;
- (BOOL)ClearUnRead:(id)arg1 FromCreateTime:(unsigned int)arg2 ToCreateTime:(unsigned int)arg3;
- (BOOL)hasMsgInChat:(id)arg1;
- (id)GetMsgListWithChatName:(id)arg1 fromLocalId:(unsigned int)arg2 limitCnt:(NSInteger)arg3 hasMore:(char *)arg4 sortAscend:(BOOL)arg5;
- (id)GetMsgListWithChatName:(id)arg1 fromCreateTime:(unsigned int)arg2 limitCnt:(NSInteger)arg3 hasMore:(char *)arg4 sortAscend:(BOOL)arg5;
- (BOOL)updateVoiceTextInDBWithMessage:(MessageData *)message;
@end

@interface MMServiceCenter : NSObject
+ (id)defaultCenter;
- (id)getService:(Class)arg1;
@end

@interface SKBuiltinString_t : NSObject
@property(retain, nonatomic, setter=SetString:) NSString *string; // @synthesize string;
@end

@interface AddMsg : NSObject
@property(retain, nonatomic, setter=SetContent:) SKBuiltinString_t *content; // @synthesize content;
@property(retain, nonatomic, setter=SetFromUserName:) SKBuiltinString_t *fromUserName; // @synthesize fromUserName;
@property(nonatomic, setter=SetMsgType:) int msgType; // @synthesize msgType;
@property(retain, nonatomic, setter=SetToUserName:) SKBuiltinString_t *toUserName; // @synthesize toUserName;
@property (nonatomic, assign) unsigned int createTime;
@property(nonatomic, setter=SetNewMsgId:) long long newMsgId;
@end

@class MMChatMessageViewController;
@interface MMChatsViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
@property(nonatomic) __weak NSTableView *tableView;
@property(retain, nonatomic) MMBrandChatsViewController *brandChatsViewController;
@property(readonly, nonatomic) __weak MMChatMessageViewController *chatMessageViewController;
@end

@interface WeChat : NSObject
+ (id)sharedInstance;
@property(nonatomic) MMChatsViewController *chatsViewController;
@property(retain, nonatomic) MMMainWindowController *mainWindowController;
@property(nonatomic) BOOL isAppTerminating;
- (void)startANewChatWithContact:(id)arg1;
- (void)_clearAllUnreadMessages:(id)arg1;
- (void)onAuthOK:(BOOL)arg1;
@property(nonatomic) BOOL hasAuthOK;
@end

@interface ContactStorage : NSObject
- (id)GetSelfContact;
- (id)GetContact:(id)arg1;
- (id)GetAllBrandContacts;
- (id)GetAllFavContacts;
- (id)GetAllFriendContacts;
@end

@interface GroupStorage : NSObject
{
    NSMutableDictionary *m_dictGroupContacts;
}
- (id)GetAllGroups;
- (id)GetGroupMemberContact:(id)arg1;
@end

@interface WCContactData : NSObject
@property(retain, nonatomic) NSString *m_nsUsrName; // @synthesize m_nsUsrName;
@property(nonatomic) unsigned int m_uiFriendScene;  // @synthesize m_uiFriendScene;
@property(retain, nonatomic) NSString *m_nsNickName;    // 用户昵称
@property(retain, nonatomic) NSString *m_nsRemark;      // 备注
@property(retain, nonatomic) NSString *m_nsHeadImgUrl;  // 头像
@property(retain, nonatomic) NSString *m_nsHeadHDImgUrl;
@property(retain, nonatomic) NSString *m_nsHeadHDMd5;
@property(retain, nonatomic) NSString *m_nsAliasName;
@property(nonatomic) BOOL m_isShowRedDot;
- (BOOL)isBrandContact;
- (BOOL)isSelf;
- (id)getGroupDisplayName;
- (id)getContactDisplayUsrName;
- (BOOL)isGroupChat;
- (BOOL)isMMChat;
- (BOOL)isMMContact;
@end

@interface MessageData : NSObject
- (id)initWithMsgType:(long long)arg1;
@property(retain, nonatomic) NSString *fromUsrName;
@property(retain, nonatomic) NSString *toUsrName;
@property(retain, nonatomic) NSString *msgContent;
@property(retain, nonatomic) NSString *msgPushContent;
@property(nonatomic) int messageType;
@property(nonatomic) int msgStatus;
@property(nonatomic) int msgCreateTime;
@property(nonatomic) int mesLocalID;
@property(nonatomic) long long mesSvrID;
@property(retain, nonatomic) NSString *msgVoiceText;
@property(copy, nonatomic) NSString *m_nsEmoticonMD5;
@property(nonatomic) unsigned int m_uiVoiceToTextStatus;
- (BOOL)isChatRoomMessage;
- (NSString *)groupChatSenderDisplayName;
- (id)getRealMessageContent;
- (id)getChatRoomUsrName;
- (BOOL)isSendFromSelf;
- (BOOL)isCustomEmojiMsg;
- (BOOL)isImgMsg;
- (BOOL)isVideoMsg;
- (BOOL)isVoiceMsg;
- (BOOL)canForward;
- (BOOL)IsPlayingSound;
- (id)summaryString:(BOOL)arg1;
- (BOOL)isEmojiAppMsg;
- (BOOL)isAppBrandMsg;
- (BOOL)IsUnPlayed;
- (void)SetPlayed;
@property(retain, nonatomic) NSString *m_nsTitle;
- (id)originalImageFilePath;
@property(retain, nonatomic) NSString *m_nsVideoPath;
@property(retain, nonatomic) NSString *m_nsFilePath;
@property(retain, nonatomic) NSString *m_nsAppMediaUrl;
@property(nonatomic) MessageData *m_refMessageData;
@property(nonatomic) unsigned int m_uiDownloadStatus;
- (void)SetPlayingSoundStatus:(BOOL)arg1;
@end

@interface CUtility : NSObject
+ (BOOL)HasWechatInstance;
+ (unsigned long long)getFreeDiskSpace;
+ (void)ReloadSessionForMsgSync;
+ (id)GetCurrentUserName;
@end
@interface MMSessionInfoPackedInfo: NSObject
@property(retain, nonatomic) WCContactData *m_contact;
@property(retain, nonatomic) MessageData *m_msgData;
@end

@interface MMSessionInfo : NSObject
@property(nonatomic) BOOL m_bIsTop; // @synthesize m_bIsTop;
@property(nonatomic) BOOL m_bShowUnReadAsRedDot;
@property(nonatomic) BOOL m_isMentionedUnread; // @synthesize
@property(retain, nonatomic) NSString *m_nsUserName; // @synthesize m_nsUserName;
@property(retain, nonatomic) MMSessionInfoPackedInfo *m_packedInfo;
@end

@protocol MMChatsTableCellViewDelegate <NSObject>
@optional
- (void)cellViewReloadData:(MMSessionInfo *)arg1;
@end

@interface MMChatsTableCellView : NSTableCellView
@property(nonatomic) __weak id <MMChatsTableCellViewDelegate> delegate;
@property(retain, nonatomic) MMSessionInfo *sessionInfo;
- (void)menuWillOpen:(id)arg1;
- (void)contextMenuSticky:(id)arg1;
- (void)contextMenuDelete:(id)arg1;
- (void)tableView:(NSTableView *)arg1 rowGotMouseDown:(long long)arg2;
@end

@interface MMSessionMgr : NSObject
@property(retain, nonatomic) NSMutableArray *m_arrSession;
- (id)GetSessionAtIndex:(unsigned long long)arg1;
- (void)MuteSessionByUserName:(id)arg1;
//- (void)TopSessionByUserName:(id)arg1;
- (void)UnmuteSessionByUserName:(id)arg1;
- (void)UntopSessionByUserName:(id)arg1;
- (void)deleteSessionWithoutSyncToServerWithUserName:(id)arg1;
- (void)removeSessionOfUser:(id)arg1 isDelMsg:(BOOL)arg2;
- (void)sortSessions;
- (id)getContact:(id)arg1;
@end

@interface LogoutCGI : NSTableCellView
- (void)sendLogoutCGIWithCompletion:(id)arg1;
@end

@interface MMNotificationService : NSObject
- (id)getNotificationContentWithMsgData:(id)arg1;
- (void)userNotificationCenter:(id)arg1 didActivateNotification:(id)arg2;
@end

@interface MMChatMessageDataSource : MMTableDataSource
@end

@interface MMChatMessageViewController : NSViewController
@property(nonatomic) __weak MMTableView *messageTableView;
@property(retain, nonatomic) MMChatMessageDataSource *messageDataSource;
@end

@interface MMMessageTableItem : NSObject
@property(retain, nonatomic) MessageData *message;
@property(nonatomic) unsigned int messageCreateTime;
@property(nonatomic) int type;
@property(nonatomic) BOOL shouldShowGroupChatDisplayName;
@property(nonatomic) __weak MMTableDataSource *tableDataSource;
- (BOOL)isOrientationRight;
- (void)reloadDataForRowView;
@end

@interface MMStickerMessageCellView : NSObject
@property(retain, nonatomic) MMMessageTableItem *messageTableItem;
@property(nonatomic) MMChatMessageViewController *delegate;
- (BOOL)allowCopy;
- (void)contextMenuCopy;
- (id)contextMenu;
@end

@interface MMImageMessageCellView: NSObject
@property(retain, nonatomic) MMMessageTableItem *messageTableItem;
@end

@interface EmoticonMgr : NSObject
@property(retain, nonatomic) MessageData *message;
- (id)getEmotionDataWithMD5:(id)arg1;
- (void)addFavEmoticon:(id)arg1;
- (void)addEmoticonToUploadQueueWithMD5:(id)arg1;
- (void)setAppStickerToastViewDelegate:(id)arg1;
@end

@interface MMComplexContactSearchTaskMgr : NSObject
+ (id)sharedInstance;
- (void)doComplexContactSearch:(id)arg1 searchScene:(unsigned long long)arg2 complete:(void (^)(NSString *,NSArray *, NSArray *, NSArray *,id))arg3 cancelable:(BOOL)arg4;
@end

@interface MMBasicSearchResult : NSObject
@end

@interface MMSearchResultItem : NSObject
@property(retain, nonatomic) MMBasicSearchResult *result;
@end

@interface MMContactSearchLogic : NSObject
@property(retain, nonatomic) NSMutableArray *contactResults;
- (void)doSearchWithKeyword:(id)arg1 searchScene:(unsigned long long)arg2 resultIsShownBlock:(id)arg3 completion:(id)arg4;
@property(retain, nonatomic) NSMutableArray *groupResults;
@property(nonatomic) BOOL isBrandContactSearched;
@property(nonatomic) BOOL isChatLogSearched;
@property(nonatomic) BOOL isContactSearched;
@property(nonatomic) BOOL isGroupContactSearched;
@property(retain, nonatomic) NSMutableArray *oaResults;
- (void)clearAllResults;
- (void)reloadSearchResultDataWithKeyword:(id)arg1 completionBlock:(id)arg2;    //  2.3.17
- (void)reloadSearchResultDataWithCompletionBlock:(id)arg1;                     //  2.3.13
@end

@interface MMComplexContactSearchResult : MMBasicSearchResult
@property(retain, nonatomic) NSString *fieldValue;
@property(retain, nonatomic) WCContactData *contact;
@property(nonatomic) unsigned long long fieldType;  // 1：备注 3：昵称 4：微信号  8：省份  7：市  9：国家
@end

@interface MMComplexGroupContactMembersSearchResult : MMBasicSearchResult
@property(retain, nonatomic) NSMutableArray<MMComplexContactSearchResult *> *membersSearchReults;
@end

@interface MMComplexGroupContactSearchResult : MMBasicSearchResult
@property(nonatomic) unsigned long long searchType;     // 1 名称 2 群成员名称
@property(retain) WCContactData *groupContact;
@property(retain, nonatomic) MMComplexGroupContactMembersSearchResult *groupMembersResult;
@end

@interface MMAvatarService : NSObject
- (NSString *)avatarCachePath;
- (void)avatarImageWithContact:(id)arg1 completion:(void (^)(NSImage *image))arg2;
@end

@interface NSString (MD5)
- (id)md5String;
@end

@interface MMSessionPickerLogic : NSObject
@property(nonatomic) NSArray *selectedUserNames;
@end


@interface MMSessionListView : NSObject
{
    MMSessionPickerLogic *m_logic;
}
@end

@interface MMSessionPickerWindow : NSWindowController
+ (id)shareInstance;
- (void)beginSheetForWindow:(id)arg1 completionHandler:(void(^)(id a1))arg2;
@property(retain, nonatomic) id choosenViewController; // @synthesize
@property(retain, nonatomic) id listViewController; // @synthesize
- (void)setShowsGroupChats:(BOOL)arg1;
- (void)setShowsOfficialAccounts:(BOOL)arg1;
- (void)setShowsOtherNonhumanChats:(BOOL)arg1;
- (void)setType:(unsigned long long)arg1;

@end

@interface AFHTTPResponseSerializer : NSObject
@end

@interface AFURLSessionManager : NSObject
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                          destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                    completionHandler:(void (^)(NSURLResponse *response, NSURL * filePath, NSError * error))completionHandler;
- (id)initWithSessionConfiguration:(id)arg1;
@end

@interface AFHTTPRequestSerializer : NSObject
+ (id)serializer;
@property(nonatomic) unsigned long long cachePolicy;
@end

@interface AFHTTPSessionManager : NSObject
+ (AFHTTPSessionManager *)manager;
@property(retain, nonatomic) AFHTTPRequestSerializer *requestSerializer;
@property(retain, nonatomic) AFHTTPResponseSerializer *responseSerializer;
@end

@interface MMURLHandler : NSObject
- (void)startGetA8KeyWithURL:(id)arg1;
- (BOOL)openURLWithDefault:(id)arg1;
+ (BOOL)containsHTTPString:(id)arg1;
@end

@interface UserDefaultsService : NSObject
- (void)setString:(id)arg1 forKey:(id)arg2;
- (id)stringForKey:(id)arg1;
@end

@interface MMLinkInfo : NSObject
+ (NSRange)rangeOfUrlInString:(id)arg1 withRange:(NSRange)arg2;
@end

@interface MMCDNDownloadMgr : NSObject
- (BOOL)downloadImageWithMessage:(id)arg1;
@end

@interface MMMessageVideoService : NSObject
- (BOOL)downloadVideoWithMessage:(id)arg1;
@end

@interface MMVoiceMessagePlayer : NSObject
+ (id)defaultPlayer;
- (void)playWithVoiceMessage:(id)arg1 isUnplayedBeforePlay:(BOOL)arg2;
- (void)stop;
@end

@interface MultiPlatformStatusSyncMgr : NSObject
- (void)markVoiceMessageAsRead:(id)arg1;
@end

@interface EmoticonDownloadMgr : NSObject
- (void)downloadEmoticonWithMessageData:(id)arg1;
@end

@interface PathUtility : NSObject
+ (id)emoticonPath:(id)arg1;
+ (id)getMsgVideoPathWithMessage:(id)arg1;
+ (id)getMsgVideoPathWithUserName:(id)arg1 localId:(unsigned int)arg2;
@end

@interface MMExtensionCenter : NSObject
- (id)getExtension:(id)arg1;
@end

@interface MMExtension : NSObject
- (BOOL)registerExtension:(id)arg1;
- (void)unregisterExtension:(id)arg1;
@end

@interface EmoticonMsgInfo : NSObject
@property(copy, nonatomic) NSString *cdnUrl;
@property(copy, nonatomic) NSString *m_nsMD5;
@end

@protocol EmoticonDownloadMgrExt <NSObject>
@optional
- (void)emoticonDownloadFailed:(EmoticonMsgInfo *)arg1;
- (void)emoticonDownloadFinished:(EmoticonMsgInfo *)arg1;
@end

@interface MMChatMangerSearchReportMgr : NSObject
@property(retain, nonatomic) NSMutableArray *brandContactSearchResults;
@property(retain, nonatomic) NSMutableArray *chatLogSearchResults;
@property(retain, nonatomic) NSMutableArray *contactSearchResults;
@property(retain, nonatomic) NSMutableArray *groupContactSearchResults;
@end

#pragma mark - TozyZuo

@interface MMMessageCellView : NSTableCellView
@property(nonatomic) BOOL showGroupChatNickName;
@property(retain, nonatomic) NSTextField *groupChatNickNameLabel;
@property(retain, nonatomic) NSView/* MMMessageCellAvatarView */ *avatarImgView;
@property(retain, nonatomic) MMMessageTableItem *messageTableItem;
- (void)populateWithMessage:(id)message;
- (void)updateGroupChatNickName;
@end

@interface NSView (Ext)
+ (id)rootDesc;
+ (id)recursiveDescriptionOfView:(id)arg1 level:(long long)arg2;
- (BOOL)isMouseReallyInside;
- (id)firstSubviewOfClass:(id)arg1;
- (id)rootDescWithLevel6;
- (id)rootDescWithLevel5;
- (id)rootDescWithLevel4;
- (id)rootDescWithLevel3;
- (id)rootDescWithLevel2;
- (id)rootDescWithLevel1;
- (id)rootDescWithLevel:(long long)arg1;
- (id)debugDescription;
- (id)rootDescWithLevel;
- (id)selfDesc;
- (id)screenCacheImageForViewWithRect:(struct CGRect)arg1;
- (id)screenCacheImageForView;
- (id)imageWithSubviews;
@property double cornerRadius;
@property double bottom;
@property double top;
@property double right;
@property double left;
@property double height;
@property double width;
@property double y;
@property double x;
@end

@interface MMTimeStampCellView : MMMessageCellView
+ (double)cellHeightWithMessage:(id)arg1 constrainedToWidth:(double)arg2;
@end

@interface MMVoiceMessageCellView : MMMessageCellView
@property(nonatomic) BOOL isTranslatingVoiceToText;
- (void)contextMenuTranscribe;
- (void)contextMenuWipeOutText;
- (void)prepareForReuse;
@end

@interface MMLogger : NSObject
+ (void)logWithMMLogLevel:(int)arg1 module:(const char *)arg2 file:(const char *)arg3 line:(int)arg4 func:(const char *)arg5 message:(id)arg6;
@end


#endif /* TZWeChatHeader_h */