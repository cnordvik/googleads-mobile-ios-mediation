// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADPangleRTBBannerRenderer.h"
#include <stdatomic.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"
#import "GADPangleNetworkExtras.h"
#import <PAGAdSDK/PAGAdSDK.h>

@interface GADPangleRTBBannerRenderer () <PAGBannerAdDelegate>

@property (nonatomic, copy) GADMediationBannerLoadCompletionHandler loadCompletionHandler;
@property (nonatomic, strong) PAGBannerAd *bannerAd;
@property (nonatomic, weak) id<GADMediationBannerAdEventDelegate> delegate;

@end

@implementation GADPangleRTBBannerRenderer

- (void)renderBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:
                         (nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  self.loadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
      _Nullable id<GADMediationBannerAd> ad, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationBannerAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(ad, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  NSString *placementId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";
  if (!placementId.length) {
    NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(
        GADPangleErrorInvalidServerParameters,
        [NSString stringWithFormat:@"%@ cannot be nil.", GADMAdapterPanglePlacementID]);
    self.loadCompletionHandler(nil, error);
    return;
  }

  NSError *error = nil;
  PAGBannerAdSize bannerSize = [self bannerSizeFormGADAdSize:adConfiguration.adSize error:&error];
  if (error) {
    self.loadCompletionHandler(nil, error);
    return;
  }
  
  PAGBannerRequest *request = [PAGBannerRequest requestWithBannerSize:bannerSize];
  request.adString = adConfiguration.bidResponse;
  __weak typeof(self) weakSelf = self;
  [PAGBannerAd loadAdWithSlotID:placementId
                        request:request
              completionHandler:^(PAGBannerAd * _Nullable bannerAd,
                                  NSError * _Nullable loadError) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
       return;
    }
    if (loadError) {
      strongSelf.loadCompletionHandler(nil,loadError);
      return;
    }
    
    CGRect frame = bannerAd.bannerView.frame;
    frame.size = bannerSize.size;
    bannerAd.bannerView.frame = frame;
    bannerAd.rootViewController = adConfiguration.topViewController;
    
    strongSelf.bannerAd = bannerAd;
    strongSelf.bannerAd.delegate = strongSelf;
    
    if (strongSelf.loadCompletionHandler) {
      strongSelf.delegate = strongSelf.loadCompletionHandler(strongSelf,nil);
    }
  }];
}

- (PAGBannerAdSize)bannerSizeFormGADAdSize:(GADAdSize)gadAdSize error:(NSError **)error {
  CGSize gadAdCGSize = CGSizeFromGADAdSize(gadAdSize);
  GADAdSize banner50 = GADAdSizeFromCGSize(
      CGSizeMake(gadAdCGSize.width, kPAGBannerSize320x50.size.height));  // 320*50
  GADAdSize banner90 = GADAdSizeFromCGSize(
      CGSizeMake(gadAdCGSize.width, kPAGBannerSize728x90.size.height));  // 728*90
  GADAdSize banner250 = GADAdSizeFromCGSize(
      CGSizeMake(gadAdCGSize.width, kPAGBannerSize300x250.size.height));  // 300*250
  NSArray *potentials = @[
    NSValueFromGADAdSize(banner50), NSValueFromGADAdSize(banner90), NSValueFromGADAdSize(banner250)
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
  if (size.height == kPAGBannerSize320x50.size.height) {
    return kPAGBannerSize320x50;
  } else if (size.height == kPAGBannerSize728x90.size.height) {
    return kPAGBannerSize728x90;
  } else if (size.height == kPAGBannerSize300x250.size.height) {
    return kPAGBannerSize300x250;
  }

  if (error) {
    *error = GADMAdapterPangleErrorWithCodeAndDescription(
        GADPangleErrorBannerSizeMismatch,
        [NSString stringWithFormat:@"Invalid size for Pangle mediation adapter. Size: %@",
                                   NSStringFromGADAdSize(gadAdSize)]);
  }
  return (PAGBannerAdSize){CGSizeZero};
}

#pragma mark - GADMediationBannerAd
- (nonnull UIView *)view {
  return self.bannerAd.bannerView;
}

#pragma mark - PAGBannerAdDelegate

- (void)adDidShow:(PAGBannerAd *)ad {
  id<GADMediationBannerAdEventDelegate> delegate = self.delegate;
  [delegate reportImpression];
}

- (void)adDidClick:(PAGBannerAd *)ad {
  id<GADMediationBannerAdEventDelegate> delegate = self.delegate;
  [delegate reportClick];
}

@end
