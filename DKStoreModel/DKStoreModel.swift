//
//  DKStoreModel.swift
//  ABank24
//
//  Created by Anton Vovk on 17.01.2023.
//  Copyright © 2023 ABank. All rights reserved.
//

import Foundation
import UIKit

class DKStoreModel: RouterModel {
    
    // MARK: - Private Properties

    private var viewModel = DKStoreViewModel()
    private var btBasket: UIButton!
    lazy private var lbCount: UILabel = {
        let view = UILabel()
        view.font = .medium12
        view.textColor = .mABWhite
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    lazy private var vArhivCount: UIView! = {
        let view = UIView()
        view.backgroundColor = .mABGreen
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cornerRadius = 10
        view.isHidden = true
        ABConstraintBuilder().setViewHeight(view: view, value: 20)
        ABConstraintBuilder().setViewWidth(view: view, value: 20)
        
        return view
    }()

    
    // MARK: - Overrides

    override init() {
        super.init()
        
        startSettings()
        listenToServer()
        viewModel.getInfo()
    }
    
    override func allDataLoaded() {
        super.allDataLoaded()
        
        addHeader()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
       
        viewModel.getBasket(isAnimation: false)
    }
    
    
    // MARK: - Private Properties

    private func startSettings() {
        customizeActionButton = { [weak self] button in
            guard let self = self else { return }
            button.isHidden = true
            button.setImage(UIImage(named: "ic_arhiv_vkladu"), for: .normal)
            self.btBasket = button
            
            button.addSubview(self.vArhivCount)
            self.vArhivCount.addSubview(self.lbCount)
            ABConstraintBuilder().setCenterX(view: self.lbCount, toView: self.vArhivCount)
            ABConstraintBuilder().setCenterY(view: self.lbCount, toView: self.vArhivCount)
            ABConstraintBuilder().setCenterY(view: self.vArhivCount, toView: button, constant: 12)
            ABConstraintBuilder().setCenterX(view: self.vArhivCount, toView: button, constant: -15)
        }
    }
    
    override func initConstructor() {
        constructor2?.topAlignInSection = 1
        constructor2?.info = info
        constructor2?.collectionView?.collectionViewLayout = ABLeftAlignedLayout()
        constructor2?.handler = { _, object in
            if let item = object?.object as? DKShopItem  {
                let height: CGFloat = 700 + UIApplication.shared.keyWindow!.safeAreaInsets.bottom
                let view = DynamoDetailView.configure(object: item)
                let bottomSheet = BottomSheetView.configure(with: height, content: view, isIndicator: true)
                view.closeClosure = { [weak bottomSheet] in
                    bottomSheet?.closeBottomSheet()
                }
                
                view.selectClosure = { [weak bottomSheet, weak self] parameters in
                    self?.viewModel.addItemInBasket(item: parameters) { [weak bottomSheet] in
                        bottomSheet?.closeBottomSheet()
                    }
                }
            }
        }
    }
    
    private func updateBasket(count: Int) {
        vArhivCount.isHidden = count < 1
        btBasket.isHidden = count < 1
        
        UIView.transition(with: lbCount,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            guard let self = self else { return }
            self.lbCount.text = String(count)
        }, completion: nil)
    }
    
    private func addHeader() {
        let headerView = SimpleImageFlexibleHeader.configureView(title: ABLocalizedString("dynamo_info"),
                                                                 image: UIImage(named: "ic_dynamo_kyiv"),
                                                                 imageSize: CGSize(width: 43, height: 43),
                                                                 topConstraint: 0)
        headerView.frame = CGRect(origin: .zero, size: CGSize(width: .zero, height: 140))
        addFillHeader(headerView, animated: false)
    }
    
    private func listenToServer() {
        viewModel.updateUI
            .applyIOSchedulers()
            .subscribe { [weak self] response in
                guard let self = self else { return }
                self.info = DKStoreInfo(viewModel: self.viewModel)
                self.constructor2?.info = self.info
                self.constructor2?.reloadFrames()
            } onError: { error in
                Logger.error(error)
            }
            .disposed(by: disposeBag)
        
        viewModel.updateUIBasket
            .applyIOSchedulers()
            .subscribe { [weak self] response in
                guard let self = self else { return }
                self.updateBasket(count: response.mBasket.count)
            } onError: { error in
                Logger.error(error)
            }
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Actions

    override func actionButtonTapped() {
        ABInteractor.main.router.show(model: DKBasketModel(basketInfo: viewModel.basketInfo))
    }
}
