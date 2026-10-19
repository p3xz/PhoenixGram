#import "SPKProfileSettingsProvider.h"

#import "../../AssetUtils.h"
#import "../../Features/Profile/FollowIndicator.h"
#import "../../Shared/ActionButton/SPKActionButtonConfiguration.h"
#import "../../Utils.h"
#import "../SPKTopicSettingsSupport.h"

static NSString *const kSPKProfileActionNone = @"none";
static NSString *const kSPKProfileActionCopyInfo = @"copy_info";
static NSString *const kSPKProfileActionViewPicture = @"view_picture";
static NSString *const kSPKProfileActionSharePicture = @"share_picture";
static NSString *const kSPKProfileActionSavePictureToGallery = @"save_picture_gallery";
static NSString *const kSPKProfileActionOpenSettings = @"profile_settings";
static NSString *const kSPKProfileDefaultCopyInfoKey = @"profile_action_btn_default_copy_info_action";
static NSString *const kSPKProfileCopyInfoID = @"id";
static NSString *const kSPKProfileCopyInfoUsername = @"username";
static NSString *const kSPKProfileCopyInfoName = @"name";
static NSString *const kSPKProfileCopyInfoBio = @"bio";
static NSString *const kSPKProfileCopyInfoLink = @"link";
static CGFloat const kSPKProfileSettingsMenuIconPointSize = 22.0;

static UIImage *SPKProfileSettingsMenuIcon(NSString *resourceName) {
    return [SPKAssetUtils instagramIconNamed:resourceName pointSize:kSPKProfileSettingsMenuIconPointSize];
}

static UICommand *SPKProfileActionDefaultCommand(NSString *title, NSString *resourceName, NSString *value) {
    UIImage *image = SPKProfileSettingsMenuIcon(resourceName);
    return [UICommand commandWithTitle:title
                                 image:image
                                action:@selector(menuChanged:)
                          propertyList:@{
                              @"defaultsKey" : @"profile_action_btn_default_action",
                              @"value" : value,
                              @"iconName" : resourceName
                          }];
}

static UIMenu *SPKProfileActionDefaultMenu(void) {
    return [UIMenu menuWithChildren:@[
        SPKProfileActionDefaultCommand(@"Open Menu", @"action", kSPKProfileActionNone),
        SPKProfileActionDefaultCommand(@"Copy Info", @"copy", kSPKProfileActionCopyInfo),
        SPKProfileActionDefaultCommand(@"View Picture", @"photo", kSPKProfileActionViewPicture),
        SPKProfileActionDefaultCommand(@"Share Picture", @"share", kSPKProfileActionSharePicture),
        SPKProfileActionDefaultCommand(@"Save to Gallery", @"sparkle_gallery", kSPKProfileActionSavePictureToGallery),
        SPKProfileActionDefaultCommand(@"Profile Settings", @"settings", kSPKProfileActionOpenSettings)
    ]];
}

static UICommand *SPKProfileDefaultCopyInfoCommand(NSString *title, NSString *resourceName, NSString *value) {
    UIImage *image = SPKProfileSettingsMenuIcon(resourceName);
    return [UICommand commandWithTitle:title
                                 image:image
                                action:@selector(menuChanged:)
                          propertyList:@{
                              @"defaultsKey" : kSPKProfileDefaultCopyInfoKey,
                              @"value" : value,
                              @"iconName" : resourceName
                          }];
}

static UIMenu *SPKProfileDefaultCopyInfoMenu(void) {
    return [UIMenu menuWithChildren:@[
        SPKProfileDefaultCopyInfoCommand(@"ID", @"key", kSPKProfileCopyInfoID),
        SPKProfileDefaultCopyInfoCommand(@"Username", @"username", kSPKProfileCopyInfoUsername),
        SPKProfileDefaultCopyInfoCommand(@"Name", @"text", kSPKProfileCopyInfoName),
        SPKProfileDefaultCopyInfoCommand(@"Bio", @"caption", kSPKProfileCopyInfoBio),
        SPKProfileDefaultCopyInfoCommand(@"Profile Link", @"link", kSPKProfileCopyInfoLink)
    ]];
}

static NSString *const kSPKFollowIndicatorModeKey = @"profile_follow_indicator_mode";
static NSString *const kSPKFollowIndicatorModeOff = @"off";
static NSString *const kSPKFollowIndicatorModeText = @"text";
static NSString *const kSPKFollowIndicatorModeIcon = @"icon";
static NSString *const kSPKFollowIndicatorModeIconText = @"icontext";

static NSString *SPKFollowIndicatorEffectiveMode(void) {
    if (![SPKUtils getBoolPref:@"profile_follow_indicator"])
        return kSPKFollowIndicatorModeOff;
    NSString *mode = [SPKUtils getStringPref:kSPKFollowIndicatorModeKey];
    if (mode.length > 0)
        return mode;
    return kSPKFollowIndicatorModeText;
}

static NSString *const kSPKFollowIndicatorColorfulKey = @"profile_follow_indicator_colorful";

static BOOL SPKFollowIndicatorColorfulEnabled(void) {
    id value = SPKPreferenceObjectForKey(kSPKFollowIndicatorColorfulKey);
    if (value == nil)
        return YES;
    return [value boolValue];
}

// No per-item icons: the menu is a plain title list. The cell keeps a static
// leading icon instead of reflecting the selection.
static UICommand *SPKFollowIndicatorModeCommand(NSString *title, NSString *value) {
    return [UICommand commandWithTitle:title
                                 image:nil
                                action:@selector(menuChanged:)
                          propertyList:@{
                              @"defaultsKey" : kSPKFollowIndicatorModeKey,
                              @"value" : value
                          }];
}

static UIMenu *SPKFollowIndicatorModeMenu(void) {
    return [UIMenu menuWithChildren:@[
        SPKFollowIndicatorModeCommand(@"Text", kSPKFollowIndicatorModeText),
        SPKFollowIndicatorModeCommand(@"Icon", kSPKFollowIndicatorModeIcon),
        SPKFollowIndicatorModeCommand(@"Icon & Text", kSPKFollowIndicatorModeIconText)
    ]];
}

@implementation SPKProfileSettingsProvider

+ (SPKSetting *)rootSetting {
    return SPKTopicNavigationSetting(@"Profile", @"user_circle", 24.0, @[
        SPKTopicSection(@"Action Button", @[
            [SPKSetting switchCellWithTitle:@"Profile Action Button"
                                       icon:SPKSettingsIcon(@"action")
                                 defaultsKey:@"profile_action_btn"],
            SPKActionButtonDefaultActionNavigationSetting(SPKActionButtonSourceProfile),
            SPKActionButtonConfigurationNavigationSetting(SPKActionButtonSourceProfile, @"Profile", SPKActionButtonSupportedActionsForSource(SPKActionButtonSourceProfile), SPKActionButtonDefaultSectionsForSource(SPKActionButtonSourceProfile)),
            SPKSettingApplySelectedMenuIcon([SPKSetting menuCellWithTitle:@"Copy Info Default" icon:SPKSettingsIcon(@"copy") menu:SPKProfileDefaultCopyInfoMenu()], SPKSettingsIcon(@"copy"))
        ],
                        @"Choose what tapping the action button does. Copy Info Default controls what gets copied when Default Tap Action is Copy Info."),
        SPKTopicSection(@"Profile Picture", @[
            [SPKSetting switchCellWithTitle:@"Long Press to Expand"
                                       icon:SPKSettingsIcon(@"expand")
                                 defaultsKey:@"profile_photo_zoom"]
        ],
                        @"Long press a profile picture to open it expanded."),
        SPKTopicSection(@"Indicators", @[
            ({
                SPKSetting *toggle = [SPKSetting switchCellWithTitle:@"Follow Status Badge"
                                                                icon:SPKSettingsIcon(@"user_check")
                                                         defaultsKey:@"profile_follow_indicator"];
                toggle.switchChangeHandler = ^(BOOL isOn) {
                    SPKPreferenceSetObject(@(isOn), @"profile_follow_indicator");
                    [[NSNotificationCenter defaultCenter] postNotificationName:SPKFollowIndicatorDidChangeNotification object:nil];
                };
                toggle;
            }),
            ({
                SPKSetting *mode = [SPKSetting menuCellWithTitle:@"Badge Style"
                                                            icon:SPKSettingsIcon(@"palette")
                                                            menu:SPKFollowIndicatorModeMenu()];
                mode.accessoryTextProvider = ^NSString * {
                    NSString *value = SPKFollowIndicatorEffectiveMode();
                    if ([value isEqualToString:kSPKFollowIndicatorModeIcon])
                        return @"Icon";
                    if ([value isEqualToString:kSPKFollowIndicatorModeIconText])
                        return @"Icon + Text";
                    return @"Text";
                };
                mode.hiddenProvider = ^BOOL {
                    return ![SPKUtils getBoolPref:@"profile_follow_indicator"];
                };
                mode;
            }),
            ({
                SPKSetting *colorful = [SPKSetting switchCellWithTitle:@"Colorful Badge"
                                                                  icon:SPKSettingsIcon(@"palette")
                                                           defaultsKey:kSPKFollowIndicatorColorfulKey];
                colorful.switchValueProvider = ^BOOL {
                    return SPKFollowIndicatorColorfulEnabled();
                };
                colorful.switchChangeHandler = ^(BOOL isOn) {
                    SPKPreferenceSetObject(@(isOn), kSPKFollowIndicatorColorfulKey);
                    [[NSNotificationCenter defaultCenter] postNotificationName:SPKFollowIndicatorDidChangeNotification object:nil];
                };
                colorful.hiddenProvider = ^BOOL {
                    return ![SPKUtils getBoolPref:@"profile_follow_indicator"] || [SPKFollowIndicatorEffectiveMode() isEqualToString:kSPKFollowIndicatorModeOff];
                };
                colorful;
            }),
            [SPKSetting switchCellWithTitle:@"Hide Notes Bubble"
                                       icon:SPKSettingsIcon(@"notes")
                                 defaultsKey:@"profile_hide_notes_bubble"],
            [SPKSetting switchCellWithTitle:@"Hide Threads Button"
                                       icon:SPKSettingsIcon(@"threads")
                                 defaultsKey:@"profile_hide_threads_btn"]
        ],
                        @"Follow Status Badge shows whether a profile follows you back (Follows you 😊 in green, or Doesn't follow you 😔 in red), under their stats."),
        SPKTopicSection(@"Confirmation", @[
            [SPKSetting switchCellWithTitle:@"Confirm Follow"
                                       icon:SPKSettingsIcon(@"user_follow")
                                defaultsKey:@"profile_confirm_follow"],
            [SPKSetting switchCellWithTitle:@"Confirm Unfollow"
                                       icon:SPKSettingsIcon(@"user_unfollow")
                                defaultsKey:@"profile_confirm_unfollow"]
        ],
                        @"Shows confirmation alerts before the enabled profile actions are performed.")
    ]);
}

@end
