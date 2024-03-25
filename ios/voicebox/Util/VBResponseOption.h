//
//  VBResponseOption.h
//  voicebox
//
//  Created by Steve Cosman on 2024-03-09.
//

#ifndef VBResponseOption_h
#define VBResponseOption_h

NS_ASSUME_NONNULL_BEGIN

@interface ResponseOption : NSObject

@property (nonatomic, strong) NSString* fullBodyReplacement;

- (bool)hasSuboptions;
- (NSString*)displayName;
- (NSString*)replacementText;
- (NSArray<ResponseOption*>*)subOptions;

@end

@protocol VBMLProvider <NSObject>

- (id)sendSynchronousRequestRaw:(NSError**)error; // return parsed json (dict)
- (NSMutableArray<ResponseOption*>*)sendSynchronousRequest:(NSError**)error;

@end

NS_ASSUME_NONNULL_END

#endif /* VBResponseOption_h */
