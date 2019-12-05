//
//  OHAutoNIBi18n.m
//
//  Created by Olivier on 03/11/10.
//  Copyright 2010 FoodReporter. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "OHAutoNIBi18n.h"

static inline NSString* localizedString(NSString* aString);

static inline void localizeUIBarButtonItem(UIBarButtonItem* bbi);
static inline void localizeUIBarItem(UIBarItem* bi);
static inline void localizeUIButton(UIButton* btn);
static inline void localizeUILabel(UILabel* lbl);
static inline void localizeUINavigationItem(UINavigationItem* ni);
static inline void localizeUISearchBar(UISearchBar* sb);
static inline void localizeUISegmentedControl(UISegmentedControl* sc);
static inline void localizeUITextField(UITextField* tf);
static inline void localizeUITextView(UITextView* tv);
static inline void localizeUIViewController(UIViewController* vc);


// ------------------------------------------------------------------------------------------------

static NSBundle* _bundle = nil;
static NSString* _tableName = nil;
static NSMutableArray* _languageArray = nil;

@implementation OHAutoNIBi18n
+ (void)setLocalizationBundle:(NSBundle* __nullable)bundle tableName:(NSString* __nullable)tableName {
    _bundle = bundle ?: [NSBundle mainBundle];
    _tableName = tableName;
}
    
   + (void)setLocalizationArray:(NSMutableArray* __nullable)languageArray {
        _languageArray = languageArray;
    }
@end

@interface NSObject(OHAutoNIBi18n)
-(void)localizeNibObject;
@end


@implementation NSObject(OHAutoNIBi18n)

#define LocalizeIfClass(Cls) if ([self isKindOfClass:[Cls class]]) localize##Cls((Cls*)self)
-(void)localizeNibObject
{
    LocalizeIfClass(UIBarButtonItem);
    else LocalizeIfClass(UIBarItem);
    else LocalizeIfClass(UIButton);
    else LocalizeIfClass(UILabel);
    else LocalizeIfClass(UINavigationItem);
    else LocalizeIfClass(UISearchBar);
    else LocalizeIfClass(UISegmentedControl);
    else LocalizeIfClass(UITextField);
    else LocalizeIfClass(UITextView);
    else LocalizeIfClass(UIViewController);
    
    if (![self isKindOfClass:UITableView.class] && (self.isAccessibilityElement == YES))
    {
        // Security to avoid translating tableView's accessibilityLabel & accessibilityHint
        // since it seems to provoke a crash on some configurations
        // See https://github.com/AliSoftware/OHAutoNIBi18n/issues/3
        self.accessibilityLabel = localizedString(self.accessibilityLabel);
        self.accessibilityHint = localizedString(self.accessibilityHint);
    }
    
    // Call the original awakeFromNib method
    [self localizeNibObject]; // this actually calls the original awakeFromNib (and not localizeNibObject) because we did some method swizzling
}

+(void)load
{
    // Autoload : swizzle -awakeFromNib with -localizeNibObject as soon as the app (and thus this class) is loaded
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method localizeNibObject = class_getInstanceMethod([NSObject class], @selector(localizeNibObject));
        Method awakeFromNib = class_getInstanceMethod([NSObject class], @selector(awakeFromNib));
        method_exchangeImplementations(awakeFromNib, localizeNibObject);
        _bundle = [NSBundle mainBundle];
    });
}

@end

/////////////////////////////////////////////////////////////////////////////

static inline NSString* localizedString(NSString* aString)
{
    if (aString == nil || [aString length] == 0)
        return aString;
    
    // Don't translate strings starting with a digit
    if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[aString characterAtIndex:0]])
        return aString;
    
    NSString* str = nil;
    if ([_languageArray count] != 0) {
        NSPredicate *thePredicate = [NSPredicate predicateWithFormat:@"SELF.key LIKE %@", aString];
        NSArray *filteredList = [_languageArray filteredArrayUsingPredicate:thePredicate];
        
        NSDictionary *selectedDict = [filteredList lastObject];
        if ([selectedDict valueForKey:@"value"] != nil) {
            if ([[selectedDict valueForKey:@"value"] isKindOfClass:[NSString class]] && [
                                                                                         (NSString*) ([selectedDict valueForKey:@"value"]) length] > 0) {
                str = [selectedDict valueForKey:@"value"];
                return str;
            }
        }
    }
#if OHAutoNIBi18n_DEBUG
#warning Debug mode for i18n is active
    static NSString* const kNoTranslation = @"$!";
    NSString* tr = [_bundle localizedStringForKey:aString value:kNoTranslation table:_tableName];
    if ([tr isEqualToString:kNoTranslation])
    {
        if ([aString hasPrefix:@"."])
        {
            // strings in XIB starting with '.' are typically used as temporary placeholder for design
            // and will be replaced by code later, so don't warn about them
            return aString;
        }
        NSLog(@"No translation for string '%@'",aString);
        tr = [NSString stringWithFormat:@"$%@$",aString];
    }
    return tr;
#else
    return [_bundle localizedStringForKey:aString value:nil table:_tableName];
#endif
}


// ------------------------------------------------------------------------------------------------


static inline void localizeUIBarButtonItem(UIBarButtonItem* bbi) {
    localizeUIBarItem(bbi); /* inheritence */
    
    NSMutableSet* locTitles = [[NSMutableSet alloc] initWithCapacity:[bbi.possibleTitles count]];
    for(NSString* str in bbi.possibleTitles) {
        [locTitles addObject:localizedString(str)];
    }
    bbi.possibleTitles = [NSSet setWithSet:locTitles];
#if ! __has_feature(objc_arc)
    [locTitles release];
#endif
}

static inline void localizeUIBarItem(UIBarItem* bi) {
    bi.title = localizedString(bi.title);
}

static inline void localizeUIButton(UIButton* btn) {
    NSString* title[4] = {
        [btn titleForState:UIControlStateNormal],
        [btn titleForState:UIControlStateHighlighted],
        [btn titleForState:UIControlStateDisabled],
        [btn titleForState:UIControlStateSelected]
    };
    
    [btn setTitle:localizedString(title[0]) forState:UIControlStateNormal];
    if (title[1] == [btn titleForState:UIControlStateHighlighted])
        [btn setTitle:localizedString(title[1]) forState:UIControlStateHighlighted];
    if (title[2] == [btn titleForState:UIControlStateDisabled])
        [btn setTitle:localizedString(title[2]) forState:UIControlStateDisabled];
    if (title[3] == [btn titleForState:UIControlStateSelected])
        [btn setTitle:localizedString(title[3]) forState:UIControlStateSelected];
}

static inline void localizeUILabel(UILabel* lbl) {
    lbl.text = localizedString(lbl.text);
}

static inline void localizeUINavigationItem(UINavigationItem* ni) {
    ni.title = localizedString(ni.title);
    ni.prompt = localizedString(ni.prompt);
}

static inline void localizeUISearchBar(UISearchBar* sb) {
    sb.placeholder = localizedString(sb.placeholder);
    sb.prompt = localizedString(sb.prompt);
    sb.text = localizedString(sb.text);
    
    NSMutableArray* locScopesTitles = [[NSMutableArray alloc] initWithCapacity:[sb.scopeButtonTitles count]];
    for(NSString* str in sb.scopeButtonTitles) {
        [locScopesTitles addObject:localizedString(str)];
    }
    sb.scopeButtonTitles = [NSArray arrayWithArray:locScopesTitles];
#if ! __has_feature(objc_arc)
    [locScopesTitles release];
#endif
}

static inline void localizeUISegmentedControl(UISegmentedControl* sc) {
    NSUInteger n = sc.numberOfSegments;
    for(NSUInteger idx = 0; idx<n; ++idx) {
        [sc setTitle:localizedString([sc titleForSegmentAtIndex:idx]) forSegmentAtIndex:idx];
    }
}

static inline void localizeUITextField(UITextField* tf) {
    tf.text = localizedString(tf.text);
    tf.placeholder = localizedString(tf.placeholder);
}

static inline void localizeUITextView(UITextView* tv) {
    tv.text = localizedString(tv.text);
}

static inline void localizeUIViewController(UIViewController* vc) {
    vc.title = localizedString(vc.title);
}

