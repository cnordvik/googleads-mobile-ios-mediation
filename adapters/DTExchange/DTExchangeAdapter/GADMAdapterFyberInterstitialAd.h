// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterFyberInterstitialAd : NSObject

/// Dedicated initializer to create a new instance of an interstitial ad.
- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Loads an interstitial ad from the DT Exchange SDK.
- (void)loadInterstitialAdWithCompletionHandler:
    (nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler;

@end