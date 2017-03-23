/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionRequirementSourceListFlatTree.h"

#import "PKGDistributionRequirementSourceListGroupItem.h"
#import "PKGDistributionRequirementSourceListRequirementItem.h"

#import "PKGRequirementPluginsManager.h"
#import "PKGRequirementConverter.h"

#import "PKGRequirement+UI.h"

@interface PKGDistributionRequirementSourceListFlatTree ()
{
	PKGDistributionRequirementSourceListNode * _installationGroupNode;
	PKGDistributionRequirementSourceListNode * _targetGroupNode;
	
	NSMutableArray * _array;
}

@end

@implementation PKGDistributionRequirementSourceListFlatTree

- (instancetype)initWithRequirements:(NSMutableArray *)inRequirements
{
	self=[super init];
	
	if (self!=nil)
	{
		_array=[NSMutableArray array];
		
		_installationGroupNode=[[PKGDistributionRequirementSourceListNode alloc] initWithRepresentedObject:[[PKGDistributionRequirementSourceListGroupItem alloc] initWithGroupType:PKGRequirementTypeInstallation]];
		_targetGroupNode=[[PKGDistributionRequirementSourceListNode alloc] initWithRepresentedObject:[[PKGDistributionRequirementSourceListGroupItem alloc] initWithGroupType:PKGRequirementTypeTarget]];
		
		NSMutableArray * tInstallationNodes=[NSMutableArray array];
		NSMutableArray * tVolumeNodes=[NSMutableArray array];
		
		for(PKGRequirement * tRequirement in inRequirements)
		{
			PKGDistributionRequirementSourceListNode * tRequirementTreeNode=[[PKGDistributionRequirementSourceListNode alloc] initWithRepresentedObject:[[PKGDistributionRequirementSourceListRequirementItem alloc] initWithRequirement:tRequirement]];
			
			PKGDistributionRequirementSourceListNode * tGroupNode=nil;
			
			PKGRequirementType tRequirementType=tRequirement.requirementType;
			
			switch (tRequirementType)
			{
				case PKGRequirementTypeInstallation:
					
					tGroupNode=_installationGroupNode;
					
					[tInstallationNodes addObject:tRequirementTreeNode];
					
					break;
					
				case PKGRequirementTypeTarget:
					
					tGroupNode=_targetGroupNode;
					
					[tVolumeNodes addObject:tRequirementTreeNode];
					
					break;
					
				default:
					
					// A COMPLETER
					
					break;
			}
			
			tRequirementTreeNode.parent=tGroupNode;
		}
		
		if (tInstallationNodes.count>0)
		{
			[_array addObject:_installationGroupNode];
			[_array addObjectsFromArray:tInstallationNodes];
		}
		
		if (tVolumeNodes.count>0)
		{
			[_array addObject:_targetGroupNode];
			[_array addObjectsFromArray:tVolumeNodes];
		}
	}
	
	return self;
}

#pragma mark -

- (NSUInteger)count
{
	return _array.count;
}

- (NSUInteger)indexOfNode:(PKGDistributionRequirementSourceListNode *)inNode
{
	if (inNode==nil)
		return NSNotFound;
	
	return [_array indexOfObject:inNode];
}

- (PKGDistributionRequirementSourceListNode *)nodeAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=_array.count)
		return nil;
	
	return [_array objectAtIndex:inIndex];
}

- (NSArray *)nodesAtIndexes:(NSIndexSet *)inIndexes
{
	if (inIndexes==nil)
		return [NSArray array];
	
	return [_array objectsAtIndexes:inIndexes];
}

- (void)insertNodes:(NSArray *)inNodes atIndexes:(NSIndexSet *)inIndexes
{
	if (inNodes.count==0 || inIndexes==nil)
		return;
	
	[_array insertObjects:inNodes atIndexes:inIndexes];
		
}

- (void)removeNode:(PKGDistributionRequirementSourceListNode *)inNode
{
	[_array removeObject:inNode];
	
	if ([inNode isKindOfClass:PKGDistributionRequirementSourceListNode.class]==NO)
		return;
	
	if ([inNode.representedObject isKindOfClass:PKGDistributionRequirementSourceListGroupItem.class]==YES)
		return;
	
	PKGDistributionRequirementSourceListNode * tParentNode=inNode.parent;
	
	inNode.parent=nil;
	
	if (tParentNode.numberOfChildren==0)
		[_array removeObject:tParentNode];
}

- (void)removeNodesInArray:(NSArray *)inArray
{
	for(PKGDistributionRequirementSourceListNode * tNode in inArray)
		[self removeNode:tNode];
}

#pragma mark -

- (void)addRequirement:(PKGRequirement *)inRequirement
{
	if (inRequirement==nil)
		return;
	
	PKGRequirementType tRequirementType=inRequirement.requirementType;
	
	PKGDistributionRequirementSourceListNode * tGroupNode=(inRequirement.requirementType==PKGRequirementTypeInstallation) ? _installationGroupNode : _targetGroupNode;
	
	PKGDistributionRequirementSourceListNode * tNode=[[PKGDistributionRequirementSourceListNode alloc] initWithRepresentedObject:[[PKGDistributionRequirementSourceListRequirementItem alloc] initWithRequirement:inRequirement]];
	tNode.parent=tGroupNode;
	
	NSUInteger tGroupIndex=[_array indexOfObject:tGroupNode];
	
	if (tRequirementType==PKGRequirementTypeTarget)
	{
		if (tGroupIndex==NSNotFound)
			[_array addObject:_targetGroupNode];
		
		[_array addObject:tNode];
		
		return;
	}
	
	if (tGroupIndex==NSNotFound)
	{
		[_array insertObject:_installationGroupNode atIndex:0];
		[_array insertObject:tNode atIndex:1];
		
		return;
	}
		
	tGroupIndex=[_array indexOfObject:_targetGroupNode];
	
	if (tGroupIndex==NSNotFound)
		[_array addObject:tNode];
	else
		[_array insertObject:tNode atIndex:tGroupIndex];
}

- (PKGDistributionRequirementSourceListNode *)treeNodeForRequirement:(PKGRequirement *)inRequirement
{
	if (inRequirement==nil)
		return nil;
	
	for(PKGDistributionRequirementSourceListNode * tTreeNode in _array)
	{
		PKGDistributionRequirementSourceListItem * tItem=tTreeNode.representedObject;
		
		if ([tItem isKindOfClass:PKGDistributionRequirementSourceListGroupItem.class]==YES)
			continue;
		
		PKGDistributionRequirementSourceListRequirementItem * tRequirementItem=(PKGDistributionRequirementSourceListRequirementItem *)tItem;
				
		if (tRequirementItem.requirement==inRequirement)
			return tTreeNode;
	}
	
	return nil;
}

@end