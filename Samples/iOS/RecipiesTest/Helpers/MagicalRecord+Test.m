//
//  MagicalRecord+Test.m
//  MagicalRecordRecipes
//
//  Created by Agustín de Cabrera on 18/06/2013.
//
//

#import "MagicalRecord+Test.h"

@implementation MagicalRecord (Test)

+ (void)clearPersistentStore
{
    NSPersistentStore *store = [NSPersistentStore MR_defaultPersistentStore];
    
    NSError *error;
    if (![[NSFileManager defaultManager] removeItemAtURL:store.URL error:&error]) {
        NSLog(@"error: %@", error);
    }
}

@end
