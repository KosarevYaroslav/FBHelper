//
// Created by Sergey Zhdanov on 17/12/15.
// Copyright (c) 2015 Drive Pixels Studio. All rights reserved.
//

#import "FBHelper.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFNetworkActivityLogger.h"


@interface FBHelper () <FBSDKAppInviteDialogDelegate, FBSDKSharingDelegate>

@property (strong, nonatomic) FBSDKLoginManager *loginManager;
@property (strong, nonatomic) FBHelperCallback inviteCallcack;
@property (strong, nonatomic) FBHelperCallback sharedCallcack;

@end

@implementation FBHelper


#pragma mark -
#pragma mark - Private Methods

- (void)initWithReadPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions;
{
    self.readPermissions = readPermissions;
    self.publishPermissions = publishPermissions;
}

- (BOOL)isSessionValid
{
    return [FBSDKAccessToken currentAccessToken] != nil;
}



- (void)loginCallBack:(FBHelperCallback)callBack
{
    [self loginWithBehavior:FBSDKLoginBehaviorSystemAccount CallBack:callBack];
}

- (void)loginWithBehavior:(FBSDKLoginBehavior)behavior CallBack:(FBHelperCallback)callBack
{
    if (behavior) {
        self.loginManager.loginBehavior = behavior;
    }

    [self.loginManager logInWithReadPermissions: self.readPermissions
                             fromViewController: nil
                                        handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                            if (error) {
                                                callBack(NO, error.localizedDescription);
                                            } else if (result.isCancelled) {
                                                callBack(NO, @"Cancelled");
                                            } else {
                                                if(callBack){
                                                    callBack(!error, result);
                                                }
                                            }
                                        }];
}


- (void)logoutCallBack:(FBHelperCallback)callBack
{
    [self.loginManager logOut];

    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"https://facebook.com/"]];

    for (NSHTTPCookie* cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }

    callBack(YES, @"Logout successfully");
}

- (void)getUserFields:(NSString *)fields callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    [self graphFacebookForMethodGET:@"me" params:@{@"fields" : fields} callBack:callBack];
}


- (void)getUserFriendsCallBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if ([[FBSDKAccessToken currentAccessToken] hasGranted:(@"user_friends")]) {
        [self graphFacebookForMethodGET:@"me/friends" params:nil callBack:callBack];
    } else {

        self.loginManager.loginBehavior = FBSDKLoginBehaviorSystemAccount;
        [self.loginManager logInWithPublishPermissions:self.publishPermissions fromViewController:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (error) {
                callBack(NO, error.localizedDescription);
            } else if (result.isCancelled) {
                callBack(NO, @"Cancelled");
            } else {
                [self graphFacebookForMethodGET:@"me/friends" params:nil callBack:callBack];
            }
        }];
    }
}

- (void)feedPostWithLinkPath:(NSString *)url caption:(NSString *)caption message:(NSString *)message photo:(UIImage *)photo video:(NSData *)videoData callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    //Need to provide POST parameters to the Facebook SDK for the specific post type
    NSString *graphPath = @"me/feed";

    switch (self.postType) {
        case FBPostTypeLink:{
            params[@"link"] = (url != nil) ? url : @"";
            params[@"description"] = (caption != nil) ? caption : @"";
            break;
        }
        case FBPostTypeStatus:{
            params[@"message"] = (message != nil) ? message : @"";
            break;
        }
        case FBPostTypePhoto:{
            graphPath = @"me/photos";
            params[@"source"] = UIImagePNGRepresentation(photo);
            params[@"message"] = (caption != nil) ? caption : @"";
            params[@"link"] = (url != nil) ? url : @"";
            break;
        }
        case FBPostTypeVideo:{
            graphPath = @"me/videos";

            if (videoData == nil) {
                callBack(NO, @"Not logged in");
                return;
            }

            params[@"video.mp4"] = videoData;
            params[@"title"] = caption;
            params[@"description"] = message;
            break;
        }

        default:
            break;
    }

    [self graphFacebookForMethodPOST:graphPath params:params callBack:callBack];
}

- (void)myFeedCallBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    [self graphFacebookForMethodPOST:@"me/feed" params:nil callBack:callBack];
}

- (void)inviteFriendsWithAppLinkURL:(NSURL *)url previewImageURL:(NSURL *)preview callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = url;

    if (preview) {
        //optionally set previewImageURL
        content.appInvitePreviewImageURL = preview;
    }

    [FBSDKAppInviteDialog showFromViewController:nil withContent:content
                                        delegate:self];

    self.inviteCallcack = callBack;
}

- (void)getPagesCallBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if ([[FBSDKAccessToken currentAccessToken] hasGranted:(@"manage_pages")]) {
        [self graphFacebookForMethodGET:@"me/accounts" params:nil callBack:callBack];
    } else {

        self.loginManager.loginBehavior = FBSDKLoginBehaviorSystemAccount;
        [self.loginManager logInWithPublishPermissions:self.publishPermissions fromViewController:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (error) {
                callBack(NO, error.localizedDescription);
            } else if (result.isCancelled) {
                callBack(NO, @"Cancelled");
            } else {
                [self graphFacebookForMethodGET:@"me/accounts" params:nil callBack:callBack];
            }
        }];
    }

}

- (void)getPageById:(NSString *)pageId callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if (!pageId) {
        callBack(NO, @"Page id or name required");
        return;
    }

    [FBHelper graphFacebookForMethodGET:pageId params:nil callBack:callBack];
}

- (void)feedPostForPage:(NSString *)page message:(NSString *)message callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if (!page) {
        callBack(NO, @"Page id or name required");
        return;
    }

    [FBHelper graphFacebookForMethodPOST:[NSString stringWithFormat:@"%@/feed", page] params:@{@"message" : message} callBack:callBack];
}

- (void)feedPostForPage:(NSString *)page message:(NSString *)message photo:(UIImage *)photo callBack:(FBHelperCallback)callBack
{

    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if (!page) {
        callBack(NO, @"Page id or name required");
        return;
    }

    [FBHelper graphFacebookForMethodPOST:[NSString stringWithFormat:@"%@/photos", page] params:@{@"message" : message, @"source" : UIImagePNGRepresentation(photo)} callBack:callBack];
}

- (void)feedPostForPage:(NSString *)page message:(NSString *)message link:(NSString *)url callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if (!page) {
        callBack(NO, @"Page id or name required");
        return;
    }

    [FBHelper graphFacebookForMethodPOST:[NSString stringWithFormat:@"%@/feed", page] params:@{@"message" : message, @"link" : url} callBack:callBack];
}

- (void)feedPostForPage:(NSString *)page video:(NSData *)videoData title:(NSString *)title description:(NSString *)description callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if (!page) {
        callBack(NO, @"Page id or name required");
        return;
    }

    [FBHelper graphFacebookForMethodPOST:[NSString stringWithFormat:@"%@/videos", page]
                                  params:@{@"title" : title,
                                          @"description" : description,
                                          @"video.mp4" : videoData} callBack:callBack];
}

- (void)feedPostAdminForPageName:(NSString *)page message:(NSString *)message callBack:(FBHelperCallback)callBack
{

    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    [FBHelper getPagesCallBack:^(BOOL success, id result) {

        if (success) {

            NSDictionary *dicPageAdmin = nil;

            for (NSDictionary *dic in result[@"data"]) {

                if ([dic[@"name"] isEqualToString:page]) {
                    dicPageAdmin = dic;
                    break;
                }
            }

            if (!dicPageAdmin) {
                callBack(NO, @"Page not found!");
                return;
            }


            FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                    initWithGraphPath:[NSString stringWithFormat:@"%@/feed", dicPageAdmin[@"id"]] parameters:@{@"message" : message} HTTPMethod:@"POST"];

            [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                if (error) {
                    callBack(NO, [error domain]);
                } else {
                    callBack(YES, result);
                }
            }];
        }
    }];
}

- (void)feedPostAdminForPageName:(NSString *)page video:(NSData *)videoData title:(NSString *)title description:(NSString *)description callBack:(FBHelperCallback)callBack
{

    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    [FBHelper getPagesCallBack:^(BOOL success, id result) {

        if (success) {

            NSDictionary *dicPageAdmin = nil;

            for (NSDictionary *dic in result[@"data"]) {

                if ([dic[@"name"] isEqualToString:page]) {
                    dicPageAdmin = dic;
                    break;
                }
            }

            if (!dicPageAdmin) {
                callBack(NO, @"Page not found!");
                return;
            }


            FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                    initWithGraphPath:[NSString stringWithFormat:@"%@/feed", dicPageAdmin[@"id"]]
                           parameters:@{
                                   @"title" : title,
                                   @"description" : description,
                                   @"video.mp4" : videoData,
                                   @"access_token" : dicPageAdmin[@"access_token"]
                           }
                           HTTPMethod:@"POST"];

            [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                if (error) {
                    callBack(NO, [error domain]);
                } else {
                    callBack(YES, result);
                }
            }];
        }
    }];
}

- (void)feedPostAdminForPageName:(NSString *)page message:(NSString *)message link:(NSString *)url callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    [FBHelper getPagesCallBack:^(BOOL success, id result) {

        if (success) {

            NSDictionary *dicPageAdmin = nil;

            for (NSDictionary *dic in result[@"data"]) {

                if ([dic[@"name"] isEqualToString:page]) {
                    dicPageAdmin = dic;
                    break;
                }
            }

            if (!dicPageAdmin) {
                callBack(NO, @"Page not found!");
                return;
            }

            FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                    initWithGraphPath:[NSString stringWithFormat:@"%@/feed", dicPageAdmin[@"id"]]
                           parameters:@{
                                   @"message" : message,
                                   @"link" : url,
                                   @"access_token" : dicPageAdmin[@"access_token"]
                           }
                           HTTPMethod:@"POST"];

            [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                if (error) {
                    callBack(NO, [error domain]);
                } else {
                    callBack(YES, result);
                }
            }];
        }
    }];
}

- (void)feedPostAdminForPageName:(NSString *)page message:(NSString *)message photo:(UIImage *)photo callBack:(FBHelperCallback)callBack
{

    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    [FBHelper getPagesCallBack:^(BOOL success, id result) {

        if (success) {

            NSDictionary *dicPageAdmin = nil;

            for (NSDictionary *dic in result[@"data"]) {

                if ([dic[@"name"] isEqualToString:page]) {
                    dicPageAdmin = dic;
                    break;
                }
            }

            if (!dicPageAdmin) {
                callBack(NO, @"Page not found!");
                return;
            }


            FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                    initWithGraphPath:[NSString stringWithFormat:@"%@/feed", dicPageAdmin[@"id"]]
                           parameters:@{
                                   @"message" : message,
                                   @"source" : UIImagePNGRepresentation(photo),
                                   @"access_token" : dicPageAdmin[@"access_token"]}
                           HTTPMethod:@"POST"];

            [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                if (error) {
                    callBack(NO, [error domain]);
                } else {
                    callBack(YES, result);
                }
            }];
        }
    }];
}

- (void)getAlbumsCallBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    [self graphFacebookForMethodGET:@"me/albums" params:nil callBack:callBack];
}

- (void)getAlbumById:(NSString *)albumId callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if (!albumId) {
        callBack(NO, @"Album id required");
        return;
    }

    [FBHelper graphFacebookForMethodGET:albumId params:nil callBack:callBack];
}

- (void)getPhotosAlbumById:(NSString *)albumId callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if (!albumId) {
        callBack(NO, @"Album id required");
        return;
    }

    [FBHelper graphFacebookForMethodGET:[NSString stringWithFormat:@"%@/photos", albumId] params:nil callBack:callBack];
}

- (void)createAlbumName:(NSString *)name message:(NSString *)message privacy:(FBAlbumPrivacyType)privacy callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if (!name && !message) {
        callBack(NO, @"Name and message required");
        return;
    }

    NSString *privacyString = @"";

    switch (privacy) {
        case FBAlbumPrivacyEveryone:
            privacyString = @"EVERYONE";
            break;
        case FBAlbumPrivacyAllFriends:
            privacyString = @"ALL_FRIENDS";
            break;
        case FBAlbumPrivacyFriendsOfFriends:
            privacyString = @"FRIENDS_OF_FRIENDS";
            break;
        case FBAlbumPrivacySelf:
            privacyString = @"SELF";
            break;
        default:
            break;
    }

    [FBHelper       graphFacebookForMethodPOST:@"me/albums" params:@{@"name" : (name != nil) ? name : @"",
            @"message" : message,
            @"value" : privacyString} callBack:callBack];
}

- (void)feedPostForAlbumId:(NSString *)albumId photo:(UIImage *)photo callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    if (!albumId) {
        callBack(NO, @"Album id required");
        return;
    }

    [FBHelper graphFacebookForMethodPOST:[NSString stringWithFormat:@"%@/photos", albumId] params:@{@"source" : UIImagePNGRepresentation(photo)} callBack:callBack];
}

- (void)sendForPostOpenGraphWithActionType:(NSString *)actionType graphObject:(FBSDKShareOpenGraphObject *)openGraphObject objectName:(NSString *)objectName viewController:(UIViewController *)viewController callBack:(FBHelperCallback)callBack
{
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    FBSDKShareOpenGraphAction *action = [[FBSDKShareOpenGraphAction alloc] init];
    action.actionType = actionType;
    [action setObject:openGraphObject forKey:objectName];
    FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
    content.action = action;
    content.previewPropertyName = objectName;

    [FBSDKShareDialog showFromViewController:viewController
                                 withContent:content
                                    delegate:self];

    self.sharedCallcack = callBack;
}

- (void)graphFacebookForMethodPOST:(NSString *)method params:(id)params callBack:(FBHelperCallback)callBack
{
    [self graphFacebookForMethod:method httpMethod:@"POST" params:params callBack:callBack];
}

- (void)graphFacebookForMethodGET:(NSString *)method params:(id)params callBack:(FBHelperCallback)callBack
{
    [self graphFacebookForMethod:method httpMethod:@"GET" params:params callBack:callBack];
}

- (void)graphFacebookForMethod:(NSString *)method httpMethod:(NSString *)httpMethod params:(id)params callBack:(FBHelperCallback)callBack
{
    [[[FBSDKGraphRequest alloc] initWithGraphPath:method
                                       parameters:params
                                       HTTPMethod:httpMethod]
            startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                if ([error.userInfo[FBSDKGraphRequestErrorGraphErrorCode] isEqual:@200]) {
                    callBack(NO, error);
                } else {
                    callBack(YES, result);
                }
            }];
}

- (void)shareFacebookLink:(NSString *)link title:(NSString *)title description:(NSString *)description imageUrl:(NSString *)imageUrl callBack:(FBHelperCallback)callBack {
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:link];
    content.imageURL = [NSURL URLWithString:imageUrl];
    content.contentDescription = description;
    content.contentTitle = title;

    FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
    dialog.mode = FBSDKShareDialogModeNative;
    dialog.shareContent = content;
    dialog.delegate = self;
    if(!dialog.canShow) {
        dialog.mode = FBSDKShareDialogModeAutomatic;
    }
    if(!dialog.canShow) {
        callBack(NO, @"Can't show share dialog");
        return;
    }

    self.sharedCallcack = callBack;
    [dialog show];
}

- (void)shareFacebookLink:(NSString *)link title:(NSString *)title description:(NSString *)description image:(UIImage *)image callBack:(FBHelperCallback)callBack {
    if (![self isSessionValid]) {
        callBack(NO, @"Not logged in");
        return;
    }

    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    AFHTTPRequestOperationManager *restManager = [AFHTTPRequestOperationManager manager];
    restManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [restManager POST:@"http://uploads.im/api" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.7f);
        [formData appendPartWithFormData:imageData name:@"upload"];
        [formData appendPartWithFileData:imageData name:@"upload" fileName:@"some_file.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *resp = (NSDictionary*)responseObject;
        NSLog(@"resp: %@", resp);
        if([resp[@"status_code"] isEqualToNumber:@200]) {
            NSString *thumbUrl = resp[@"data"][@"thumb_url"];
            if(thumbUrl.length > 0) {
                [self shareFacebookLink:link title:title description:description imageUrl:thumbUrl callBack:callBack];
                return;
            }
        }
        callBack(NO, [NSString stringWithFormat:@"Can't upload image to file hosting: %@", resp]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callBack(NO, @"Can't upload image to file hosting");
    }];
}

#pragma mark -
#pragma mark - FBSDKAppInviteDialogDelegate methods

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results
{
    self.inviteCallcack(YES, results);
    self.inviteCallcack = nil;
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error
{
    self.inviteCallcack(NO, error);
    self.inviteCallcack = nil;
}



#pragma mark -
#pragma mark - FBSDKSharingDelegate methods

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
    self.sharedCallcack(YES, results);
    self.sharedCallcack = nil;
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    self.sharedCallcack(NO, error);
    self.sharedCallcack = nil;
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    self.sharedCallcack(YES, @"Cancelled");
    self.sharedCallcack = nil;
}

#pragma mark -
#pragma mark - Singleton

+ (FBHelper *)shared
{
    static FBHelper *scFacebook = nil;

    @synchronized (self){

        static dispatch_once_t pred;
        dispatch_once(&pred, ^{
            scFacebook = [[FBHelper alloc] init];
            scFacebook.loginManager = [[FBSDKLoginManager alloc] init];
        });
    }

    return scFacebook;
}



#pragma mark -
#pragma mark - Public Methods

+ (void)initWithReadPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions
{
    [[FBHelper shared] initWithReadPermissions:readPermissions publishPermissions:publishPermissions];
}

+(BOOL)isSessionValid
{
    return [[FBHelper shared] isSessionValid];
}

+ (void)loginCallBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] loginCallBack:callBack];
}

+ (void)loginWithBehavior:(FBSDKLoginBehavior)behavior CallBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] loginWithBehavior:behavior CallBack:callBack];
}

+ (void)logoutCallBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] logoutCallBack:callBack];
}

+ (void)getUserFields:(NSString *)fields callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] getUserFields:fields callBack:callBack];
}

+ (void)getUserFriendsCallBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] getUserFriendsCallBack:callBack];
}

+ (void)feedPostWithLinkPath:(NSString *)url caption:(NSString *)caption callBack:(FBHelperCallback)callBack
{
    [FBHelper shared].postType = FBPostTypeLink;
    [[FBHelper shared] feedPostWithLinkPath:url caption:caption message:nil photo:nil video:nil callBack:callBack];
}

+ (void)feedPostWithMessage:(NSString *)message callBack:(FBHelperCallback)callBack
{
    [FBHelper shared].postType = FBPostTypeStatus;
    [[FBHelper shared] feedPostWithLinkPath:nil caption:nil message:message photo:nil video:nil callBack:callBack];
}

+ (void)feedPostWithPhoto:(UIImage *)photo caption:(NSString *)caption callBack:(FBHelperCallback)callBack
{
    [FBHelper shared].postType = FBPostTypePhoto;
    [[FBHelper shared] feedPostWithLinkPath:nil caption:caption message:nil photo:photo video:nil callBack:callBack];
}


+ (void)feedPostWithVideo:(NSData *)videoData title:(NSString *)title description:(NSString *)description callBack:(FBHelperCallback)callBack
{
    [FBHelper shared].postType = FBPostTypeVideo;
    [[FBHelper shared] feedPostWithLinkPath:nil caption:title message:description photo:nil video:videoData callBack:callBack];
}

+ (void)myFeedCallBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] myFeedCallBack:callBack];
}

+ (void)inviteFriendsWithAppLinkURL:(NSURL *)url previewImageURL:(NSURL *)preview callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] inviteFriendsWithAppLinkURL:url previewImageURL:url callBack:callBack];
}

+ (void)getPagesCallBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] getPagesCallBack:callBack];
}

+ (void)getPageById:(NSString *)pageId callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] getPageById:pageId callBack:callBack];
}

+ (void)feedPostForPage:(NSString *)page message:(NSString *)message callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] feedPostForPage:page message:message callBack:callBack];
}

+ (void)feedPostForPage:(NSString *)page message:(NSString *)message photo:(UIImage *)photo callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] feedPostForPage:page message:message photo:photo callBack:callBack];
}

+ (void)feedPostForPage:(NSString *)page message:(NSString *)message link:(NSString *)url callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] feedPostForPage:page message:message link:url callBack:callBack];
}

+ (void)feedPostForPage:(NSString *)page video:(NSData *)videoData title:(NSString *)title description:(NSString *)description callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] feedPostForPage:page video:videoData title:title description:description callBack:callBack];
}

+ (void)feedPostAdminForPageName:(NSString *)page message:(NSString *)message callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] feedPostAdminForPageName:page message:message callBack:callBack];
}

+ (void)feedPostAdminForPageName:(NSString *)page video:(NSData *)videoData title:(NSString *)title description:(NSString *)description callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] feedPostAdminForPageName:page video:videoData title:title description:description callBack:callBack];
}

+ (void)feedPostAdminForPageName:(NSString *)page message:(NSString *)message link:(NSString *)url callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] feedPostAdminForPageName:page message:message link:url callBack:callBack];
}

+ (void)feedPostAdminForPageName:(NSString *)page message:(NSString *)message photo:(UIImage *)photo callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] feedPostAdminForPageName:page message:message photo:photo callBack:callBack];
}

+ (void)getAlbumsCallBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] getAlbumsCallBack:callBack];
}

+ (void)getAlbumById:(NSString *)albumId callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] getAlbumById:albumId callBack:callBack];
}

+ (void)getPhotosAlbumById:(NSString *)albumId callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] getPhotosAlbumById:albumId callBack:callBack];
}

+ (void)createAlbumName:(NSString *)name message:(NSString *)message privacy:(FBAlbumPrivacyType)privacy callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] createAlbumName:name message:message privacy:privacy callBack:callBack];
}

+ (void)feedPostForAlbumId:(NSString *)albumId photo:(UIImage *)photo callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] feedPostForAlbumId:albumId photo:photo callBack:callBack];
}

+ (void)sendForPostOpenGraphWithActionType:(NSString *)actionType graphObject:(FBSDKShareOpenGraphObject *)openGraphObject objectName:(NSString *)objectName viewController:(UIViewController *)viewController callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] sendForPostOpenGraphWithActionType:actionType graphObject:openGraphObject objectName:objectName viewController:(UIViewController *)viewController callBack:callBack];
}

+ (void)graphFacebookForMethodGET:(NSString *)method params:(id)params callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] graphFacebookForMethodGET:method params:params callBack:callBack];
}

+ (void)graphFacebookForMethodPOST:(NSString *)method params:(id)params callBack:(FBHelperCallback)callBack
{
    [[FBHelper shared] graphFacebookForMethodPOST:method params:params callBack:callBack];
}

+ (void)shareFacebookLink:(NSString *)link title:(NSString *)title description:(NSString *)description imageUrl:(NSString *)imageUrl callBack:(FBHelperCallback)callBack {
    [[FBHelper shared] shareFacebookLink:link title:title description:description imageUrl:imageUrl callBack:callBack];
}

+ (void)shareFacebookLink:(NSString *)link title:(NSString *)title description:(NSString *)description image:(UIImage *)image callBack:(FBHelperCallback)callBack {
    [[FBHelper shared] shareFacebookLink:link title:title description:description image:image callBack:callBack];
}

@end
