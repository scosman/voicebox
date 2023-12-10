//
//  Constants.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-07.
//

#ifndef Constants_h
#define Constants_h

#define ACCESSIBLE_SYSTEM_SPACING_MULTIPLE 3.0

// Colors
#define APP_BACKGROUND_UICOLOR [UIColor colorWithRed:0.961 green:0.950 blue:0.922 alpha:1.0]
#define BLACK_TEXT_UICOLOR [UIColor colorWithRed:0.1216 green:0.1216 blue:0.098 alpha:1.0]
#define ACTION_BUTTON_UICOLOR [UIColor colorWithRed:0.4 green:0.502 blue:0.694 alpha:1.0]
#define ACTION_BUTTON_HIGHLIGHT_UICOLOR [UIColor colorWithRed:0.32 green:0.402 blue:0.555 alpha:1.0]
#define ACTION_BUTTON_DISABLED_UICOLOR [[UIColor systemGray4Color] colorWithAlphaComponent:0.6]
#define KEYBOARD_BUTTON_UICOLOR [UIColor colorWithRed:0.6 green:0.702 blue:0.894 alpha:1.0]

#define OPEN_AI_API_TIMEOUT_SECONDS 12.0

#define IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#endif /* Constants_h */
