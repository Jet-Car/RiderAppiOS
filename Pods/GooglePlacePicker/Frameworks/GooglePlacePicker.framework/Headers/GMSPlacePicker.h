//
//  GMSPlacePicker.h
//  Google Places API for iOS
//
//  Copyright 2016 Google Inc.
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://developers.google.com/maps/terms
//

#if __has_feature(modules)
@import GoogleMapsBase;
#else
#import <GoogleMapsBase/GoogleMapsBase.h>
#endif
#import "GMSPlacePickerConfig.h"

NS_ASSUME_NONNULL_BEGIN;


/**
 * \defgroup PlacePickerErrors GMSPlacePickerErrorCode
 * @{
 */

/**
 * Error domain used for Place Picker errors.
 */
extern NSString *const kGMSPlacePickerErrorDomain;

/**
 * Error codes for |kGMSPlacePickerErrorDomain|.
 */
typedef NS_ENUM(NSInteger, GMSPlacePickerErrorCode) {
  /**
   * Something unknown went wrong.
   */
  kGMSPlacePickerUnknownError = -1,
  /**
   * An internal error occurred in the Places API library.
   */
  kGMSPlacePickerInternalError = -2,
  /**
   * An invalid GMSPlacePickerConfig was used.
   */
  kGMSPlacePickerInvalidConfig = -3,
  /**
   * Attempted to perform simultaneous place picking operations.
   */
  kGMSPlacePickerOverlappingCalls = -4,
};

/**@}*/

/**
 * The Place Picker is a dialog that allows the user to pick a |GMSPlace| using an interactive map
 * and other tools. Users can select the place they're at or nearby.
 *
 * NOTE: This class is deprecated, it is recommended that you use |GMSPlacePickerViewController|
 * instead.
 */
__GMS_AVAILABLE_BUT_DEPRECATED_MSG("Use GMSPlacePickerViewController instead")
@interface GMSPlacePicker : NSObject

/**
 * The configuration of the place picker, as passed in at initialization.
 */
@property(nonatomic, readonly, copy)
    GMSPlacePickerConfig *config __GMS_AVAILABLE_BUT_DEPRECATED_MSG(
        "Use GMSPlacePickerViewController instead");

/**
 * Initializes the place picker with a given configuration. This does not start the process of
 * picking a place.
 */
- (instancetype)initWithConfig:(GMSPlacePickerConfig *)config
    __GMS_AVAILABLE_BUT_DEPRECATED_MSG("Use GMSPlacePickerViewController instead");

/**
 * Prompt the user to pick a place. The place picker is a full-screen window that appears on
 * [UIScreen mainScreen]. The place picker takes over the screen until the user cancels the
 * operation or picks a place. The supplied callback will be invoked with the chosen place, or nil
 * if no place was chosen.
 *
 * This method should be called on the main thread. The callback will also be invoked on the main
 * thread.
 *
 * It is not possible to have multiple place picking operations active at the same time. If this is
 * attempted, the callback will be invoked with an error.
 */
- (void)pickPlaceWithCallback:(GMSPlaceResultCallback)callback
    __GMS_AVAILABLE_BUT_DEPRECATED_MSG("Use GMSPlacePickerViewController instead");

@end

NS_ASSUME_NONNULL_END;
