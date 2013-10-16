//
//  UVWelcomeViewController.m
//  UserVoice
//
//  Created by UserVoice on 12/15/09.
//  Copyright 2009 UserVoice Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UVWelcomeViewController.h"
#import "UVStyleSheet.h"
#import "UVSession.h"
#import "UVForum.h"
#import "UVClientConfig.h"
#import "UVSubdomain.h"
#import "UVNewTicketViewController.h"
#import "UVSuggestionListViewController.h"
#import "UVSuggestion.h"
#import "UVArticle.h"
#import "UVSuggestionDetailsViewController.h"
#import "UVArticleViewController.h"
#import "UVHelpTopic.h"
#import "UVHelpTopicViewController.h"
#import "UVConfig.h"
#import "UVNewSuggestionViewController.h"
#import "UVGradientButton.h"
#import "UVBabayaga.h"
#import "UVUtils.h"

@implementation UVWelcomeViewController

@synthesize searchController;

- (BOOL)showArticles {
    return [UVSession currentSession].config.topicId || [[UVSession currentSession].topics count] == 0;
}

#pragma mark ===== table cells =====

- (void)initCellForContact:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.textLabel.text = NSLocalizedStringFromTable(@"Send us a message", @"UserVoice", nil);
    if (IOS7) {
        cell.textLabel.textColor = cell.textLabel.tintColor;
    }
}

- (void)initCellForForum:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.text = NSLocalizedStringFromTable(@"Feedback Forum", @"UserVoice", nil);
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSString *detail;
    if ([UVSession currentSession].forum.suggestionsCount == 1) {
        detail = NSLocalizedStringFromTable(@"2 idea", @"UserVoice", nil);
    } else {
        detail = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ ideas", @"UserVoice", nil), [UVUtils formatInteger:[UVSession currentSession].forum.suggestionsCount]];
    }
    cell.detailTextLabel.text = detail;
}

- (void)customizeCellForTopic:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
    if (indexPath.row == [[UVSession currentSession].topics count]) {
        cell.textLabel.text = NSLocalizedStringFromTable(@"All Articles", @"UserVoice", nil);
        cell.detailTextLabel.text = nil;
    } else {
        UVHelpTopic *topic = [[UVSession currentSession].topics objectAtIndex:indexPath.row];
        cell.textLabel.text = topic.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", topic.articleCount];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)customizeCellForArticle:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
    UVArticle *article = [[UVSession currentSession].articles objectAtIndex:indexPath.row];
    cell.textLabel.text = article.question;
    cell.imageView.image = [UIImage imageNamed:@"uv_article.png"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:13.0];
}

- (void)initCellForFlash:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.text = NSLocalizedStringFromTable(@"View idea", @"UserVoice", nil);
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)initCellForInstantAnswer:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    [super initCellForInstantAnswer:cell indexPath:indexPath];
    UIView *label = [cell viewWithTag:HIGHLIGHTING_LABEL_TAG];
    label.frame = CGRectMake(40, 12, cell.bounds.size.width - 80, 20);
}

- (void)customizeCellForInstantAnswer:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    [self customizeCellForInstantAnswer:cell index:indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
}

#pragma mark ===== UITableViewDataSource Methods =====

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"";
    if (theTableView == searchController.searchResultsTableView) {
        identifier = @"InstantAnswer";
    } else {
        if (indexPath.section == 0 && indexPath.row == 0 && [UVSession currentSession].config.showContactUs)
            identifier = @"Contact";
        else if (indexPath.section == 0)
            identifier = @"Forum";
        else if ([self showArticles])
            identifier = @"Article";
        else
            identifier = @"Topic";
    }

    return [self createCellForIdentifier:identifier tableView:theTableView indexPath:indexPath style:UITableViewCellStyleValue1 selectable:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView {
    if (theTableView == searchController.searchResultsTableView) {
        return 1;
    } else {
        int sections = 0;

        if ([UVSession currentSession].config.showKnowledgeBase && ([[UVSession currentSession].topics count] > 0 || [[UVSession currentSession].articles count] > 0))
            sections++;
        
        if ([UVSession currentSession].config.showForum || [UVSession currentSession].config.showContactUs)
            sections++;

        return sections;
    }
}

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section {
    if (theTableView == searchController.searchResultsTableView) {
        return [instantAnswers count];
    } else {
        if (section == 0 && ([UVSession currentSession].config.showForum || [UVSession currentSession].config.showContactUs))
            return ([UVSession currentSession].config.showForum && [UVSession currentSession].config.showContactUs) ? 2 : 1;
        else if ([self showArticles])
            return [[UVSession currentSession].articles count];
        else
            return [[UVSession currentSession].topics count] + 1;
    }
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [theTableView deselectRowAtIndexPath:indexPath animated:YES];
    if (theTableView == searchController.searchResultsTableView) {
        [self selectInstantAnswerAtIndex:indexPath.row];
    } else {
        if (indexPath.section == 0 && indexPath.row == 0 && [UVSession currentSession].config.showContactUs) {
            [self presentModalViewController:[UVNewTicketViewController viewController]];
        } else if (indexPath.section == 0 && [UVSession currentSession].config.showForum) {
            UVSuggestionListViewController *next = [[[UVSuggestionListViewController alloc] init] autorelease];
            [self.navigationController pushViewController:next animated:YES];
        } else if ([self showArticles]) {
            UVArticle *article = (UVArticle *)[[UVSession currentSession].articles objectAtIndex:indexPath.row];
            UVArticleViewController *next = [[[UVArticleViewController alloc] initWithArticle:article helpfulPrompt:nil returnMessage:nil] autorelease];
            [self.navigationController pushViewController:next animated:YES];
        } else {
            UVHelpTopic *topic = nil;
            if (indexPath.row < [[UVSession currentSession].topics count])
                topic = (UVHelpTopic *)[[UVSession currentSession].topics objectAtIndex:indexPath.row];
            UVHelpTopicViewController *next = [[[UVHelpTopicViewController alloc] initWithTopic:topic] autorelease];
            [self.navigationController pushViewController:next animated:YES];
        }
    }
}

- (NSString *)tableView:(UITableView *)theTableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0 && [UVSession currentSession].config.showForum)
        return nil;
    else if ([UVSession currentSession].config.topicId)
        return [((UVHelpTopic *)[[UVSession currentSession].topics objectAtIndex:0]) name];
    else
        return NSLocalizedStringFromTable(@"Knowledge Base", @"UserVoice", nil);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (void)logoTapped {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.uservoice.com/ios"]];
}

#pragma mark ===== UISearchBarDelegate Methods =====

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [searchController setActive:YES animated:YES];
    searchController.searchResultsTableView.tableFooterView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    searchController.searchResultsTableView.backgroundView = nil;
    searchController.searchResultsTableView.backgroundColor = [UIColor colorWithRed:0.94f green:0.95f blue:0.95f alpha:1.0f];
    searchController.searchResultsTableView.separatorColor = [UIColor colorWithRed:0.80f green:0.80f blue:0.80f alpha:1.0f];
    [searchBar setShowsCancelButton:YES animated:YES];
    filter = IA_FILTER_ALL;
    searchBar.showsScopeBar = YES;
    searchBar.selectedScopeButtonIndex = 0;
    return YES;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    controller.searchBar.showsScopeBar = NO;
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    self.filter = searchBar.selectedScopeButtonIndex;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.instantAnswersQuery = searchBar.text;
    [self loadInstantAnswers];
}

- (void)didLoadInstantAnswers {
    if (searchController.active)
        [searchController.searchResultsTableView reloadData];
}

- (int)maxInstantAnswerResults {
    return 10;
}

#pragma mark ===== Basic View Methods =====

- (void)loadView {
    [super loadView];
    [UVBabayaga track:VIEW_KB];
    self.navigationItem.title = NSLocalizedStringFromTable(@"Feedback & Support", @"UserVoice", nil);
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Close", @"UserVoice", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(dismissUserVoice)] autorelease];

    self.tableView = [[[UITableView alloc] initWithFrame:[self contentFrame] style:UITableViewStyleGrouped] autorelease];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view = self.tableView;

    if ([UVSession currentSession].config.showKnowledgeBase) {
        UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)] autorelease];
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        searchBar.placeholder = NSLocalizedStringFromTable(@"Search", @"UserVoice", nil);
        searchBar.delegate = self;
        searchBar.showsScopeBar = NO;
        if ([UVSession currentSession].config.showForum) {
            searchBar.scopeButtonTitles = @[NSLocalizedStringFromTable(@"All", @"UserVoice", nil), NSLocalizedStringFromTable(@"Articles", @"UserVoice", nil), NSLocalizedStringFromTable(@"Ideas", @"UserVoice", nil)];
        }
        self.tableView.tableHeaderView = searchBar;

        self.searchController = [[[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self] autorelease];
        searchController.delegate = self;
        searchController.searchResultsDelegate = self;
        searchController.searchResultsDataSource = self;
    }


    if (![UVSession currentSession].clientConfig.whiteLabel) {
        UIView *footer = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 50)] autorelease];
        footer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UIView *logo = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
        UILabel *poweredBy = [[[UILabel alloc] initWithFrame:CGRectMake(0, 6, 0, 0)] autorelease];
        // tweak for retina
        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0))
            poweredBy.frame = CGRectMake(0, 8, 0, 0);
        poweredBy.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        poweredBy.backgroundColor = [UIColor clearColor];
        poweredBy.textColor = [UIColor grayColor];
        poweredBy.font = [UIFont systemFontOfSize:11];
        poweredBy.text = NSLocalizedStringFromTable(@"powered by", @"UserVoice", nil);
        [poweredBy sizeToFit];
        [logo addSubview:poweredBy];
        UIImageView *image = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uv_logo.png"]] autorelease];
        image.frame = CGRectMake(poweredBy.bounds.size.width + 7, 0, image.bounds.size.width * 0.8, image.bounds.size.height * 0.8);
        [logo addSubview:image];
        logo.frame = CGRectMake(0, 0, image.frame.origin.x + image.frame.size.width, image.frame.size.height);
        logo.center = CGPointMake(footer.bounds.size.width / 2, footer.bounds.size.height - logo.bounds.size.height / 2 - 15);
        logo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
        [logo addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(logoTapped)] autorelease]];
        [footer addSubview:logo];
        tableView.tableFooterView = footer;
    }

    [tableView reloadData];
}

- (void)dealloc {
    self.searchController = nil;
    [super dealloc];
}

@end
