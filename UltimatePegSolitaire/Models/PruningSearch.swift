//
//  PruningSearch.swift
//  UltimatePegSolitaire
//
//  Created by Maksim Khrapov on 8/25/19.
//  Copyright © 2019 Maksim Khrapov. All rights reserved.
//

// https://www.ultimatepegsolitaire.com/
// https://github.com/mkhrapov/ultimate-peg-solitaire
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


import Foundation


final class PruningSearch {
    let initialPosition: Position
    var pruningNumber = 200
    var solutions = [Position]()
    var probability = 0.0
    var generation: [Position]
    var progressCallback: ((Double) -> ())?
    var currentGen = 0.0
    var numGenerations = 0.0
    var cancelCallback: (() -> Bool)?
    var hasBeenCanceled = false
    var timeOutInSeconds: Int?
    var startTime: DispatchTime
    
    
    
    init(_ initialPosition: Position) {
        self.initialPosition = initialPosition
        let steps = initialPosition.board.allowed.count - 2
        probability = 1.0 / Double(steps)
        generation = [Position]()
        numGenerations = Double(steps)
        startTime = DispatchTime.now()
    }
    
    func shouldReplaceChild() -> Bool {
        let x = Double.random(in: 0.0 ..< 1.0)
        if x < probability {
            return true
        }
        return false
    }
    
    
    func prune(_ newPruningNumber: Int) {
        pruningNumber = newPruningNumber
    }
    
    
    func getSolution(_ i: Int) -> Position {
        return solutions[i]
    }
    
    
    func search() -> Int {
        generation = [Position]()
        generation.append(initialPosition)
        
        startTime = DispatchTime.now()
        while true {
            if searchByGeneration() {
                break
            }
            
            if solutions.count > 0 {
                break
            }
            
            if let timeOut = timeOutInSeconds {
                let now = DispatchTime.now()
                let timer = Double(now.uptimeNanoseconds - startTime.uptimeNanoseconds)/1_000_000_000.0
                if timer > Double(timeOut) {
                    return -2
                }
            }
        }
        
        if hasBeenCanceled {
            return -1
        }
        else {
            return solutions.count
        }
    }
    
    func searchByGeneration() -> Bool {
        if let cancelCallback = cancelCallback {
            let cancel = cancelCallback()
            if cancel {
                hasBeenCanceled = true
                return true
            }
        }
        if let progressCallback = progressCallback {
            progressCallback(currentGen/numGenerations)
        }
        currentGen += 1.0
        
        if generation.count == 0 {
            return true
        }
        
        var dedup = [String:Position]()
        var children = [Position]()
        
        for p in generation {
            for child in p.children() {
                let id = child.getID()
                
                if dedup[id] == nil {
                    dedup[id] = child
                }
                else {
                    if shouldReplaceChild() {
                        dedup[id] = child
                    }
                }
            }
        }
        
        for child in dedup.values {
            children.append(child)
        }
        
        if children.count == 0 {
            return true
        }
        
        for p in children {
            if p.isFinal() {
                solutions.append(p)
            }
        }
        
        if solutions.count > 0 {
            return true
        }
        
        if pruningNumber > 0 && children.count > pruningNumber {
            let children2 = children.sorted(by: { $0.getScore() < $1.getScore() } )
            var children3 = [Position]()
            for i in 0..<pruningNumber {
                children3.append(children2[i])
            }
            generation = children3
        }
        else {
            generation = children
        }
        
        return false
    }
}
