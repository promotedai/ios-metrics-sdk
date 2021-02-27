// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: proto/promotion/promotion.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/GPBProtocolBuffers.h>
#else
 #import "GPBProtocolBuffers.h"
#endif

#if GOOGLE_PROTOBUF_OBJC_VERSION < 30004
#error This file was generated by a newer version of protoc which is incompatible with your Protocol Buffer library sources.
#endif
#if 30004 < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION
#error This file was generated by an older version of protoc which is incompatible with your Protocol Buffer library sources.
#endif

// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

CF_EXTERN_C_BEGIN

@class PROAccount;
@class PROContent;
@class PROEntityPath;
@class PROFlatPromotion;
@class PROPromotion;
GPB_ENUM_FWD_DECLARE(PROCurrencyCode);

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enum PROStatus

typedef GPB_ENUM(PROStatus) {
  /**
   * Value used if any message's field encounters a value that is not defined
   * by this enum. The message will also have C functions to get/set the rawValue
   * of the field.
   **/
  PROStatus_GPBUnrecognizedEnumeratorValue = kGPBUnrecognizedEnumeratorValue,
  PROStatus_UnknownStatus = 0,
  PROStatus_Active = 1,
  PROStatus_Paused = 2,
  PROStatus_Archived = 3,
};

GPBEnumDescriptor *PROStatus_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL PROStatus_IsValidValue(int32_t value);

#pragma mark - Enum PROBidType

typedef GPB_ENUM(PROBidType) {
  /**
   * Value used if any message's field encounters a value that is not defined
   * by this enum. The message will also have C functions to get/set the rawValue
   * of the field.
   **/
  PROBidType_GPBUnrecognizedEnumeratorValue = kGPBUnrecognizedEnumeratorValue,
  PROBidType_UnknownBidType = 0,
  PROBidType_Cpm = 1,
  PROBidType_Cpc = 2,
};

GPBEnumDescriptor *PROBidType_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL PROBidType_IsValidValue(int32_t value);

#pragma mark - PROPromotionRoot

/**
 * Exposes the extension registry for this file.
 *
 * The base class provides:
 * @code
 *   + (GPBExtensionRegistry *)extensionRegistry;
 * @endcode
 * which is a @c GPBExtensionRegistry that includes all the extensions defined by
 * this file and all files that it depends on.
 **/
GPB_FINAL @interface PROPromotionRoot : GPBRootObject
@end

#pragma mark - PROPlatform

/**
 * Status status = 1;
 **/
GPB_FINAL @interface PROPlatform : GPBMessage

@end

#pragma mark - PROCustomer

/**
 * Status status = 1;
 **/
GPB_FINAL @interface PROCustomer : GPBMessage

@end

#pragma mark - PROAccount

typedef GPB_ENUM(PROAccount_FieldNumber) {
  PROAccount_FieldNumber_CurrencyCode = 2,
};

GPB_FINAL @interface PROAccount : GPBMessage

/** Status status = 1; */
@property(nonatomic, readwrite) enum PROCurrencyCode currencyCode;

@end

/**
 * Fetches the raw value of a @c PROAccount's @c currencyCode property, even
 * if the value was not defined by the enum at the time the code was generated.
 **/
int32_t PROAccount_CurrencyCode_RawValue(PROAccount *message);
/**
 * Sets the raw value of an @c PROAccount's @c currencyCode property, allowing
 * it to be set to a value that was not defined by the enum at the time the code
 * was generated.
 **/
void SetPROAccount_CurrencyCode_RawValue(PROAccount *message, int32_t value);

#pragma mark - PROCampaign

/**
 * Status status = 1;
 **/
GPB_FINAL @interface PROCampaign : GPBMessage

@end

#pragma mark - PROContent

typedef GPB_ENUM(PROContent_FieldNumber) {
  PROContent_FieldNumber_ExternalContentId = 2,
};

GPB_FINAL @interface PROContent : GPBMessage

/** Status status = 1; */
@property(nonatomic, readwrite, copy, null_resettable) NSString *externalContentId;

@end

#pragma mark - PROPromotion

typedef GPB_ENUM(PROPromotion_FieldNumber) {
  PROPromotion_FieldNumber_Content = 2,
  PROPromotion_FieldNumber_BidType = 3,
  PROPromotion_FieldNumber_BidAmount = 4,
};

GPB_FINAL @interface PROPromotion : GPBMessage

/** Status status = 1; */
@property(nonatomic, readwrite, strong, null_resettable) PROContent *content;
/** Test to see if @c content has been set. */
@property(nonatomic, readwrite) BOOL hasContent;

@property(nonatomic, readwrite) PROBidType bidType;

@property(nonatomic, readwrite) double bidAmount;

@end

/**
 * Fetches the raw value of a @c PROPromotion's @c bidType property, even
 * if the value was not defined by the enum at the time the code was generated.
 **/
int32_t PROPromotion_BidType_RawValue(PROPromotion *message);
/**
 * Sets the raw value of an @c PROPromotion's @c bidType property, allowing
 * it to be set to a value that was not defined by the enum at the time the code
 * was generated.
 **/
void SetPROPromotion_BidType_RawValue(PROPromotion *message, int32_t value);

#pragma mark - PROFlatPromotion

typedef GPB_ENUM(PROFlatPromotion_FieldNumber) {
  PROFlatPromotion_FieldNumber_EntityPath = 1,
  PROFlatPromotion_FieldNumber_Account = 4,
  PROFlatPromotion_FieldNumber_Promotion = 6,
};

GPB_FINAL @interface PROFlatPromotion : GPBMessage

@property(nonatomic, readwrite, strong, null_resettable) PROEntityPath *entityPath;
/** Test to see if @c entityPath has been set. */
@property(nonatomic, readwrite) BOOL hasEntityPath;

/**
 * Platform platform = 2;
 * Customer customer = 3;
 **/
@property(nonatomic, readwrite, strong, null_resettable) PROAccount *account;
/** Test to see if @c account has been set. */
@property(nonatomic, readwrite) BOOL hasAccount;

/** Campaign campaign = 5; */
@property(nonatomic, readwrite, strong, null_resettable) PROPromotion *promotion;
/** Test to see if @c promotion has been set. */
@property(nonatomic, readwrite) BOOL hasPromotion;

@end

#pragma mark - PROInsertionLogFlatPromotion

typedef GPB_ENUM(PROInsertionLogFlatPromotion_FieldNumber) {
  PROInsertionLogFlatPromotion_FieldNumber_FlatPromotion = 1,
};

/**
 * This proto gets inserted in a temporary Redis DB between the serving system
 * and the event system to pass along info we don't want to pass externally.
 **/
GPB_FINAL @interface PROInsertionLogFlatPromotion : GPBMessage

/**
 * Even though this only has one field, we'll keep a wrapper message in case
 * we want to add other serving info that we do not want in FlatPromotion.
 **/
@property(nonatomic, readwrite, strong, null_resettable) PROFlatPromotion *flatPromotion;
/** Test to see if @c flatPromotion has been set. */
@property(nonatomic, readwrite) BOOL hasFlatPromotion;

@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)
