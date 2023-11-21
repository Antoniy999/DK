//
//  DKBasketViewModel.swift
//  ABank24
//
//  Created by Anton Vovk on 19.01.2023.
//  Copyright © 2023 ABank. All rights reserved.
//

import Foundation
import RxSwift

let kDeletePosition = "delete_position"
let kGetCommission = "get_commission"
let kPay = "pay"

class DKBasketViewModel: BaseViewModel {
  
    // MARK: - Private Properties

    private var moreModel: ABMoreViewModel = ABMoreViewModel()

    
    // MARK: - Publick Properties
    
    var updateUICommission: PublishSubject<String?> = PublishSubject()
    var updateNPPlace: PublishSubject<ReplenishPoint?> = PublishSubject()
    var updateButton: PublishSubject<Bool> = PublishSubject()
    var basketInfo: DKBasketResponse?
    var selectCard: DBCardProtocol? = DBFacade.shared.getFirstCard(.dynamo)
    var commission: String?
    var mailAddress: String?


    // MARK: - Initialization

    init(basketInfo: DKBasketResponse?) {
        self.basketInfo = basketInfo
        super.init()
        
        listenToServer()
    }
       
    
    // MARK: - Private Methods

    private func listenToServer() {
        updateNPPlace
            .applyIOSchedulers()
            .subscribe { [weak self] place in
                self?.mailAddress = place?.mAddress
                self?.validation()
            } onError: { error in
                Logger.error(error)
            }
            .disposed(by: disposedBag)
    }
    
    
    // MARK: - Logic
    
    func subscribeCardRx(_ publishRx: PublishSubject<DBCardProtocol>) {
        publishRx
            .applyIOSchedulers()
            .subscribe(onNext: { [weak self] (card) in
                guard let self = self else { return }
                self.selectCard = card
                self.getCommission()
            })
            .disposed(by: disposedBag)
    }
    
    func validation() {
        let valid = mailAddress != nil && basketInfo?.mBasket.count != 0
        updateButton.onNext(valid)
    }
    
    
    // MARK: - API
    
    func getCommission() {
        var sum = 0
        basketInfo?.mBasket.forEach({ sum = sum + $0.mSum })
        guard sum != 0 else { return }
       
        var params: [String: Any] = [:]
        params[kAction] = kGetCommission
        params["sum"] = sum
        params["cardId"] = selectCard?.mId
        
        let observable: Observable<ABDataResponse<DKCommissionResponse>?> = moreModel.getDynamoData(params: params)
        observable
            .applyIOSchedulers()
            .subscribe { [weak self] response in
                guard let self = self, let data = response?.mData else { return }
                
                if response?.mStatus == kSuccess {
                    self.commission = data.mCommission
                    self.updateUICommission.onNext(data.mCommission)
                } else {
                    ErrorResponseHandler.treat(message: response?.mMessage ?? "", shouldGoBack: true)
                }
            } onError: {  error in
                ErrorResponseHandler.treat(message: error.localizedDescription)
            }
            .disposed(by: disposedBag)
    }
    
    func removeInBasket(code: String, size: String, completionHandler: VoidClosure?) {
        var params: [String: Any] = [:]
        params[kAction] = kDeletePosition
        params["product_code"] = code
        params["size"] = size

        let observable: Observable<ABDataResponse<DKBasketResponse>?> = moreModel.getDynamoData(params: params)
        observable
            .applyIOSchedulers()
            .subscribe { [weak self] response in
                guard let self = self, let data = response?.mData else { return }
                
                if response?.mStatus == kSuccess {
                    self.basketInfo = data
                    completionHandler?()
                } else {
                    ErrorResponseHandler.treat(message: response?.mMessage ?? "", shouldGoBack: true)
                }
            } onError: {  error in
                ErrorResponseHandler.treat(message: error.localizedDescription)
            }
            .disposed(by: disposedBag)
    }
    
    func payOrder() {
        var sum = 0
        basketInfo?.mBasket.forEach({ sum = sum + $0.mSum })
        
        if (selectCard?.mBalance ?? 0.0) < Double(sum) {
            ErrorResponseHandler.treat(message: ABLocalizedString("insufficientFunds"))
            return
        }

        var params: [String: Any] = [:]
        params[kAction] = kPay
        params["sum"] = sum
        params["cardId"] = selectCard?.mId
        params["delivery_mail_address"] = mailAddress
        
        let observable: Observable<ABDataResponse<DKBasketMessage>?> = moreModel.getDynamoData(params: params)
        observable
            .applyIOSchedulers()
            .subscribe { [weak self] response in
                guard let self = self else { return }
                
                if response?.mStatus == kSuccess {
                    let data = [kFirstInfo: self.mailAddress ?? "",
                               kSecondInfo: String(sum) + " ₴",
                                kThirdInfo: self.commission ?? ""]
                    
                    ABInteractor.main.router.show(model: ABSuccessModelNew(object: DKSuccessObject(data: data, message: response?.mData?.mMessage ?? "")))
                } else {
                    ErrorResponseHandler.treat(message: response?.mMessage ?? "", shouldGoBack: true)
                }
            } onError: {  error in
                ErrorResponseHandler.treat(message: error.localizedDescription)
            }
            .disposed(by: disposedBag)
    }
}
