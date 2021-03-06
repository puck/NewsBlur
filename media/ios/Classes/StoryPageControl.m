//
//  StoryPageControl.m
//  NewsBlur
//
//  Created by Samuel Clay on 11/2/12.
//  Copyright (c) 2012 NewsBlur. All rights reserved.
//

#import "StoryPageControl.h"
#import "StoryDetailViewController.h"
#import "NewsBlurAppDelegate.h"
#import "NewsBlurViewController.h"
#import "FeedDetailViewController.h"
#import "FontSettingsViewController.h"
#import "UserProfileViewController.h"
#import "ShareViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "Base64.h"
#import "Utilities.h"
#import "NSString+HTML.h"
#import "NBContainerViewController.h"
#import "DataUtilities.h"
#import "JSON.h"
#import "TransparentToolbar.h"
#import "UIBarButtonItem+Image.h"
#import "ShareThis.h"
#import "THCircularProgressView.h"

@implementation StoryPageControl

@synthesize appDelegate;
@synthesize currentPage, nextPage, previousPage;
@synthesize circularProgressView;
@synthesize separatorBarButton;
@synthesize spacerBarButton, spacer2BarButton, spacer3BarButton;
@synthesize rightToolbar;
@synthesize buttonPrevious;
@synthesize buttonNext;
@synthesize buttonAction;
@synthesize buttonText;
@synthesize fontSettingsButton;
@synthesize originalStoryButton;
@synthesize subscribeButton;
@synthesize buttonBack;
@synthesize bottomPlaceholderToolbar;
@synthesize popoverController;
@synthesize loadingIndicator;
@synthesize inTouchMove;
@synthesize isDraggingScrollview;
@synthesize waitingForNextUnreadFromServer;
@synthesize storyHUD;
@synthesize scrollingToPage;
@synthesize traverseView;
@synthesize progressView, progressViewContainer;
@synthesize traversePinned, traverseFloating;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
	currentPage = [[StoryDetailViewController alloc] initWithNibName:@"StoryDetailViewController" bundle:nil];
	nextPage = [[StoryDetailViewController alloc] initWithNibName:@"StoryDetailViewController" bundle:nil];
    previousPage = [[StoryDetailViewController alloc] initWithNibName:@"StoryDetailViewController" bundle:nil];
    
    currentPage.appDelegate = appDelegate;
    nextPage.appDelegate = appDelegate;
    previousPage.appDelegate = appDelegate;
    currentPage.view.frame = self.scrollView.frame;
    nextPage.view.frame = self.scrollView.frame;
    previousPage.view.frame = self.scrollView.frame;
    
	[self.scrollView addSubview:currentPage.view];
	[self.scrollView addSubview:nextPage.view];
    [self.scrollView addSubview:previousPage.view];
    [self.scrollView setPagingEnabled:YES];
	[self.scrollView setScrollEnabled:YES];
	[self.scrollView setShowsHorizontalScrollIndicator:NO];
	[self.scrollView setShowsVerticalScrollIndicator:NO];
    
    popoverClass = [WEPopoverController class];
    
    // adding HUD for progress bar
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapProgressBar:)];
    
    CGFloat radius = 8;
    circularProgressView = [[THCircularProgressView alloc]
                            initWithCenter:CGPointMake(self.traverseView.frame.size.width - 101,
                                                       self.traverseView.frame.size.height / 2)
                            radius:radius
                            lineWidth:radius / 4.0f
                            progressMode:THProgressModeFill
                            progressColor:[UIColor colorWithRed:0.612f green:0.62f blue:0.596f alpha:0.4f]
                            progressBackgroundMode:THProgressBackgroundModeCircumference
                            progressBackgroundColor:[UIColor colorWithRed:0.312f green:0.32f blue:0.296f alpha:.02f]
                            percentage:20];
    [self.traverseView addSubview:circularProgressView];
    UIView *tapIndicator = [[UIView alloc] initWithFrame:CGRectMake(circularProgressView.frame.origin.x - circularProgressView.frame.size.width / 2, circularProgressView.frame.origin.y - circularProgressView.frame.size.height / 2, circularProgressView.frame.size.width*2, circularProgressView.frame.size.height*2)];
    [tapIndicator addGestureRecognizer:tap];
    [self.traverseView insertSubview:tapIndicator aboveSubview:circularProgressView];
    self.loadingIndicator.frame = self.circularProgressView.frame;
    self.buttonNext.titleEdgeInsets = UIEdgeInsetsMake(0, 24, 0, 0);

    rightToolbar = [[TransparentToolbar alloc]
                    initWithFrame:CGRectMake(0, 0, 80, 44)];
    
    spacerBarButton = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacerBarButton.width = -12;
    spacer2BarButton = [[UIBarButtonItem alloc]
                        initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer2BarButton.width = -4;
    spacer3BarButton = [[UIBarButtonItem alloc]
                        initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer3BarButton.width = -10;
    
    UIImage *separatorImage = [UIImage imageNamed:@"bar-separator.png"];
    separatorBarButton = [UIBarButtonItem barItemWithImage:separatorImage target:nil action:nil];
    [separatorBarButton setEnabled:NO];
    
    UIImage *settingsImage = [UIImage imageNamed:@"nav_icn_settings.png"];
    fontSettingsButton = [UIBarButtonItem barItemWithImage:settingsImage target:self action:@selector(toggleFontSize:)];
    
    UIImage *markreadImage = [UIImage imageNamed:@"original_button.png"];
    originalStoryButton = [UIBarButtonItem barItemWithImage:markreadImage target:self action:@selector(showOriginalSubview:)];
    
    UIBarButtonItem *subscribeBtn = [[UIBarButtonItem alloc]
                                     initWithTitle:@"Follow User"
                                     style:UIBarButtonSystemItemAction
                                     target:self
                                     action:@selector(subscribeToBlurblog)
                                     ];
    
    self.subscribeButton = subscribeBtn;
    
    // back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"All Sites" style:UIBarButtonItemStyleBordered target:self action:@selector(transitionFromFeedDetail)];
    self.buttonBack = backButton;
    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {        
        [rightToolbar setItems: [NSArray arrayWithObjects:
                                 spacerBarButton,
                                 fontSettingsButton,
                                 spacer2BarButton,
                                 separatorBarButton,
                                 spacer3BarButton,
                                 originalStoryButton, nil]];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightToolbar];
    }
    
    [self.scrollView addObserver:self forKeyPath:@"contentOffset"
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                         context:nil];
    
    _orientation = [UIApplication sharedApplication].statusBarOrientation;
}

- (void)viewWillAppear:(BOOL)animated {
    [self setNextPreviousButtons];
    [appDelegate adjustStoryDetailWebView];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!appDelegate.isSocialView) {
            UIImage *titleImage;
            if (appDelegate.isSocialRiverView && [appDelegate.activeFolder isEqualToString:@"river_global"]) {
                titleImage = [UIImage imageNamed:@"ak-icon-global.png"];
            } else if (appDelegate.isSocialRiverView && [appDelegate.activeFolder isEqualToString:@"river_blurblogs"]) {
                titleImage = [UIImage imageNamed:@"ak-icon-blurblogs.png"];
            } else if (appDelegate.isRiverView && [appDelegate.activeFolder isEqualToString:@"everything"]) {
                titleImage = [UIImage imageNamed:@"ak-icon-allstories.png"];
            } else if (appDelegate.isRiverView && [appDelegate.activeFolder isEqualToString:@"saved_stories"]) {
                titleImage = [UIImage imageNamed:@"clock.png"];
            } else if (appDelegate.isRiverView) {
                titleImage = [UIImage imageNamed:@"g_icn_folder.png"];
            } else {
                NSString *feedIdStr = [NSString stringWithFormat:@"%@",
                                       [appDelegate.activeStory objectForKey:@"story_feed_id"]];
                titleImage = [Utilities getImage:feedIdStr];
            }
            
            UIImageView *titleImageView = [[UIImageView alloc] initWithImage:titleImage];
            if (appDelegate.isRiverView) {
                titleImageView.frame = CGRectMake(0.0, 2.0, 22.0, 22.0);
            } else {
                titleImageView.frame = CGRectMake(0.0, 2.0, 16.0, 16.0);
            }
            titleImageView.hidden = YES;
            titleImageView.contentMode = UIViewContentModeScaleAspectFit;
            self.navigationItem.titleView = titleImageView;
            titleImageView.hidden = NO;
        } else {
            NSString *feedIdStr = [NSString stringWithFormat:@"%@",
                                   [appDelegate.activeFeed objectForKey:@"id"]];
            UIImage *titleImage  = [Utilities getImage:feedIdStr];
            titleImage = [Utilities roundCorneredImage:titleImage radius:6];
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
            imageView.frame = CGRectMake(0.0, 0.0, 28.0, 28.0);
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [imageView setImage:titleImage];
            self.navigationItem.titleView = imageView;
        }
    }
    
    previousPage.view.hidden = YES;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    [self layoutForInterfaceOrientation:orientation];
}

- (void)viewDidAppear:(BOOL)animated {
    // set the subscribeButton flag
    if (appDelegate.isTryFeedView) {
        self.subscribeButton.title = [NSString stringWithFormat:@"Follow %@", [appDelegate.activeFeed objectForKey:@"username"]];
        self.navigationItem.leftBarButtonItem = self.subscribeButton;
        //        self.subscribeButton.tintColor = UIColorFromRGB(0x0a6720);
    }
    appDelegate.isTryFeedView = NO;
    [self applyNewIndex:previousPage.pageIndex pageController:previousPage];
}

- (void)transitionFromFeedDetail {
//    [self performSelector:@selector(resetPages) withObject:self afterDelay:0.5];
    [appDelegate.masterContainerViewController transitionFromFeedDetail];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        
        
        NSLog(@"%f,%f",self.view.frame.size.width,self.view.frame.size.height);
        
    } else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
        
        NSLog(@"%f,%f",self.view.frame.size.width,self.view.frame.size.height);
    }
    [self refreshPages];
    [self layoutForInterfaceOrientation:toInterfaceOrientation];
}

- (void)layoutForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (interfaceOrientation != _orientation) {
        _orientation = interfaceOrientation;
        [self refreshPages];
        previousPage.view.hidden = YES;
    }
}

- (void)resetPages {
    [currentPage clearStory];
    [nextPage clearStory];
    [previousPage clearStory];

    [currentPage hideStory];
    [nextPage hideStory];
    [previousPage hideStory];
    
    CGRect frame = self.scrollView.frame;
    self.scrollView.contentSize = frame.size;
    
//    NSLog(@"Pages are at: %f / %f / %f", previousPage.view.frame.origin.x, currentPage.view.frame.origin.x, nextPage.view.frame.origin.x);
    currentPage.view.frame = self.scrollView.frame;
    nextPage.view.frame = self.scrollView.frame;
    previousPage.view.frame = self.scrollView.frame;

    currentPage.pageIndex = -2;
    nextPage.pageIndex = -2;
    previousPage.pageIndex = -2;
    
}

- (void)refreshPages {
    int pageIndex = currentPage.pageIndex;
    [self resizeScrollView];
    [appDelegate adjustStoryDetailWebView];
    currentPage.pageIndex = -2;
    nextPage.pageIndex = -2;
    previousPage.pageIndex = -2;
    [self changePage:pageIndex animated:NO];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    //    self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * currentPage.pageIndex, 0);
}

- (void)refreshHeaders {
    [currentPage refreshHeader];
    [nextPage refreshHeader];
    [previousPage refreshHeader];
}
- (void)resizeScrollView {
    NSInteger widthCount = self.appDelegate.storyLocationsCount;
	if (widthCount == 0) {
		widthCount = 1;
	}
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width
                                             * widthCount,
                                             self.scrollView.frame.size.height);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && UIInterfaceOrientationIsPortrait(orientation)) {
        UITouch *theTouch = [touches anyObject];
        if ([theTouch.view isKindOfClass: UIToolbar.class] || [theTouch.view isKindOfClass: UIView.class]) {
            self.inTouchMove = YES;
//            CGPoint touchLocation = [theTouch locationInView:self.view];
//            CGFloat y = touchLocation.y;
//            [appDelegate.masterContainerViewController dragStoryToolbar:y];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && UIInterfaceOrientationIsPortrait(orientation)) {
        UITouch *theTouch = [touches anyObject];
        
        if (([theTouch.view isKindOfClass: UIToolbar.class] || [theTouch.view isKindOfClass: UIView.class]) && self.inTouchMove) {
            self.inTouchMove = NO;
            [appDelegate.masterContainerViewController adjustFeedDetailScreenForStoryTitles];
        }
    }
}

#pragma mark -
#pragma mark Side scroll view

- (void)applyNewIndex:(NSInteger)newIndex pageController:(StoryDetailViewController *)pageController {
	NSInteger pageCount = [[appDelegate activeFeedStoryLocations] count];
	BOOL outOfBounds = newIndex >= pageCount || newIndex < 0;
    
	if (!outOfBounds) {
		CGRect pageFrame = pageController.view.frame;
		pageFrame.origin.y = 0;
		pageFrame.origin.x = self.scrollView.frame.size.width * newIndex;
        pageFrame.size.height = self.scrollView.frame.size.height;
        pageController.view.hidden = NO;
		pageController.view.frame = pageFrame;
	} else {
//        NSLog(@"Out of bounds: was %d, now %d", pageController.pageIndex, newIndex);
		CGRect pageFrame = pageController.view.frame;
		pageFrame.origin.x = self.scrollView.frame.size.width * newIndex;
		pageFrame.origin.y = self.scrollView.frame.size.height;
        pageFrame.size.height = self.scrollView.frame.size.height;
        pageController.view.hidden = YES;
		pageController.view.frame = pageFrame;
	}
    
	pageController.pageIndex = newIndex;
//    NSLog(@"Applied Index: Was %d, now %d (%d/%d/%d) [%d stories - %d]", wasIndex, newIndex, previousPage.pageIndex, currentPage.pageIndex, nextPage.pageIndex, [appDelegate.activeFeedStoryLocations count], outOfBounds);
    
    if (newIndex > 0 && newIndex >= [appDelegate.activeFeedStoryLocations count]) {
        pageController.pageIndex = -2;
        if (self.appDelegate.feedDetailViewController.feedPage < 100 &&
            !self.appDelegate.feedDetailViewController.pageFinished &&
            !self.appDelegate.feedDetailViewController.pageFetching) {
            [self.appDelegate.feedDetailViewController fetchNextPage:^() {
//                NSLog(@"Fetched next page, %d stories", [appDelegate.activeFeedStoryLocations count]);
                [self applyNewIndex:newIndex pageController:pageController];
            }];
        } else if (!self.appDelegate.feedDetailViewController.pageFinished &&
                   !self.appDelegate.feedDetailViewController.pageFetching) {
            [appDelegate.navigationController
             popToViewController:[appDelegate.navigationController.viewControllers
                                  objectAtIndex:0]
             animated:YES];
            [appDelegate hideStoryDetailView];
        }
    } else if (!outOfBounds) {
        int location = [appDelegate indexFromLocation:pageController.pageIndex];
        [pageController setActiveStoryAtIndex:location];
        [pageController clearStory];
        if (self.isDraggingScrollview ||
            self.scrollingToPage < 0 ||
            abs(newIndex - self.scrollingToPage) <= 1) {
            [pageController initStory];
            [pageController drawStory];
        } else {
            [pageController clearStory];
//            NSLog(@"Skipping drawing %d (waiting for %d)", newIndex, self.scrollingToPage);
        }
    } else if (outOfBounds) {
        [pageController clearStory];
    }
    
    [self resizeScrollView];
    [self setTextButton];
    [self.loadingIndicator stopAnimating];
    self.circularProgressView.hidden = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
//    [sender setContentOffset:CGPointMake(sender.contentOffset.x, 0)];
    CGFloat pageWidth = self.scrollView.frame.size.width;
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
	
	NSInteger lowerNumber = floor(fractionalPage);
	NSInteger upperNumber = lowerNumber + 1;
	NSInteger previousNumber = lowerNumber - 1;
	
    int storyCount = [appDelegate.activeFeedStoryLocations count];
    if (storyCount == 0 || lowerNumber > storyCount) return;
    
//    NSLog(@"Did Scroll: %f = %d (%d/%d/%d)", fractionalPage, lowerNumber, previousPage.pageIndex, currentPage.pageIndex, nextPage.pageIndex);
	if (lowerNumber == currentPage.pageIndex) {
		if (upperNumber != nextPage.pageIndex) {
//            NSLog(@"Next was %d, now %d (A)", nextPage.pageIndex, upperNumber);
			[self applyNewIndex:upperNumber pageController:nextPage];
		}
		if (previousNumber != previousPage.pageIndex) {
//            NSLog(@"Prev was %d, now %d (A)", previousPage.pageIndex, previousNumber);
			[self applyNewIndex:previousNumber pageController:previousPage];
		}
	} else if (upperNumber == currentPage.pageIndex) {
        // Going backwards
		if (lowerNumber != previousPage.pageIndex) {
//            NSLog(@"Prev was %d, now %d (B)", previousPage.pageIndex, previousNumber);
			[self applyNewIndex:lowerNumber pageController:previousPage];
		}
	} else {
        // Going forwards
		if (lowerNumber == nextPage.pageIndex) {
//            NSLog(@"Prev was %d, now %d (C1)", previousPage.pageIndex, previousNumber);
//			[self applyNewIndex:upperNumber pageController:nextPage];
//			[self applyNewIndex:lowerNumber pageController:currentPage];
			[self applyNewIndex:previousNumber pageController:previousPage];
		} else if (upperNumber == nextPage.pageIndex) {
//            NSLog(@"Prev was %d, now %d (C2)", previousPage.pageIndex, previousNumber);
			[self applyNewIndex:lowerNumber pageController:currentPage];
			[self applyNewIndex:previousNumber pageController:previousPage];
		} else {
//            NSLog(@"Next was %d, now %d (C3)", nextPage.pageIndex, upperNumber);
//            NSLog(@"Current was %d, now %d (C3)", currentPage.pageIndex, lowerNumber);
//            NSLog(@"Prev was %d, now %d (C3)", previousPage.pageIndex, previousNumber);
			[self applyNewIndex:lowerNumber pageController:currentPage];
			[self applyNewIndex:upperNumber pageController:nextPage];
			[self applyNewIndex:previousNumber pageController:previousPage];
		}
	}
    
//    if (self.isDraggingScrollview) {
        [self setStoryFromScroll];
//    }
    
    // Stick to bottom
    CGRect tvf = self.traverseView.frame;
    traversePinned = YES;
    [UIView animateWithDuration:.3 delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.traverseView.frame = CGRectMake(tvf.origin.x,
                                                              self.scrollView.frame.size.height - tvf.size.height,
                                                              tvf.size.width, tvf.size.height);
                         self.traverseView.alpha = 1;
                         self.traversePinned = YES;
                     } completion:^(BOOL finished) {
                         
                     }];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isDraggingScrollview = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)newScrollView
{
	[self scrollViewDidEndScrollingAnimation:newScrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)newScrollView
{
    self.isDraggingScrollview = NO;
    CGFloat pageWidth = self.scrollView.frame.size.width;
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
	NSInteger nearestNumber = lround(fractionalPage);
    self.scrollingToPage = nearestNumber;
    [self setStoryFromScroll];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
        [keyPath isEqual:@"contentOffset"] &&
        self.isDraggingScrollview) {
        CGFloat pageWidth = self.scrollView.frame.size.width;
        float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
        NSInteger nearestNumber = lround(fractionalPage);
        
        if (![appDelegate.activeFeedStories count]) return;
        
        int storyIndex = [appDelegate indexFromLocation:nearestNumber];
        if (storyIndex != [appDelegate indexOfActiveStory]) {
            appDelegate.activeStory = [appDelegate.activeFeedStories objectAtIndex:storyIndex];
            [appDelegate changeActiveFeedDetailRow];
        }
    }
}

- (void)changePage:(NSInteger)pageIndex {
    [self changePage:pageIndex animated:YES];
}

- (void)changePage:(NSInteger)pageIndex animated:(BOOL)animated {
//    NSLog(@"changePage to %d (animated: %d)", pageIndex, animated);
	// update the scroll view to the appropriate page
    [self resizeScrollView];

    CGRect frame = self.scrollView.frame;
    frame.origin.x = frame.size.width * pageIndex;
    frame.origin.y = 0;

    self.scrollingToPage = pageIndex;

    // Check if already on the selected page
    if (self.scrollView.contentOffset.x == frame.origin.x) {
        [self applyNewIndex:pageIndex pageController:currentPage];
        [self setStoryFromScroll];
    } else {
        [self.scrollView scrollRectToVisible:frame animated:animated];
        if (!animated) {
            [self setStoryFromScroll];
        }
    }
}

- (void)setStoryFromScroll {
    [self setStoryFromScroll:NO];
}

- (void)setStoryFromScroll:(BOOL)force {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
	NSInteger nearestNumber = lround(fractionalPage);
    
    if (!force && currentPage.pageIndex > 0 &&
        currentPage.pageIndex == nearestNumber &&
        currentPage.pageIndex != self.scrollingToPage) {
//        NSLog(@"Skipping setStoryFromScroll: currentPage is %d (%d, %d)", currentPage.pageIndex, nearestNumber, self.scrollingToPage);
        return;
    }
    
	if (currentPage.pageIndex < nearestNumber) {
//        NSLog(@"Swap next into current, current into previous: %d / %d", currentPage.pageIndex, nearestNumber);
		StoryDetailViewController *swapCurrentController = currentPage;
		StoryDetailViewController *swapPreviousController = previousPage;
		currentPage = nextPage;
		previousPage = swapCurrentController;
        nextPage = swapPreviousController;
	} else if (currentPage.pageIndex > nearestNumber) {
//        NSLog(@"Swap previous into current: %d / %d", currentPage.pageIndex, nearestNumber);
		StoryDetailViewController *swapCurrentController = currentPage;
		StoryDetailViewController *swapNextController = nextPage;
		currentPage = previousPage;
		nextPage = swapCurrentController;
        previousPage = swapNextController;
    }
    
//    NSLog(@"Set Story from scroll: %f = %d (%d/%d/%d)", fractionalPage, nearestNumber, previousPage.pageIndex, currentPage.pageIndex, nextPage.pageIndex);
    
    nextPage.webView.scrollView.scrollsToTop = NO;
    previousPage.webView.scrollView.scrollsToTop = NO;
    currentPage.webView.scrollView.scrollsToTop = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        appDelegate.feedDetailViewController.storyTitlesTable.scrollsToTop = NO;
    }
    self.scrollView.scrollsToTop = NO;
    
    if (self.isDraggingScrollview || self.scrollingToPage == currentPage.pageIndex) {
        if (currentPage.pageIndex == -2) return;
        self.scrollingToPage = -1;
        int storyIndex = [appDelegate indexFromLocation:currentPage.pageIndex];
        appDelegate.activeStory = [appDelegate.activeFeedStories objectAtIndex:storyIndex];
        [self updatePageWithActiveStory:currentPage.pageIndex];
    }
}

- (void)advanceToNextUnread {
    if (!self.waitingForNextUnreadFromServer) {
        return;
    }
    
    self.waitingForNextUnreadFromServer = NO;
    [self doNextUnreadStory];
}

- (void)updatePageWithActiveStory:(int)location {
    [self markStoryAsRead];
    [appDelegate pushReadStory:[appDelegate.activeStory objectForKey:@"id"]];
    
    self.bottomPlaceholderToolbar.hidden = YES;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [rightToolbar setItems: [NSArray arrayWithObjects:
                                 spacerBarButton,
                                 fontSettingsButton,
                                 spacer2BarButton,
                                 separatorBarButton,
                                 spacer3BarButton,
                                 originalStoryButton, nil]];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightToolbar];
    }
    
    [self setNextPreviousButtons];
    [appDelegate changeActiveFeedDetailRow];
    
    if (self.currentPage.pageIndex != location) {
//        NSLog(@"Updating Current: from %d to %d", currentPage.pageIndex, location);
        [self applyNewIndex:location pageController:self.currentPage];
    }
    if (self.nextPage.pageIndex != location+1) {
//        NSLog(@"Updating Next: from %d to %d", nextPage.pageIndex, location+1);
        [self applyNewIndex:location+1 pageController:self.nextPage];
    }
    if (self.previousPage.pageIndex != location-1) {
//        NSLog(@"Updating Previous: from %d to %d", previousPage.pageIndex, location-1);
        [self applyNewIndex:location-1 pageController:self.previousPage];
    }
}

- (void)requestFailed:(id)request {
    NSString *error;
    if ([request class] == [ASIHTTPRequest class]) {
        NSLog(@"Error in story detail: %@", [request error]);
        if ([request error]) {
            error = [NSString stringWithFormat:@"%@", [request error]];
        } else {
            error = @"The server barfed!";
        }
    } else {
        error = request;
    }
    [self informError:error];
}

- (void)requestFailedMarkStoryRead:(ASIHTTPRequest *)request {
    [self informError:@"Failed to mark story as read"];
}


#pragma mark -
#pragma mark Actions

- (void)setNextPreviousButtons {
    // setting up the PREV BUTTON
    int readStoryCount = [appDelegate.readStories count];
    if (readStoryCount == 0 ||
        (readStoryCount == 1 &&
         [appDelegate.readStories lastObject] == [appDelegate.activeStory objectForKey:@"id"])) {
            [buttonPrevious setEnabled:NO];
            [buttonPrevious setAlpha:.4];
        } else {
            [buttonPrevious setEnabled:YES];
            [buttonPrevious setAlpha:1];
        }
    
    // setting up the NEXT UNREAD STORY BUTTON
    buttonNext.enabled = YES;
    int nextIndex = [appDelegate indexOfNextUnreadStory];
    int unreadCount = [appDelegate unreadCount];
    if ((nextIndex == -1 && unreadCount > 0) ||
        nextIndex != -1) {
        [buttonNext setTitle:@"NEXT" forState:UIControlStateNormal];
        [buttonNext setBackgroundImage:[UIImage imageNamed:@"traverse_next.png"] forState:UIControlStateNormal];
    } else {
        [buttonNext setTitle:@"DONE" forState:UIControlStateNormal];
        [buttonNext setBackgroundImage:[UIImage imageNamed:@"traverse_done.png"] forState:UIControlStateNormal];
    }
    
    float unreads = (float)[appDelegate unreadCount];
    float total = [appDelegate originalStoryCount];
    float progress = (total - unreads) / total;
    circularProgressView.percentage = progress;
}

- (void)setTextButton {
    if (currentPage.inTextView) {
        [buttonText setTitle:[@"Story" uppercaseString] forState:UIControlStateNormal];
        [buttonText setBackgroundImage:[UIImage imageNamed:@"traverse_text_on.png"]
                              forState:nil];
        self.buttonText.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -44);
    } else {
        [buttonText setTitle:[@"Text" uppercaseString] forState:UIControlStateNormal];
        [buttonText setBackgroundImage:[UIImage imageNamed:@"traverse_text.png"]
                              forState:nil];
        self.buttonText.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -40);
    }
}

- (void)markStoryAsRead {
    //    NSLog(@"[appDelegate.activeStory objectForKey:@read_status] intValue] %i", [[appDelegate.activeStory objectForKey:@"read_status"] intValue]);
    if ([[appDelegate.activeStory objectForKey:@"read_status"] intValue] != 1) {
        
        [appDelegate markActiveStoryRead];
        
        NSString *urlString;
        if (appDelegate.isSocialView || appDelegate.isSocialRiverView) {
            urlString = [NSString stringWithFormat:@"http://%@/reader/mark_social_stories_as_read",
                         NEWSBLUR_URL];
        } else {
            urlString = [NSString stringWithFormat:@"http://%@/reader/mark_story_as_read",
                         NEWSBLUR_URL];
        }
        
        NSURL *url = [NSURL URLWithString:urlString];
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        
        if (appDelegate.isSocialRiverView) {
            // grab the user id from the shared_by_friends
            NSArray *storyId = [NSArray arrayWithObject:[appDelegate.activeStory objectForKey:@"id"]];
            NSString *friendUserId;
            
            if ([[appDelegate.activeStory objectForKey:@"shared_by_friends"] count]) {
                friendUserId = [NSString stringWithFormat:@"%@",
                                [[appDelegate.activeStory objectForKey:@"shared_by_friends"] objectAtIndex:0]];
            } else if ([[appDelegate.activeStory objectForKey:@"commented_by_friends"] count]) {
                friendUserId = [NSString stringWithFormat:@"%@",
                                [[appDelegate.activeStory objectForKey:@"commented_by_friends"] objectAtIndex:0]];
            } else {
                friendUserId = [NSString stringWithFormat:@"%@",
                                [[appDelegate.activeStory objectForKey:@"share_user_ids"] objectAtIndex:0]];
            }
            
            NSDictionary *feedStory = [NSDictionary dictionaryWithObject:storyId
                                                                  forKey:[NSString stringWithFormat:@"%@",
                                                                          [appDelegate.activeStory objectForKey:@"story_feed_id"]]];
            
            NSDictionary *usersFeedsStories = [NSDictionary dictionaryWithObject:feedStory
                                                                          forKey:friendUserId];
            
            [request setPostValue:[usersFeedsStories JSONRepresentation] forKey:@"users_feeds_stories"];
        } else if (appDelegate.isSocialView) {
            NSArray *storyId = [NSArray arrayWithObject:[appDelegate.activeStory objectForKey:@"id"]];
            NSDictionary *feedStory = [NSDictionary dictionaryWithObject:storyId
                                                                  forKey:[NSString stringWithFormat:@"%@",
                                                                          [appDelegate.activeStory objectForKey:@"story_feed_id"]]];
            
            NSDictionary *usersFeedsStories = [NSDictionary dictionaryWithObject:feedStory
                                                                          forKey:[NSString stringWithFormat:@"%@",
                                                                                  [appDelegate.activeStory objectForKey:@"social_user_id"]]];
            
            [request setPostValue:[usersFeedsStories JSONRepresentation] forKey:@"users_feeds_stories"];
        } else {
            [request setPostValue:[appDelegate.activeStory
                                   objectForKey:@"id"]
                           forKey:@"story_id"];
            [request setPostValue:[appDelegate.activeStory
                                   objectForKey:@"story_feed_id"]
                           forKey:@"feed_id"];
        }
        
        [request setDidFinishSelector:@selector(finishMarkAsRead:)];
        [request setDidFailSelector:@selector(requestFailedMarkStoryRead:)];
        [request setDelegate:self];
        [request startAsynchronous];
    }
}


- (void)finishMarkAsRead:(ASIHTTPRequest *)request {
    if ([request responseStatusCode] != 200) {
        return [self requestFailedMarkStoryRead:request];
    }
    
    //    NSString *responseString = [request responseString];
    //    NSDictionary *results = [[NSDictionary alloc]
    //                             initWithDictionary:[responseString JSONValue]];
    //    NSLog(@"results in mark as read is %@", results);
}

- (void)openSendToDialog {
    NSURL *url = [NSURL URLWithString:[appDelegate.activeStory
                                       objectForKey:@"story_permalink"]];
    NSString *title = [appDelegate.activeStory
                       objectForKey:@"story_title"];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [ShareThis showShareOptionsToShareUrl:url title:title image:nil onViewController:self.appDelegate.masterContainerViewController];
    } else {
        [ShareThis showShareOptionsToShareUrl:url title:title image:nil onViewController:self];
    }
}

- (void)markStoryAsSaved {
    NSString *urlString = [NSString stringWithFormat:@"http://%@/reader/mark_story_as_starred",
                           NEWSBLUR_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    
    [request setPostValue:[appDelegate.activeStory
                           objectForKey:@"id"]
                   forKey:@"story_id"];
    [request setPostValue:[appDelegate.activeStory
                           objectForKey:@"story_feed_id"]
                   forKey:@"feed_id"];
    
    [request setDidFinishSelector:@selector(finishMarkAsSaved:)];
    [request setDidFailSelector:@selector(requestFailed:)];
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)finishMarkAsSaved:(ASIHTTPRequest *)request {
    if ([request responseStatusCode] != 200) {
        return [self requestFailed:request];
    }
    
    [appDelegate markActiveStorySaved:YES];
    [self.currentPage flashCheckmarkHud:@"saved"];
}

- (void)markStoryAsUnsaved {
    //    [appDelegate markActiveStoryUnread];
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/reader/mark_story_as_unstarred",
                           NEWSBLUR_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    
    [request setPostValue:[appDelegate.activeStory
                           objectForKey:@"id"]
                   forKey:@"story_id"];
    [request setPostValue:[appDelegate.activeStory
                           objectForKey:@"story_feed_id"]
                   forKey:@"feed_id"];
    
    [request setDidFinishSelector:@selector(finishMarkAsUnsaved:)];
    [request setDidFailSelector:@selector(requestFailed:)];
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)finishMarkAsUnsaved:(ASIHTTPRequest *)request {
    if ([request responseStatusCode] != 200) {
        return [self requestFailed:request];
    }
    
    //    [appDelegate markActiveStoryUnread];
    //    [appDelegate.feedDetailViewController redrawUnreadStory];
    
    [appDelegate markActiveStorySaved:NO];
    [self.currentPage flashCheckmarkHud:@"unsaved"];
}

- (void)markStoryAsUnread {
    if ([[appDelegate.activeStory objectForKey:@"read_status"] intValue] == 1) {
        NSString *urlString = [NSString stringWithFormat:@"http://%@/reader/mark_story_as_unread",
                               NEWSBLUR_URL];
        NSURL *url = [NSURL URLWithString:urlString];
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        
        [request setPostValue:[appDelegate.activeStory
                               objectForKey:@"id"]
                       forKey:@"story_id"];
        [request setPostValue:[appDelegate.activeStory
                               objectForKey:@"story_feed_id"]
                       forKey:@"feed_id"];
        
        [request setDidFinishSelector:@selector(finishMarkAsUnread:)];
        [request setDidFailSelector:@selector(requestFailed:)];
        [request setDelegate:self];
        [request startAsynchronous];
    }
}

- (void)finishMarkAsUnread:(ASIHTTPRequest *)request {
    if ([request responseStatusCode] != 200) {
        return [self requestFailed:request];
    }
    
    NSString *responseString = [request responseString];
    NSDictionary *results = [[NSDictionary alloc]
                             initWithDictionary:[responseString JSONValue]];
    
    if ([[results objectForKey:@"code"] intValue] < 0) {
        return [self requestFailed:[results objectForKey:@"message"]];
    }
    
    [appDelegate markActiveStoryUnread];
    [appDelegate.feedDetailViewController redrawUnreadStory];
    [self setNextPreviousButtons];
    
    [self.currentPage flashCheckmarkHud:@"unread"];
}

- (IBAction)showOriginalSubview:(id)sender {
    NSURL *url = [NSURL URLWithString:[appDelegate.activeStory
                                       objectForKey:@"story_permalink"]];
    [appDelegate showOriginalStory:url];
}

- (IBAction)tapProgressBar:(id)sender {
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	hud.mode = MBProgressHUDModeText;
	hud.removeFromSuperViewOnHide = YES;
    int unreadCount = appDelegate.unreadCount;
    if (unreadCount == 0) {
        hud.labelText = @"No unread stories";
    } else if (unreadCount == 1) {
        hud.labelText = @"1 story left";
    } else {
        hud.labelText = [NSString stringWithFormat:@"%i stories left", unreadCount];
    }
	[hud hide:YES afterDelay:0.8];
}

- (void)subscribeToBlurblog {
    [self.currentPage subscribeToBlurblog];
}

- (IBAction)toggleView:(id)sender {
    [self.currentPage fetchTextView];
}

#pragma mark -
#pragma mark Styles


- (IBAction)toggleFontSize:(id)sender {    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [appDelegate.masterContainerViewController showFontSettingsPopover:self.fontSettingsButton];
    } else {
        if (self.popoverController == nil) {
            self.popoverController = [[WEPopoverController alloc]
                                      initWithContentViewController:appDelegate.fontSettingsViewController];
            
            self.popoverController.delegate = self;
        } else {
            [self.popoverController dismissPopoverAnimated:YES];
            self.popoverController = nil;
        }
        
        if ([self.popoverController respondsToSelector:@selector(setContainerViewProperties:)]) {
            [self.popoverController setContainerViewProperties:[self improvedContainerViewProperties]];
        }
        [self.popoverController setPopoverContentSize:CGSizeMake(240, 38*7-2)];
        [self.popoverController presentPopoverFromBarButtonItem:self.fontSettingsButton
                                       permittedArrowDirections:UIPopoverArrowDirectionAny
                                                       animated:YES];
    }
}

- (void)setFontStyle:(NSString *)fontStyle {
    [self.currentPage setFontStyle:fontStyle];
    [self.nextPage setFontStyle:fontStyle];
    [self.previousPage setFontStyle:fontStyle];
}

- (void)changeFontSize:(NSString *)fontSize {
    [self.currentPage changeFontSize:fontSize];
    [self.nextPage changeFontSize:fontSize];
    [self.previousPage changeFontSize:fontSize];
}

- (void)showShareHUD:(NSString *)msg {
//    [MBProgressHUD hideHUDForView:self.view animated:NO];
    self.storyHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.storyHUD.labelText = msg;
    self.storyHUD.margin = 20.0f;
    self.currentPage.noStorySelectedLabel.hidden = YES;
    self.nextPage.noStorySelectedLabel.hidden = YES;
    self.previousPage.noStorySelectedLabel.hidden = YES;
}

#pragma mark -
#pragma mark Story Traversal

- (IBAction)doNextUnreadStory {
    FeedDetailViewController *fdvc = self.appDelegate.feedDetailViewController;
    int nextLocation = [appDelegate locationOfNextUnreadStory];
    int unreadCount = [appDelegate unreadCount];
    [self.loadingIndicator stopAnimating];
    
//    NSLog(@"doNextUnreadStory: %d (out of %d)", nextLocation, unreadCount);
    
    if (nextLocation == -1 && unreadCount > 0 &&
        fdvc.feedPage < 100) {
        [self.loadingIndicator startAnimating];
        self.circularProgressView.hidden = YES;
        self.buttonNext.enabled = NO;
        // Fetch next page and see if it has the unreads.
        self.waitingForNextUnreadFromServer = YES;
        [fdvc fetchNextPage:nil];
    } else if (nextLocation == -1) {
        [appDelegate.navigationController
         popToViewController:[appDelegate.navigationController.viewControllers
                              objectAtIndex:0]
         animated:YES];
        [appDelegate hideStoryDetailView];
    } else {
        [self changePage:nextLocation];
    }
}

- (IBAction)doPreviousStory {
    [self.loadingIndicator stopAnimating];
    self.circularProgressView.hidden = NO;
    id previousStoryId = [appDelegate popReadStory];
    if (!previousStoryId || previousStoryId == [appDelegate.activeStory objectForKey:@"id"]) {
        [appDelegate.navigationController
         popToViewController:[appDelegate.navigationController.viewControllers
                              objectAtIndex:0]
         animated:YES];
        [appDelegate hideStoryDetailView];
    } else {
        int previousLocation = [appDelegate locationOfStoryId:previousStoryId];
        if (previousLocation == -1) {
            return [self doPreviousStory];
        }
//        [appDelegate setActiveStory:[[appDelegate activeFeedStories]
//                                     objectAtIndex:previousIndex]];
//        [appDelegate changeActiveFeedDetailRow];
//        
        [self changePage:previousLocation];
    }
}

#pragma mark -
#pragma mark WEPopoverControllerDelegate implementation

- (void)popoverControllerDidDismissPopover:(WEPopoverController *)thePopoverController {
	//Safe to release the popover here
	self.popoverController = nil;
}

- (BOOL)popoverControllerShouldDismissPopover:(WEPopoverController *)thePopoverController {
	//The popover is automatically dismissed if you click outside it, unless you return NO here
	return YES;
}


/**
 Thanks to Paul Solt for supplying these background images and container view properties
 */
- (WEPopoverContainerViewProperties *)improvedContainerViewProperties {
	
	WEPopoverContainerViewProperties *props = [WEPopoverContainerViewProperties alloc];
	NSString *bgImageName = nil;
	CGFloat bgMargin = 0.0;
	CGFloat bgCapSize = 0.0;
	CGFloat contentMargin = 5.0;
	
	bgImageName = @"popoverBg.png";
	
	// These constants are determined by the popoverBg.png image file and are image dependent
	bgMargin = 13; // margin width of 13 pixels on all sides popoverBg.png (62 pixels wide - 36 pixel background) / 2 == 26 / 2 == 13
	bgCapSize = 31; // ImageSize/2  == 62 / 2 == 31 pixels
	
	props.leftBgMargin = bgMargin;
	props.rightBgMargin = bgMargin;
	props.topBgMargin = bgMargin;
	props.bottomBgMargin = bgMargin;
	props.leftBgCapSize = bgCapSize;
	props.topBgCapSize = bgCapSize;
	props.bgImageName = bgImageName;
	props.leftContentMargin = contentMargin;
	props.rightContentMargin = contentMargin - 1; // Need to shift one pixel for border to look correct
	props.topContentMargin = contentMargin;
	props.bottomContentMargin = contentMargin;
	
	props.arrowMargin = 4.0;
	
	props.upArrowImageName = @"popoverArrowUp.png";
	props.downArrowImageName = @"popoverArrowDown.png";
	props.leftArrowImageName = @"popoverArrowLeft.png";
	props.rightArrowImageName = @"popoverArrowRight.png";
	return props;
}

@end
