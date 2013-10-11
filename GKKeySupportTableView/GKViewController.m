//
//  GKViewController.m
//  GKKeySupportTableView
//
//  Created by georgkitz on 10/10/13.
//  Copyright (c) 2013 Aurora Apps. All rights reserved.
//

#import "GKViewController.h"
#import "UITableView+GKKeyNavigationSupport.h"

static NSString *const kCellIdentifier = @"cell.identifier";

@interface GKViewController ()

@end

@implementation GKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.gk_addKeyboardSupport = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.tableView.gk_addKeyboardSupport = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark -
# pragma mark UITableViewDelegate & Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    cell.textLabel.text = [NSString stringWithFormat:@"%d", indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *message = [NSString stringWithFormat:@"Tapped row %d", indexPath.row];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:Nil message:message delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles: nil];
    
    [alert show];
}

@end
