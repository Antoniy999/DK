//
//  DKStoreViewModel.swift
//  ABank24
//
//  Created by Anton Vovk on 17.01.2023.
//  Copyright © 2023 ABank. All rights reserved.
//

import Foundation
import RxSwift

let kWarehouse = "warehouse"
let kGetBasket = "get_basket"
let kAddToBasket = "add_to_basket"

class DKStoreViewModel: BaseViewModel {
  
    // MARK: - Private Properties

    private var moreModel: ABMoreViewModel = ABMoreViewModel()
    
    
    // MARK: - Publick Properties
    
    var updateUI: PublishSubject<DKShopResponse> = PublishSubject()
    var updateUIBasket: PublishSubject<DKBasketResponse> = PublishSubject()
    var shopInfo: DKShopResponse?
    var basketInfo: DKBasketResponse?


    // MARK: - API
    
    func getInfo() {
        addLoader()
        let params: [String: Any] =  [kAction: kWarehouse]
        let observable: Observable<ABDataResponse<DKShopResponse>?> = moreModel.getDynamoData(params: params)
        observable
            .applyIOSchedulers()
            .subscribe { [weak self] response in
                guard let self = self, let data = response?.mData else { return }
                
                if response?.mStatus == kSuccess {
                    self.shopInfo = data
                    self.updateUI.onNext(data)
                } else {
                    ErrorResponseHandler.treat(message: response?.mMessage ?? "", shouldGoBack: true)
                }
                self.removeLoader()
            } onError: {  error in
                ErrorResponseHandler.treat(message: error.localizedDescription)
            }
            .disposed(by: disposedBag)
    }
  
    func getBasket(isAnimation: Bool = true) {
        if isAnimation { addLoader() }
        let params: [String: Any] =  [kAction: kGetBasket]
        let observable: Observable<ABDataResponse<DKBasketResponse>?> = moreModel.getDynamoData(params: params)
        observable
            .applyIOSchedulers()
            .subscribe { [weak self] response in
                guard let self = self, let data = response?.mData else { return }
                
                if response?.mStatus == kSuccess {
                    self.basketInfo = data
                    self.updateUIBasket.onNext(data)
                } else {
                    ErrorResponseHandler.treat(message: response?.mMessage ?? "", shouldGoBack: true)
                }
                if isAnimation { self.removeLoader() }
            } onError: {  error in
                ErrorResponseHandler.treat(message: error.localizedDescription)
            }
            .disposed(by: disposedBag)
    }
    
    func addItemInBasket(item: [String: Any], completionHandler: VoidClosure?) {
        addLoader()
        var params: [String: Any] = item
        params[kAction] = kAddToBasket
        
        let observable: Observable<ABDataResponse<DKBasketResponse>?> = moreModel.getDynamoData(params: params)
        observable
            .applyIOSchedulers()
            .subscribe { [weak self] response in
                guard let self = self, let data = response?.mData else { return }
                
                if response?.mStatus == kSuccess {
                    self.basketInfo = data
                    self.updateUIBasket.onNext(data)
                    completionHandler?()
                } else {
                    ErrorResponseHandler.treat(message: response?.mMessage ?? "", shouldGoBack: true)
                }
                self.removeLoader()
            } onError: {  error in
                ErrorResponseHandler.treat(message: error.localizedDescription)
            }
            .disposed(by: disposedBag)
    }
}
