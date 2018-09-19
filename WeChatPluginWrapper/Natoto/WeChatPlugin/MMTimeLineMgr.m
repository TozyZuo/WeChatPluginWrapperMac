//
//  MMTimeLineMgr.m
//  WeChatPlugin
//
//  Created by nato on 2017/1/22.
//  Copyright © 2017年 github:natoto. All rights reserved.
//

#import "MMTimeLineMgr.h"
#import "NSObject+ObjectMap.h"
#import <dlfcn.h>


@interface MMTimeLineMgr () <MMCGIDelegate>
{
    void *_dylibHandler;
}
@property (nonatomic, assign, getter=isRequesting) BOOL requesting;
@property (nonatomic, strong) NSString *firstPageMd5;
@property (nonatomic, strong) SKBuiltinBuffer_t *session;
@property (nonatomic, strong) NSMutableArray *statuses;

@end

@implementation MMTimeLineMgr

- (void)dealloc
{
    dlclose(_dylibHandler);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSLog(@"\n===Start===\n");
        NSString * dylibName = @"libWC";
        NSString * path = [[NSBundle pluginBundle] pathForResource:dylibName ofType:@"dylib"];
        _dylibHandler = dlopen(path.UTF8String, RTLD_NOW);
        if (!_dylibHandler){
            NSLog(@"dlopen failed ，error %s", dlerror());
            return nil;
        };
    }
    return self;
}

#pragma mark - Network

- (void)updateTimeLineHead {
    [self requestTimeLineDataAfterItemID:0];
}

- (void)updateTimeLineTail {
    MMStatus *status = [self.statuses lastObject];
    [self requestTimeLineDataAfterItemID:status.statusId];
}

- (void)requestTimeLineDataAfterItemID:(unsigned long long)itemID {
    if (self.isRequesting) {
        return;
    }
    self.requesting = true;
    SnsTimeLineRequest *request = [[CBGetClass(SnsTimeLineRequest) alloc] init];
    request.baseRequest = [CBGetClass(MMCGIRequestUtil) InitBaseRequestWithScene:0];
    request.clientLatestId = 0;
    request.firstPageMd5 = itemID == 0 ? self.firstPageMd5 : @"";
    request.lastRequestTime = 0;
    request.maxId = itemID;
    request.minFilterId = 0;
    request.session = self.session;
    MMCGIWrap *cgiWrap = [[CBGetClass(MMCGIWrap) alloc] init];
    cgiWrap.m_requestPb = request;
//    cgiWrap.m_responsePb = [[CBGetClass(SnsTimeLineResponse) alloc] init];
    cgiWrap.m_functionId = kMMCGIWrapTimeLineFunctionId;
    
    MMCGIService *cgiService = [[CBGetClass(MMServiceCenter) defaultCenter] getService:CBGetClass(MMCGIService)];
    [cgiService RequestCGI:cgiWrap delegate:self];
    
}

- (NSMutableArray *)jsonlist {
    if (!_jsonlist) {
        _jsonlist = [[NSMutableArray alloc] init];
    }
    return _jsonlist;
}
#pragma mark - MMCGIDelegate

- (void)OnResponseCGI:(BOOL)arg1 sessionId:(unsigned int)arg2 cgiWrap:(MMCGIWrap *)cgiWrap {
    NSLog(@"%d %d %@", arg1, arg2, cgiWrap);
    SnsTimeLineRequest *request = (SnsTimeLineRequest *)cgiWrap.m_requestPb;
    SnsTimeLineResponse *response = (SnsTimeLineResponse *)cgiWrap.m_responsePb;
 
    self.session = response.session;
    NSMutableArray *statuses = [NSMutableArray new];
    NSString * jsonstr = @"";
    for (SnsObject *snsObject in response.objectList) {
        MMStatus *status = [MMStatus new];
        [status updateWithSnsObject:snsObject];
        [statuses addObject:status];
        
        MMStatusSimple *st = [MMStatusSimple new];
        [st updateWithSnsObject:snsObject];
        NSString * stajson = [st JSONString];
        jsonstr = [jsonstr stringByAppendingFormat:@"%@,",stajson];
    }
    jsonstr = [jsonstr stringByAppendingFormat:@""];
    NSLog(@"\n\njson:\n%@\n\n",jsonstr);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isRefresh = request.maxId == 0;
        if (isRefresh) {
            self.firstPageMd5 = response.firstPageMd5;
            if (statuses.count) {
                self.statuses = statuses;
            }
            self.jsonlist = [@[jsonstr] mutableCopy];
        }
        else {
            [self.statuses addObjectsFromArray:statuses];
            [self.jsonlist addObject:jsonstr];
        }
        self.requesting = false;
        if (self.delegate && [self.delegate respondsToSelector:@selector(onTimeLineStatusChange)]) {
            [self.delegate onTimeLineStatusChange];
        }
    });
}

#pragma mark - 

- (NSUInteger)getTimeLineStatusCount {
    return [self.statuses count];
}

- (MMStatus *)getTimeLineStatusAtIndex:(NSUInteger)index {
    if (index >= self.statuses.count) {
        return nil;
    }
    else {
        return self.statuses[index];
    }
}

@end

/*
@interface PBCodedOutputStream : NSObject
{
    NSMutableData *buffer;
    char *bufferPointer;
    int position;
}

+ (id)streamWithData:(id)arg1;
@property int position; // @synthesize position;
@property(retain) NSMutableData *buffer; // @synthesize buffer;
- (void)writeRawLittleEndian64:(long long)arg1;
- (void)writeRawLittleEndian32:(int)arg1;
- (void)writeRawVarint64:(long long)arg1;
- (void)writeRawVarint32:(int)arg1;
- (void)writeTag:(int)arg1 format:(int)arg2;
- (void)writeRawData:(id)arg1 offset:(int)arg2 length:(int)arg3;
- (void)writeRawData:(id)arg1;
- (void)writeRawByte:(unsigned char)arg1;
- (void)checkNoSpaceLeft;
- (int)spaceLeft;
- (void)writeSInt64:(int)arg1 value:(long long)arg2;
- (void)writeSInt64NoTag:(long long)arg1;
- (void)writeSInt32:(int)arg1 value:(int)arg2;
- (void)writeSInt32NoTag:(int)arg1;
- (void)writeSFixed64:(int)arg1 value:(long long)arg2;
- (void)writeSFixed64NoTag:(long long)arg1;
- (void)writeSFixed32:(int)arg1 value:(int)arg2;
- (void)writeSFixed32NoTag:(int)arg1;
- (void)writeEnum:(int)arg1 value:(int)arg2;
- (void)writeEnumNoTag:(int)arg1;
- (void)writeUInt32:(int)arg1 value:(int)arg2;
- (void)writeUInt32NoTag:(int)arg1;
- (void)writeData:(int)arg1 value:(id)arg2;
- (void)writeDataNoTag:(id)arg1;
- (void)writeMessage:(int)arg1 value:(id)arg2;
- (void)writeMessageNoTag:(id)arg1;
- (void)writeString:(int)arg1 value:(id)arg2;
- (void)writeStringNoTag:(id)arg1 withSize:(unsigned long long)arg2;
- (void)writeStringNoTag:(id)arg1;
- (void)writeBool:(int)arg1 value:(BOOL)arg2;
- (void)writeBoolNoTag:(BOOL)arg1;
- (void)writeFixed32:(int)arg1 value:(int)arg2;
- (void)writeFixed32NoTag:(int)arg1;
- (void)writeFixed64:(int)arg1 value:(long long)arg2;
- (void)writeFixed64NoTag:(long long)arg1;
- (void)writeInt32:(int)arg1 value:(int)arg2;
- (void)writeInt32NoTag:(int)arg1;
- (void)writeInt64:(int)arg1 value:(long long)arg2;
- (void)writeInt64NoTag:(long long)arg1;
- (void)writeUInt64:(int)arg1 value:(long long)arg2;
- (void)writeUInt64NoTag:(long long)arg1;
- (void)writeFloat:(int)arg1 value:(float)arg2;
- (void)writeFloatNoTag:(float)arg1;
- (void)writeDouble:(int)arg1 value:(double)arg2;
- (void)writeDoubleNoTag:(double)arg1;
- (id)initWithOutputData:(id)arg1;
- (void)dealloc;

@end

int (*_computeMessageSize_)(int arg0, id arg1);
int (*_computeStringSize_)(int arg0, id arg1);
int (*_computeUInt64Size_)(int arg0, int arg1);
int (*_computeUInt32Size_)(int arg0, int arg1);

int wcp_computeMessageSize(int arg0, id arg1) {
    id r14 = arg1;
    int rbx = arg0 << 0x3;
    int r15 = 0x1;
    if (rbx >= 0x80) {
        r15 = 0x2;
        if (rbx >= 0x4000) {
            r15 = 0x3;
            if (rbx >= 0x200000) {
                r15 = (rbx > 0xfffffff ? 0x1 : 0x0) & 0xff | 0x4;
            }
        }
    }
    rbx = [r14 serializedSize];
    int rax = 0x1;
    if (rbx >= 0x80) {
        rax = 0x2;
        if (rbx >= 0x4000) {
            rax = 0x3;
            if (rbx >= 0x200000) {
                rax = (rbx > 0xfffffff ? 0x1 : 0x0) & 0xff | 0x4;
            }
        }
    }
    return rax + rbx + r15;
}

int wcp_computeStringSize(int arg0, id arg1) {
    id r14 = arg1;
    int rbx = arg0 << 0x3;
    int r15 = 0x1;
    if (rbx >= 0x80) {
        r15 = 0x2;
        if (rbx >= 0x4000) {
            r15 = 0x3;
            if (rbx >= 0x200000) {
                r15 = (rbx > 0xfffffff ? 0x1 : 0x0) & 0xff | 0x4;
            }
        }
    }
    int rax = (int)[r14 lengthOfBytesUsingEncoding:0x4];
    rbx = 0x1;
    if (rax >= 0x80) {
        rbx = 0x2;
        if (rax >= 0x4000) {
            rbx = 0x3;
            if (rax >= 0x200000) {
                rbx = (rax > 0xfffffff ? 0x1 : 0x0) & 0xff | 0x4;
            }
        }
    }
    return r15 + rbx + rax;
}

int _computeRawVarint64Size(int arg0) {
    int rdi = arg0;
    int rax = 0x1;
    if (rdi >= 0x80) {
        rax = 0x2;
        if (rdi >= 0x4000) {
            rax = 0x3;
            if (rdi >= 0x200000) {
                rax = 0x4;
                if (rdi >= 0x10000000) {
                    rax = rdi >> 0x23;
                    bool COND = rax == 0x0;
                    rax = 0x5;
                    if (!COND) {
                        rax = rdi >> 0x2a;
                        COND = rax == 0x0;
                        rax = 0x6;
                        if (!COND) {
                            rax = rdi >> 0x31;
                            COND = rax == 0x0;
                            rax = 0x7;
                            if (!COND) {
                                rax = rdi >> 0x38;
                                COND = rax == 0x0;
                                rax = 0x8;
                                if (!COND) {
                                    rax = (rdi >> 0x3f) + 0x9;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return rax;
}

int wcp_computeUInt64Size(int arg0, int arg1) {
    int rsi = arg1;
    int rdi = arg0 << 0x3;
    int rbx = 0x1;
    if (rdi >= 0x80) {
        rbx = 0x2;
        if (rdi >= 0x4000) {
            rbx = 0x3;
            if (rdi >= 0x200000) {
                rbx = (rdi > 0xfffffff ? 0x1 : 0x0) & 0xff | 0x4;
            }
        }
    }
    return _computeRawVarint64Size(rsi) + rbx;
}
int wcp_computeUInt32Size(int arg0, int arg1) {
    int rsi = arg1;
    int rdi = arg0 << 0x3;
    int rax = 0x1;
    int rcx = 0x1;
    if (rdi >= 0x80) {
        rcx = 0x2;
        if (rdi >= 0x4000) {
            rcx = 0x3;
            if (rdi >= 0x200000) {
                rcx = (rdi > 0xfffffff ? 0x1 : 0x0) & 0xff | 0x4;
            }
        }
    }
    if (rsi >= 0x80) {
        rax = 0x2;
        if (rsi >= 0x4000) {
            rax = 0x3;
            if (rsi >= 0x200000) {
                rax = (rsi > 0xfffffff ? 0x1 : 0x0) & 0xff | 0x4;
            }
        }
    }
    rax = rax + rcx;
    return rax;
}


static void __attribute__((constructor)) initialize(void) {
    NSLog(@"++++++++ Natoto_manager loaded ++++++++");


}

@implementation SnsTimeLineRequest

+ (void)load
{
    class_setSuperclass(self, objc_getClass("PBGeneratedMessage"));
}

- (int)serializedSize;
{
    int ret = 0;
    ret = wcp_computeMessageSize(0x1, [self baseRequest]);
    ret = ret + wcp_computeStringSize(0x2, [self firstPageMd5]);
    ret = ret + wcp_computeUInt64Size(0x3, [self maxId]);
    ret = ret + wcp_computeUInt64Size(0x4, [self minFilterId]);
    ret = ret + wcp_computeUInt32Size(0x5, [self lastRequestTime]);
    ret = ret + wcp_computeUInt64Size(0x6, [self clientLatestId]);
    ret = ret + wcp_computeMessageSize(0x7, [self session]);

    return ret;
}

- (void)writeToCodedOutputStream:(PBCodedOutputStream *)arg1;
{
    [arg1 writeMessage:0x1 value:[self baseRequest]];
    [arg1 writeString:0x2 value:[self firstPageMd5]];
    [arg1 writeUInt64:0x3 value:[self maxId]];
    [arg1 writeUInt64:0x4 value:[self minFilterId]];
    [arg1 writeUInt32:0x5 value:[self lastRequestTime]];
    [arg1 writeUInt64:0x6 value:[self clientLatestId]];
    [arg1 writeMessage:0x7 value:[self session]];

#if 0
    if ([self hasBaseRequest] != 0x0) {
        [arg1 writeMessage:0x1 value:[self baseRequest]];
    }
    if ([self hasFirstPageMd5] != 0x0) {
        [arg1 writeString:0x2 value:[self firstPageMd5]];
    }
    if ([self hasMaxId] != 0x0) {
        [arg1 writeUInt64:0x3 value:[self maxId]];
    }
    if ([self hasMinFilterId] != 0x0) {
        [arg1 writeUInt64:0x4 value:[self minFilterId]];
    }
    if ([self hasLastRequestTime] != 0x0) {
        [arg1 writeUInt32:0x5 value:[self lastRequestTime]];
    }
    if ([self hasClientLatestId] != 0x0) {
        [arg1 writeUInt64:0x6 value:[self clientLatestId]];
    }
    if ([self hasSession] != 0x0) {
        [arg1 writeMessage:0x7 value:[self session]];
    }
#endif
}

#if 0

+ (id)parseFromData:(id)arg1
{
    return [[[SnsTimeLineRequest alloc] init] mergeFromData:arg1];
}

- (BOOL)isInitialized;
{

}

- (id)mergeFromCodedInputStream:(id)arg1;
{

}

- (BOOL)hasBaseRequest
{
    return self.baseRequest ? YES : NO;
}

- (BOOL)hasSession
{

}

- (BOOL)hasClientLatestId
{

}

- (BOOL)hasLastRequestTime
{

}

- (BOOL)hasMinFilterId
{

}

- (BOOL)hasMaxId
{

}

- (BOOL)hasFirstPageMd5
{

}

#endif

@end


@interface PBCodedInputStream : NSObject
{
    NSData *buffer;
    char *bufferPointer;
    int bufferSize;
    int bufferSizeAfterLimit;
    int bufferPos;
    int lastTag;
    int totalBytesRetired;
    int currentLimit;
    int recursionDepth;
    int recursionLimit;
    int sizeLimit;
}

+ (id)streamWithData:(id)arg1;
@property(retain) NSData *buffer; // @synthesize buffer;
- (void)skipRawData:(int)arg1;
- (id)readRawData:(int)arg1;
- (BOOL)readRawByte;
- (BOOL)isAtEnd;
- (int)bytesUntilLimit;
- (void)popLimit:(int)arg1;
- (void)recomputeBufferSizeAfterLimit;
- (int)pushLimit:(int)arg1;
- (int)setSizeLimit:(int)arg1;
- (long long)readRawLittleEndian64;
- (int)readRawLittleEndian32;
- (long long)readRawVarint64;
- (int)readRawVarint32;
- (long long)readSInt64;
- (int)readSInt32;
- (long long)readSFixed64;
- (int)readSFixed32;
- (int)readEnum;
- (int)readUInt32;
- (id)readData;
- (void)readMessage:(id)arg1;
- (id)readString;
- (BOOL)readBool;
- (int)readFixed32;
- (long long)readFixed64;
- (int)readInt32;
- (long long)readInt64;
- (long long)readUInt64;
- (float)readFloat;
- (double)readDouble;
- (void)skipMessage;
- (BOOL)skipField:(int)arg1;
- (BOOL)isLastTag:(int)arg1;
- (void)checkLastTagWas:(int)arg1;
- (int)readTag;
- (id)initWithData:(id)arg1;
- (void)commonInit;
- (void)dealloc;

@end

@implementation SnsTimeLineResponse

+ (void)load
{
    class_setSuperclass(self, objc_getClass("PBGeneratedMessage"));
}

+ (id)parseFromData:(id)arg1
{
    id response = [[objc_getClass("SnsTimeLineResponse") alloc] init];
    [response mergeFromData:arg1];
    return response;
}

- (id)mergeFromCodedInputStream:(PBCodedInputStream *)arg1;
{
    while (![arg1 isAtEnd]) {
        int readTag = [arg1 readTag];
        if (readTag <= 0x2f) {
            if (readTag <= 0x17) {
                if (readTag == 0xa) {
                    BaseResponse *response = [[objc_getClass("BaseResponse") alloc] init];
                    [arg1 readMessage:response];
                    [self SetBaseResponse:response];
                }
                else if (readTag == 0x12)
                {
                    self.firstPageMd5 = [arg1 readString];
                }
                else if (![arg1 skipField:readTag]) {
                    break;
                }
            } else {
                if (readTag == 0x18)
                {
                    self.objectCount = [arg1 readUInt32];
                }
                else if (readTag == 0x22)
                {
                    SnsObject *obj = [[objc_getClass("SnsObject") alloc] init];
                    [arg1 readMessage:obj];
                    [self addObjectList:obj];
                }
                else if (readTag == 0x28)
                {
                    self.newRequestTime = [arg1 readUInt32];
                }
                else if (![arg1 skipField:readTag]) {
                    break;
                }
            }
        }
        else if (readTag > 0x47)
        {
            if (readTag == 0x48)
            {
                [self SetAdvertiseCount:[arg1 readUInt32]];
            }
            else if (readTag == 0x52)
            {

            }
            else if (readTag == 0x5a)
            {
                SKBuiltinBuffer_t *bb = [[objc_getClass("SKBuiltinBuffer_t") alloc] init];
                [arg1 readMessage:bb];
                [self SetSession:bb];
            }
            else if (![arg1 skipField:readTag]) {
                break;
            }
        }
        else if(readTag == 0x30)
        {
            [self SetObjectCountForSameMd5:[arg1 readUInt32]];
        }
        else if(readTag == 0x38)
        {
            [self SetControlFlag:[arg1 readUInt32]];
        }
        else if(readTag != 0x42)
        {
            SnsServerConfig *config = [[objc_getClass("SnsServerConfig") alloc] init];
            [arg1 readMessage:config];
            [self SetServerConfig:config];
        }
        else if ([arg1 skipField:readTag]) {
            break;
        }
    }
    return self;
}

- (void)addObjectList:(SnsObject *)arg1
{
    if (!self.objectList) {
        self.objectList = [[NSMutableArray alloc] init];
    }
    [self.objectList addObject:arg1];
}

@end

@implementation SnsServerConfig

+ (void)load
{
    class_setSuperclass(self, objc_getClass("PBGeneratedMessage"));
}

- (id)mergeFromCodedInputStream:(PBCodedInputStream *)arg1;
{

    while (![arg1 isAtEnd]) {
        int readTag = [arg1 readTag];
        if (readTag == 0x8)
        {
            [self SetPostMentionLimit:[arg1 readInt32]];
        }
        else if (readTag == 0x10)
        {
            [self SetCopyAndPasteWordLimit:[arg1 readInt32]];
        }
    }
    return self;
}

@end


@implementation NSObject (MMCGIService__)

+ (void)load
{
    CBHookInstanceMethod(MMCGIService, @selector(ParseResponseData:buffer:servIdBuf:), @selector(_ParseResponseData:buffer:servIdBuf:));
}

- (int)_ParseResponseData:(unsigned int)arg1 buffer:(const struct AutoBuffer *)arg2 servIdBuf:(struct AutoBuffer *)arg3
{
    return [self _ParseResponseData:arg1 buffer:arg2 servIdBuf:arg3];
}
@end
*/
