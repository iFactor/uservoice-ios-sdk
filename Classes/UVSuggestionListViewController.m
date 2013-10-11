//
//  UVSuggestionListViewController.m
//  UserVoice
//
//  Created by UserVoice on 10/22/09.
//  Copyright 2009 UserVoice Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UVSuggestionListViewController.h"
#import "UVClientConfig.h"
#import "UVSession.h"
#import "UVSuggestion.h"
#import "UVSuggestionDetailsViewController.h"
#import "UVNewSuggestionViewController.h"
#import "UVStyleSheet.h"
#import "UVUser.h"
#import "UVConfig.h"
#import "UVUtils.h"
#import "UVBabayaga.h"

#define SUGGESTIONS_PAGE_SIZE 10
#define UV_SEARCH_TEXTBAR 1
#define UV_SEARCH_RESULTS_TAG_CELL_ADD_PREFIX 100
#define UV_SEARCH_RESULTS_TAG_CELL_ADD_QUERY 101
#define UV_SEARCH_RESULTS_TAG_CELL_ADD_SUFFIX 102
#define UV_BASE_GROUPED_CELL_BG 103
#define UV_BASE_SUGGESTION_LIST_TAG_CELL_BACKGROUND 104
#define UV_SEARCH_TOOLBAR 1000
#define UV_SEARCH_TOOLBAR_LABEL 1001

#define TITLE 20
#define SUBSCRIBER_COUNT 21
#define STATUS 22
#define STATUS_COLOR 23

@implementation UVSuggestionListViewController {
    UITableViewCell *_templateCell;
}

@synthesize forum = _forum;
@synthesize suggestions;
@synthesize searchResults;
@synthesize searchController;
@synthesize searchPattern;

- (id)init {
    if ((self = [super init])) {
        self.forum = [UVSession currentSession].forum;
    }
    return self;
}

- (void)retrieveMoreSuggestions {
    NSInteger page = ([self.suggestions count] / SUGGESTIONS_PAGE_SIZE) + 1;
    [self showActivityIndicator];
    [UVSuggestion getWithForum:self.forum page:page delegate:self];
}

- (void)populateSuggestions {
    self.suggestions = [NSMutableArray arrayWithCapacity:10];
    _forum.suggestions = [NSMutableArray arrayWithCapacity:10];
    _forum.suggestionsNeedReload = NO;
    [self retrieveMoreSuggestions];
}

- (void)didRetrieveSuggestions:(NSArray *)theSuggestions {
    [self hideActivityIndicator];
    if ([theSuggestions count] > 0) {
        [self.suggestions addObjectsFromArray:theSuggestions];
    }

    [_forum.suggestions addObjectsFromArray:theSuggestions];
    [self.tableView reloadData];
}

- (void)didSearchSuggestions:(NSArray *)theSuggestions {
    self.searchResults = theSuggestions;
    NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[theSuggestions count]];
    for (UVSuggestion *suggestion in theSuggestions) {
        [ids addObject:[NSNumber numberWithInt:suggestion.suggestionId]];
    }
    [UVBabayaga track:SEARCH_IDEAS searchText:searchController.searchBar.text ids:ids];
    [searchController.searchResultsTableView reloadData];
}

- (void)updatePattern {
    self.searchPattern = [UVUtils patternForQuery:searchController.searchBar.text];
}

#pragma mark ===== UITableViewDataSource Methods =====

- (void)initCellForAdd:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.textLabel.text = NSLocalizedStringFromTable(@"Post an idea", @"UserVoice", nil);
    if (IOS7) {
        cell.textLabel.textColor = cell.textLabel.tintColor;
    }
}

- (void)initCellForSuggestion:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    UIImageView *heart = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uv_heart.png"]] autorelease];
    UILabel *subs = [[[UILabel alloc] init] autorelease];
    UILabel *title = [[[UILabel alloc] init] autorelease];
    UILabel *status = [[[UILabel alloc] init] autorelease];
    UIView *statusColor = [[[UIView alloc] init] autorelease];
    title.numberOfLines = 0;
    subs.tag = SUBSCRIBER_COUNT;
    title.tag = TITLE;
    status.tag = STATUS;
    statusColor.tag = STATUS_COLOR;
    subs.translatesAutoresizingMaskIntoConstraints = NO;
    heart.translatesAutoresizingMaskIntoConstraints = NO;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    status.translatesAutoresizingMaskIntoConstraints = NO;
    statusColor.translatesAutoresizingMaskIntoConstraints = NO;
    subs.font = [UIFont systemFontOfSize:14];
    subs.textColor = [UIColor grayColor];
    status.font = [UIFont systemFontOfSize:11];
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, 9, 9);
    [statusColor.layer addSublayer:layer];
    [cell.contentView addSubview:heart];
    [cell.contentView addSubview:subs];
    [cell.contentView addSubview:title];
    [cell.contentView addSubview:statusColor];
    [cell.contentView addSubview:status];
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(subs, title, heart, statusColor, status);
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[title]-|" options:0 metrics:nil views:viewsDictionary]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[heart(==9)]-3-[subs]-10-[statusColor(==9)]-5-[status]" options:0 metrics:nil views:viewsDictionary]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[title]-6-[heart(==9)]" options:0 metrics:nil views:viewsDictionary]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[title]-6-[statusColor(==9)]" options:0 metrics:nil views:viewsDictionary]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[title]-4-[status]" options:0 metrics:nil views:viewsDictionary]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[title]-2-[subs]" options:0 metrics:nil views:viewsDictionary]];

    // template cell
    if (indexPath == nil) {
        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[heart]-10-|" options:0 metrics:nil views:viewsDictionary]];
    }
}

- (void)customizeCellForSuggestion:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UVSuggestion *suggestion = [suggestions objectAtIndex:indexPath.row];
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:TITLE];
    UILabel *subs = (UILabel *)[cell.contentView viewWithTag:SUBSCRIBER_COUNT];
    UILabel *status = (UILabel *)[cell.contentView viewWithTag:STATUS];
    UIView *statusColor = [cell.contentView viewWithTag:STATUS_COLOR];

    title.text = suggestion.title;
    subs.text = [NSString stringWithFormat:@"%d", suggestion.subscriberCount];
    [statusColor.layer.sublayers.lastObject setBackgroundColor:[suggestion.statusColor CGColor]];
    status.textColor = suggestion.statusColor;
    status.text = [suggestion.status uppercaseString];
}

- (void)initCellForLoad:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.backgroundView = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
    UILabel *label = [[[UILabel alloc] initWithFrame:cell.frame] autorelease];
    label.text = NSLocalizedStringFromTable(@"Load more", @"UserVoice", nil);
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:16];
    label.textAlignment = UITextAlignmentCenter;
    [cell addSubview:label];
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier;
    BOOL selectable = YES;
    UITableViewCellStyle style = UITableViewCellStyleDefault;
    identifier = (indexPath.section == 0 && [UVSession currentSession].config.showPostIdea) ? @"Add" : (indexPath.row < [suggestions count]) ? @"Suggestion" : @"Load";
    return [self createCellForIdentifier:identifier
                               tableView:theTableView
                               indexPath:indexPath
                                   style:style
                              selectable:selectable];
}

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && [UVSession currentSession].config.showPostIdea) {
        return 1;
    } else if (theTableView == tableView) {
        int loadedCount = [self.suggestions count];
        int suggestionsCount = _forum.suggestionsCount;
        return loadedCount + (loadedCount >= suggestionsCount || suggestionsCount < SUGGESTIONS_PAGE_SIZE ? 0 : 1);
    } else {
        return [searchResults count] + ([UVSession currentSession].config.showPostIdea ? 1 : 0);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [UVSession currentSession].config.showPostIdea ? 2 : 1;
}

#pragma mark ===== UITableViewDelegate Methods =====

- (CGFloat)tableView:(UITableView *)theTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && [UVSession currentSession].config.showPostIdea) {
        return 44;
    } else if (theTableView != tableView || indexPath.row < [suggestions count]) {
        return [self heightForDynamicRowWithReuseIdentifier:@"Suggestion" indexPath:indexPath];
    } else {
        return 44;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0 && [UVSession currentSession].config.showPostIdea) {
        return nil;
    } else {
        return self.forum.prompt;
    }
}

- (void)showSuggestion:(UVSuggestion *)suggestion {
    UVSuggestionDetailsViewController *next = [[[UVSuggestionDetailsViewController alloc] initWithSuggestion:suggestion] autorelease];
    [self.navigationController pushViewController:next animated:YES];
}

- (void)composeButtonTapped {
    [self presentModalViewController:[UVNewSuggestionViewController viewControllerWithTitle:self.searchController.searchBar.text]];
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [theTableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && [UVSession currentSession].config.showPostIdea) {
        [self composeButtonTapped];
    } else if (theTableView == tableView) {
        if (indexPath.row < [suggestions count])
            [self showSuggestion:[suggestions objectAtIndex:indexPath.row]];
        else
            [self retrieveMoreSuggestions];
    } else {
        [self showSuggestion:[searchResults objectAtIndex:indexPath.row]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

#pragma mark ===== UISearchBarDelegate Methods =====

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [searchController setActive:YES animated:YES];
    [searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self updatePattern];
    [UVSuggestion searchWithForum:self.forum query:searchBar.text delegate:self];
}

#pragma mark ===== Basic View Methods =====

- (void)loadView {
    [super loadView];

    [UVBabayaga track:VIEW_FORUM id:_forum.forumId];

    self.view = [[[UIView alloc] initWithFrame:[self contentFrame]] autorelease];
    self.view.autoresizesSubviews = YES;
    CGFloat screenWidth = [UVClientConfig getScreenWidth];

    UITableView *theTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    theTableView.dataSource = self;
    theTableView.delegate = self;
    theTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

    UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 44)] autorelease];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    searchBar.placeholder = [NSString stringWithFormat:@"%@ %@", NSLocalizedStringFromTable(@"Search", @"UserVoice", nil), _forum.name];
    searchBar.delegate = self;

    self.searchController = [[[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self] autorelease];
    searchController.delegate = self;
    searchController.searchResultsDataSource = self;
    searchController.searchResultsDelegate = self;
    theTableView.tableHeaderView = searchBar;

    self.tableView = theTableView;
    [theTableView release];
    [self.view addSubview:tableView];


    if ([UVSession currentSession].config.showPostIdea) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                                target:self
                                                                                                action:@selector(composeButtonTapped)] autorelease];
        if ([self.navigationItem.rightBarButtonItem respondsToSelector:@selector(setTintColor:)])
            self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.24f green:0.51f blue:0.95f alpha:1.0f];
    }

    if ([UVSession currentSession].isModal && firstController) {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Close", @"UserVoice", nil)
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(dismissUserVoice)] autorelease];
    }
}

- (void)initNavigationItem {
    self.navigationItem.title = self.forum.name;
    self.exitButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Cancel", @"UserVoice", nil)
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(dismissUserVoice)] autorelease];
    if ([UVSession currentSession].isModal && firstController) {
        self.navigationItem.leftBarButtonItem = exitButton;
    }
}

- (void)reloadTableData {
    self.suggestions = _forum.suggestions;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (_forum) {
        if (_forum.suggestionsNeedReload) {
            self.suggestions = nil;
        }

        if (!self.suggestions) {
            [self populateSuggestions];
        }
    }
    [self.tableView reloadData];
}

- (void)dealloc {
    self.forum = nil;
    self.suggestions = nil;
    self.searchResults = nil;
    self.searchController = nil;
    self.searchPattern = nil;
    [_templateCell release];
    _templateCell = nil;
    [super dealloc];
}

@end
