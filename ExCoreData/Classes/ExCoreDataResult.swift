//
//  DKResult.swift
//  DKLibrary
//
//  Created by yuya on 2017/06/17.
//  Copyright © 2017年 yuya. All rights reserved.
//

public enum ExCoreDataResult<T, Error> {
    case success(T)
    case failure(Error)
}
