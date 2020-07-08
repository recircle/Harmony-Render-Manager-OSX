//
//  RenderFiles.swift
//  Hrender
//
//  Created by Denis Alenti on 5/19/20.
//  Copyright © 2020 Recircle. All rights reserved.
//

import Foundation

class XSFile: NSObject
{
    var id = Int()
    var file = String()
    var fileURL = String()
    var fileExportURL = String()
    var fileDirPath = String()
    var fileName = String()
    var fileNodeList: [String]!
    
    var exportFileName = String()
    var exportFilePath = String()
    
    var osPCPath:String = "C:\\Program Files (x86)\\Toon Boom Animation\\Toon Boom Harmony 17 Premium\\win64\\bin\\HarmonyPremium.exe"
    var OsMACPath:String = "/Applications/Toon\\ Boom\\ Harmony\\ 17\\ Premium/Harmony\\ Premium.app/Contents/MacOS/Harmony\\ Premium"
    
    let defualtNodesExport:String = "all"
    let defualtExtension:String = ".xstage"
    let defaultNameAppendix:String = "_render"
    
//    var xmlData = Data()
    var xmlData = String()
    
    func setData(filename: String)
    {
        guard
//            let xml = try? Data(contentsOf: URL(fileURLWithPath: filename))
            let xml = try? String(contentsOf: URL(fileURLWithPath: filename))
            else {
                print("resource not found!")
                return
        }
        
        
        
        xmlData = xml
    }
}


