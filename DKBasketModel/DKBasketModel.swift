//
//  DKBasketModel.swift
//  ABank24
//
//  Created by Anton Vovk on 19.01.2023.
//  Copyright © 2023 ABank. All rights reserved.
//

import Foundation
import UIKit

class DKBasketModel: RouterModel {
    
    // MARK: - Private Properties

    private var viewModel: DKBasketViewModel
    lazy private var lbCommission: UILabel = {
        let view = UILabel()
        view.font = .regular14
        view.textColor = .mABBlackTextColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        ABConstraintBuilder().setViewHeight(view: view, value: 16)

        return view
    }()
    
    lazy private var lbSum: UILabel = {
        let view = UILabel()
        view.font = .regular16
        view.textColor = .mABBlackTextColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        ABConstraintBuilder().setViewHeight(view: view, value: 16)

        return view
    }()

    
    // MARK: - Initialization

    init(basketInfo: DKBasketResponse?) {
        viewModel = DKBasketViewModel(basketInfo: basketInfo)
        super.init()
        
        startSettings()
        listenToServer()
    }
    
    
    // MARK: - Overrides
    
    override func initConstructor() {
        constructor?.info = DKBasketInfo(viewModel: self.viewModel)
        constructor?.deleteHandler = {[weak self] indexPath, object in
            if let item = object?.object as? DKBasketItem  {
                self?.viewModel.removeInBasket(code: item.mProductCode, size: item.mSize) { [weak self] in
                    guard let self = self else { return }
                    self.constructor?.info.sectionInfo[indexPath.section].data.remove(at: indexPath.row)
                    self.constructor?.tableView.deleteRows(at: [indexPath], with: .fade)
                    self.viewModel.getCommission()
                    self.viewModel.validation()
                }
            }
        }
        
        let stack = UIStackView()
        stack.addArrangedSubview(lbSum)
        stack.addArrangedSubview(lbCommission)
        stack.axis = .vertical
        stack.spacing = 4
       
        bottomStackUpdateView.onNext((view: stack, at: 0, isRemove: false))
        viewModel.getCommission()
    }

    
    // MARK: - Private Properties

    private func startSettings() {
        hideBottomButton = false
        canShowRoundBottomView = true
        
        screenTitle = ABLocalizedString("garbage_title")
        
        customizeBottomButton = { button in
            button.setTitle(ABLocalizedString("payFunds"), for: .normal)
        }
        
        hideBottomButton(boolValue: true)
    }
    
    private func updateSumAndCommission() {
        lbSum.isHidden = (viewModel.basketInfo?.mBasket.count ?? 0) < 1
        lbCommission.isHidden = (Double(viewModel.commission ?? "0.0") ?? 0.0 ) == 0.0

        var sum = 0
        var сount = 0
        
        viewModel.basketInfo?.mBasket.forEach{ item in
            sum = sum + item.mSum
            сount = сount + item.mCountInt
        }
    
        let firstText1 = сount < 5 ? ABLocalizedString("goods_worth_1") :  ABLocalizedString("goods_worth_2")
        let firstText2 = ABLocalizedString("commission_title")
        
        UIView.transition(with: lbSum,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            guard let self = self else { return }
            self.lbSum.add(firstText: String(сount) + firstText1, secondText: " " + String(sum) + " ₴", font: .regular16)
        }, completion: nil)
        
        UIView.transition(with: lbCommission,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            guard let self = self else { return }
            self.lbCommission.add(firstText: firstText2, secondText: (self.viewModel.commission ?? "0.0") + " ₴", font: .regular14)
        }, completion: nil)
    }
    
    private func listenToServer() {
        viewModel.updateUICommission
            .applyIOSchedulers()
            .subscribe { [weak self] response in
                self?.updateSumAndCommission()
            } onError: { error in
                Logger.error(error)
            }
            .disposed(by: disposeBag)
        
        viewModel.updateButton
            .applyIOSchedulers()
            .subscribe { [weak self] valid in
                self?.hideBottomButton(boolValue: !valid)
            } onError: { error in
                Logger.error(error)
            }
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Actions

    override func bottomButtonTapped() {
        super.bottomButtonTapped()
       
        viewModel.payOrder()
    }
}
