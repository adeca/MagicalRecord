//
//  MagicalRecordTest.m
//  MagicalRecordRecipes
//
//  Created by Agustín de Cabrera on 18/06/2013.
//
//

#import <GHUnitIOS/GHUnit.h>
#import "Recipe.h"
#import "Ingredient.h"

#define B_SUFFIX @"B"
#define C_SUFFIX @"C"

@interface MagicalRecordTest : GHAsyncTestCase {
    NSManagedObjectContext *_threadContext;
    NSManagedObjectContext *_mainContext;
}
@end

@implementation MagicalRecordTest

- (BOOL)shouldRunOnMainThread {
    // By default NO, but if you have a UI test or test dependent on running on the main thread return YES.
    // Also an async test that calls back on the main thread, you'll probably want to return YES.
    return NO;
}

- (void)setUpClass {
    // Run at start of all tests in the class
}

- (void)tearDownClass {
    // Run at end of all tests in the class
}

- (void)setUp {
    [MagicalRecord setupAutoMigratingCoreDataStack];
    
    _mainContext = [NSManagedObjectContext MR_defaultContext];
    [self givenAThreadContext];
}

- (void)tearDown {
    [MagicalRecord clearPersistentStore];
    [MagicalRecord cleanUp];
}

#pragma mark -

- (void)testBgToMain {
    
    [self givenSomeRecipiesInBg];
    [self thenIHaveSomeRecipies];
}
- (void)testMainToBg {
    
    [self givenSomeRecipiesInMain];
    [self thenIHaveSomeRecipies];
}

- (void)testBgToMainChanges {
    
    [self givenSomeRecipiesInBg];
    [self thenIHaveSomeRecipies];
    
    [self whenIMakeChangesInContext:_threadContext suffix:B_SUFFIX];
    [self thenIHaveModificationsInContext:_threadContext suffix:B_SUFFIX];
    
    [self whenISaveTheContext:_threadContext];
    [self thenIHaveModificationsInContext:_mainContext suffix:B_SUFFIX];
}
- (void)testMainToBgChanges {
    
    [self givenSomeRecipiesInBg];
    [self thenIHaveSomeRecipies];
    
    [self whenIMakeChangesInMainContextWithSuffix:B_SUFFIX];
    [self thenIHaveModificationsInContext:_mainContext suffix:B_SUFFIX];

    [self whenISaveTheMainContext];
    [self thenIHaveModificationsInContext:_threadContext suffix:B_SUFFIX];
}
- (void)testMainAndBgChanges {
    
    [self givenSomeRecipiesInBg];
    [self thenIHaveSomeRecipies];
    
    [self whenIMakeChangesInContext:_threadContext suffix:C_SUFFIX];
    [self thenIHaveModificationsInContext:_threadContext suffix:C_SUFFIX];
    
    [self whenIMakeChangesInMainContextWithSuffix:B_SUFFIX];
    [self thenIHaveModificationsInContext:_mainContext suffix:B_SUFFIX];
    
    [self whenISaveTheMainContext];
    [self thenIHaveModificationsInContext:_threadContext suffix:B_SUFFIX];
}

#pragma mark -

- (void)givenAThreadContext {

    GHAssertFalse([NSThread isMainThread], @"expected background thread");
    
    _threadContext = [NSManagedObjectContext MR_contextForCurrentThread];
    GHAssertNotEqualObjects(_threadContext, [NSManagedObjectContext MR_defaultContext], @"expected child context");
    GHAssertEqualObjects(_threadContext.parentContext, [NSManagedObjectContext MR_defaultContext], @"expected child context");
}
- (void)givenCleanContexts {
    
    GHAssertEquals((int)[Recipe MR_countOfEntitiesWithContext:_threadContext], 0, @"expected no recipies");
    GHAssertEquals((int)[Ingredient MR_countOfEntitiesWithContext:_threadContext], 0, @"expected no ingredients");
    
    GHAssertEquals((int)[Recipe MR_countOfEntitiesWithContext:_mainContext], 0, @"expected no recipies");
    GHAssertEquals((int)[Ingredient MR_countOfEntitiesWithContext:_mainContext], 0, @"expected no ingredients");
}
- (void)givenSomeRecipiesInBg {
    
    [self givenSomeRecipiesInContext:_threadContext];
}
- (void)givenSomeRecipiesInMain {

    [self givenSomeRecipiesInContext:_mainContext];
}
- (void)givenSomeRecipiesInContext:(NSManagedObjectContext*)context {
    
    [self givenCleanContexts];
    
    Recipe *r1 = [Recipe MR_createInContext:context];
    r1.name = @"R1";
    
    Ingredient *i1 = [Ingredient MR_createInContext:context];
    i1.name = @"I1";
    i1.recipe = r1;
    
    [context MR_saveToPersistentStoreAndWait];
}

#pragma mark -

- (void)whenIMakeChangesInMainContextWithSuffix:(NSString*)suffix {
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self whenIMakeChangesInContext:_mainContext suffix:suffix];
    });
}
- (void)whenIMakeChangesInContext:(NSManagedObjectContext*)context suffix:(NSString*)suffix {
    
    Recipe *r1 = [Recipe MR_findFirstInContext:context];
    Ingredient *i1 = [Ingredient MR_findFirstInContext:context];
    
    r1.name = [@"R1_" stringByAppendingString:suffix];
    i1.name = [@"I1_" stringByAppendingString:suffix];
}
- (void)whenISaveTheMainContext {
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self whenISaveTheContext:_mainContext];
    });
}
- (void)whenISaveTheContext:(NSManagedObjectContext*)context {
    
    [context MR_saveToPersistentStoreAndWait];
}
- (void)whenIResetTheContext:(NSManagedObjectContext*)context {
    
    [context reset];
}

#pragma mark -

- (void)thenIHaveSomeRecipies {
    
    [self thenIHaveSomeRecipiesInContext:_threadContext];
    [self thenIHaveSomeRecipiesInContext:_mainContext];
}
- (void)thenIHaveSomeRecipiesInContext:(NSManagedObjectContext*)context {
    
    GHAssertEquals((int)[Recipe MR_countOfEntitiesWithContext:context], 1, @"expected 1 recipe");
    GHAssertEquals((int)[Ingredient MR_countOfEntitiesWithContext:context], 1, @"expected 1 ingredient");
    
    GHAssertEqualObjects([[Recipe MR_findFirstInContext:context] name], @"R1", @"");
    GHAssertEqualObjects([[Ingredient MR_findFirstInContext:context] name], @"I1", @"");
}
- (void)thenIHaveModificationsInContext:(NSManagedObjectContext*)context suffix:(NSString*)suffix {
    
    GHAssertEqualObjects([[Recipe MR_findFirstInContext:context] name], [@"R1_" stringByAppendingString:suffix], @"");
    GHAssertEqualObjects([[Ingredient MR_findFirstInContext:context] name], [@"I1_" stringByAppendingString:suffix], @"");
}


@end