// Tags Module - Merges default and custom tags
targetScope = 'resourceGroup'

@description('Default tags to apply')
param defaultTags object = {}

@description('Custom tags to merge with defaults')
param customTags object = {}

output tags object = union(defaultTags, customTags)
