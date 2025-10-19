//
//  XViewModelFactory.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/18/25.
//

public protocol XViewModelFactory {
    associatedtype InputModel
    associatedtype ViewModel
    static func createViewModel(_ inputModel: InputModel) -> ViewModel
}
