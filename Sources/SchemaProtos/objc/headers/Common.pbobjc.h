// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: proto/common/common.proto

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

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enum PROCurrencyCode

typedef GPB_ENUM(PROCurrencyCode) {
  /**
   * Value used if any message's field encounters a value that is not defined
   * by this enum. The message will also have C functions to get/set the rawValue
   * of the field.
   **/
  PROCurrencyCode_GPBUnrecognizedEnumeratorValue = kGPBUnrecognizedEnumeratorValue,
  PROCurrencyCode_UnknownCurrencyCode = 0,
  PROCurrencyCode_Usd = 1,
  PROCurrencyCode_Eur = 2,
  PROCurrencyCode_Jpy = 3,
  PROCurrencyCode_Gbp = 4,
  PROCurrencyCode_Aud = 5,
  PROCurrencyCode_Cad = 6,
  PROCurrencyCode_Chf = 7,
  PROCurrencyCode_Cny = 8,
  PROCurrencyCode_Hkd = 9,
  PROCurrencyCode_Nzd = 10,
  PROCurrencyCode_Sek = 11,
  PROCurrencyCode_Krw = 12,
  PROCurrencyCode_Sgd = 13,
  PROCurrencyCode_Nok = 14,
  PROCurrencyCode_Mxn = 15,
  PROCurrencyCode_Inr = 16,
  PROCurrencyCode_Rub = 17,
  PROCurrencyCode_Zar = 18,
  PROCurrencyCode_Try = 19,
  PROCurrencyCode_Brl = 20,
};

GPBEnumDescriptor *PROCurrencyCode_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL PROCurrencyCode_IsValidValue(int32_t value);

#pragma mark - PROCommonRoot

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
GPB_FINAL @interface PROCommonRoot : GPBRootObject
@end

#pragma mark - PROEntityPath

typedef GPB_ENUM(PROEntityPath_FieldNumber) {
  PROEntityPath_FieldNumber_PlatformId = 1,
  PROEntityPath_FieldNumber_CustomerId = 2,
  PROEntityPath_FieldNumber_ContentId = 3,
  PROEntityPath_FieldNumber_AccountId = 4,
  PROEntityPath_FieldNumber_CampaignId = 5,
  PROEntityPath_FieldNumber_PromotionId = 6,
};

GPB_FINAL @interface PROEntityPath : GPBMessage

@property(nonatomic, readwrite) uint64_t platformId;

@property(nonatomic, readwrite) uint64_t customerId;

@property(nonatomic, readwrite) uint64_t accountId;

@property(nonatomic, readwrite) uint64_t campaignId;

@property(nonatomic, readwrite) uint64_t promotionId;

@property(nonatomic, readwrite) uint64_t contentId;

@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)
