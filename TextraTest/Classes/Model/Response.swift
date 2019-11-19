//
//  Response.swift
//  TextraTest
//
//  Created by shoshikawa on 2019/11/07.
//  Copyright © 2019 Susumu Hoshikawa. All rights reserved.
//

import Foundation

struct TextraResponse: Codable {
    let resultset: Resultset
}

struct Resultset: Codable {
    let code: Int
    let message: String
    let request: Request
    let result: Result
}

struct Request: Codable {
    let url: String
    let text: String
    let split: Int
    let data: String
}

struct Result: Codable {
    let text: String
    let information: Information
}

struct Information: Codable {
    let textS: String
    let textT: String
    let sentence: [Sentence]
    
    enum CodingKeys: String, CodingKey {
        case textS = "text-s"
        case textT = "text-t"
        case sentence
    }
}

struct Sentence: Codable {
    let textS: String
    let textT: String
    let split: [Split]
    
    enum CodingKeys: String, CodingKey {
        case textS = "text-s"
        case textT = "text-t"
        case split
    }
}

struct Split: Codable {
    let textS: String
    let textT: String
    let process: Process
    
    enum CodingKeys: String, CodingKey {
        case textS = "text-s"
        case textT = "text-t"
        case process
    }
}

struct Process: Codable {
    
}
