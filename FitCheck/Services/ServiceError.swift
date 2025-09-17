//
//  ServiceError.swift
//  FitCheck
//
//  Created by csuftitan on 9/15/25.
//


import Foundation

enum ServiceError: Error {
    case notImplemented
    case unauthenticated
    case permissionDenied
    case network
    case unsupported
    case unknown(String)
}
