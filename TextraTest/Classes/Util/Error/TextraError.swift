//
//  TextraError.swift
//  TextraTest
//
//  Created by shoshikawa on 2019/11/07.
//  Copyright © 2019 Susumu Hoshikawa. All rights reserved.
//

import Foundation

enum TextraError: Error {
    case parsing(description: String)
    case network(description: String)
}
