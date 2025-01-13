#ifndef MUXSDKErrorEvent_h
#define MUXSDKErrorEvent_h

#import "MUXSDKPlaybackEvent.h"
#import <Foundation/Foundation.h>

extern NSString * _Nonnull const MUXSDKPlaybackEventErrorEventType;

/// The severity of a player error recorded by the SDK
typedef NS_ENUM(NSInteger, MUXSDKErrorSeverity) {
    /// An error event with a fatal severity is an unrecoverable
    /// error that arrests playback.
    MUXSDKErrorSeverityFatal,
    /// An error event with a warning severity is a recoverable
    /// error that is noteworthy and after which playback may continue.
    MUXSDKErrorSeverityWarning
};

/// Signals that the player has encountered a technical playback
/// error or a business exception relating to playback.
///
/// It is important to set a warning severity if an error is
/// recoverable and a fatal severity if an error is unrecoverable.
/// A view with error that has a fatal severity will be recorded as
/// a playback failure by Mux.
@interface MUXSDKErrorEvent : MUXSDKPlaybackEvent

/// Arbirtrary error context encoded as a string
@property (nullable) NSString *errorContext;

/// Recorded severity of the error, defaults to MUXSDKErrorSeverityFatal
@property (nonatomic, assign) MUXSDKErrorSeverity severity;

/// If ``YES`` indicates that the error is classified to be
/// a business exception. If ``NO`` indicates that the error
/// is classified as a technical failure. Defaults to ``NO`.
@property (nonatomic, assign) BOOL isBusinessException;


/// Initializes an error event
/// - Parameters:
///   - errorContext: error context encoded as a string
- (nonnull instancetype)initWithContext:(nullable NSString *)errorContext;

/// Initializes an error event
/// - Parameters:
///   - severity: severity level of the error
///   as a business exception or technical error
///   - errorContext: error context encoded as a string
- (nonnull instancetype)initWithSeverity:(MUXSDKErrorSeverity)severity
                                 context:(nullable NSString *)errorContext;

/// Initializes an error event
/// - Parameters:
///   - severity: severity level of the error
///   - isBusinessException: whether the error is classified
///   as a business exception or technical error
///   - errorContext: error context encoded as a string
- (nonnull instancetype)initWithSeverity:(MUXSDKErrorSeverity)severity
                     isBusinessException:(BOOL)isBusinessException
                                 context:(nullable NSString *)errorContext;

@end

#endif
