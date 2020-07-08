//
//  ViewController.swift
//  Hrender
//
//  Created by Denis Alenti on 5/18/20.
//  Copyright © 2020 Recircle. All rights reserved.
//

import Cocoa
import Foundation

class ViewController: NSViewController, NSTextFieldDelegate, NSControlTextEditingDelegate
{
    //table
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var defaultExportDirTxtField: NSTextField!
    var charPopupMenu: NSPopUpButton!
    
    var rowsNum:Int = 0
    var tableClickedRow:Int = 0
    
    var defaultExportURL = String()
    
    //Render all
    var renderFileNum:Int = 0
    var readerAllFile:Bool = false
    
    //Files
    var xsFile = XSFile()
    var xsFiles : [XSFile] = []
    var charEdit:Bool = false
    var charNames = [String]()
    
    // MARK: - View
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.target = self
        tableView.action = #selector(onItemClicked)
//        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        
    }
    
    // MARK: - XML
    func parseFile(id: Int)
    {
        let rowId = id
        
        var options = AEXMLOptions()
        options.parserSettings.shouldProcessNamespaces = false
        options.parserSettings.shouldReportNamespacePrefixes = false
        options.parserSettings.shouldResolveExternalEntities = false
        options.parserSettings.shouldTrimWhitespace = false
        
        do {
//            let xmlDoc = try AEXMLDocument(xml: xsFiles.map{$0.xmlData}[tableClickedRow], options: options)
            let xmlDoc = try AEXMLDocument(xml: self.xsFiles.map{$0.xmlData}[rowId], encoding: String.Encoding.utf8, options: options)
            
            if let scenes = xmlDoc.root["scenes"]["scene"].all(withAttributes: ["name" : "Top"]) {
                for sNodes in scenes {
                    let rGroup = sNodes["rootgroup"]
                    let nList = rGroup["nodeslist"]
                    for module in nList.children {
                        let valuesArray = ["Camera","Composite","Display","TopLayer","Camera_Peg","screenshot","Write"]
                        if(!valuesArray.contains(module.attributes["name"]!)) {
                            charNames.append(module.attributes["name"]!)
                            
//                            print("Module:", module.attributes["name"]!)
                        }
                        
                        if(module.attributes["name"] == "Write"){
                            let wModule = module
                            let attr = wModule["attrs"]
                            attr.removeFromParent()
                            exporVideoSettings(id: rowId, node: wModule)
                        }
                    }
                }
            }
            
//            print(xmlDoc.xmlSpaces)
//            xsFiles.filter({$0.id == tableClickedRow}).first?.xmlData = Data(xmlDoc.xml.utf8)
            xsFiles.filter({$0.id == rowId}).first?.xmlData = xmlDoc.xmlSpaces
            
        }catch {
            print("\(error)")
        }
        
        DispatchQueue.main.async {
                self.tableView.reloadData()
        }
        
//        print("Export render path - ", self.xsFiles.map{$0.exportFilePath}[rowId])
    }
    
    func exporVideoSettings(id: Int, node: AEXMLElement)
    {
        let rowId = id
        
        let rendName = self.xsFiles.map{$0.exportFilePath}[rowId] + "/" + xsFiles.map{$0.exportFileName}[rowId]
        
        let module = node
        let eNode = module.addChild(name: "attrs")
        eNode.addChild(name: "exportToMovie", value: nil, attributes: ["val": "true"])
        eNode.addChild(name: "drawingName", value: nil, attributes: ["val": "frames/final-"]) //rendName
        eNode.addChild(name: "moviePath", value: nil, attributes: ["val": rendName])
        eNode.addChild(name: "movieFormat", value: nil, attributes: ["val": "com.toonboom.av.foundation.mov.1.0"])
        eNode.addChild(name: "movieAudio")
        eNode.addChild(name: "movieVideo")
        eNode.addChild(name: "movieVideoaudio", value: nil, attributes: ["val": "com.toonboom.av.foundation.mov.1.0:enableSound(0)com.toonboom.av.foundation.mov.1.0:sampleRate(22050)com.toonboom.av.foundation.mov.1.0:nChannels(2)com.toonboom.av.foundation.mov.1.0:videoCodec(prores4444)com.toonboom.av.foundation.mov.1.0:alpha(1)"])
        eNode.addChild(name: "leadingZeros", value: nil, attributes: ["val": "3"])
        eNode.addChild(name: "start", value: nil, attributes: ["val": "1"])
        eNode.addChild(name: "drawingType", value: nil, attributes: ["val": "PNG4"])
        let enb = eNode.addChild(name: "enabling")
        enb.addChild(name: "filter", value: nil, attributes: ["val": "ALWAYS"])
        enb.addChild(name: "filterName")
        enb.addChild(name: "filterResX", value: nil, attributes: ["val": "720"])
        enb.addChild(name: "filterResY", value: nil, attributes: ["val": "540"])
        eNode.addChild(name: "compositePartitioning", value: nil, attributes: ["val": "NoCompositePartitioning"])
        eNode.addChild(name: "zPartitionRange", value: nil, attributes: ["val": "1", "defaultValue": "1"])
        eNode.addChild(name: "cleanUpPartitionFolders", value: nil, attributes: ["val": "true"])
        
//        print(eNode.xml)
    }
    
    func saveXml(id: Int)
    {
        let rowId = id
        
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .background).async {
            self.parseFile(id: rowId)
            group.leave()
        }
        group.wait()
        
        
        let path = String(xsFiles.map{$0.fileURL}[rowId].dropLast(7)) + "_render.xstage"
        let url = URL(fileURLWithPath: path)
        let data = xsFiles.map{$0.xmlData}[rowId]
        
        do {
            try data.write(to: url, atomically: false, encoding: String.Encoding.utf8)
        }
        catch {
            print("Write error at:", path)
        }
        
        print("File saved:", path)
        
        if (FileManager.default.fileExists(atPath: path)) {
            sendFileToShell(path: path)
        }
        
    }
    
    func renderAllFiles()
    {
        saveXml(id: renderFileNum)
    }
    
    // MARK: - Shell
    func sendFileToShell(path: String)
    {
//        HarmonyPremium.exe -batch -scene PathToYourScene\yourScene.xstage
//
//        printShell(launchPath: "/bin/ls")
//        printShell(launchPath: "/bin/ls", arguments:["-a", "-g"])
//        printShell(launchPath: "/usr/bin/open", arguments:["-n", "-a", "/Applications/Spine/Spine.app"])
        
//        let hP = "/Volumes/Macintosh HD-1/Applications/Toon Boom Harmony 17 Premium/Harmony Premium.app/Contents/MacOS/Harmony Premium "
        let harmonyPath = "/Applications/Toon Boom Harmony 17 Premium/Harmony Premium.app/Contents/MacOS/Harmony Premium"
        let filePath = path
        printShell(launchPath: harmonyPath, arguments:["-batch", "-scene", filePath])
        
    }
    
    func printShell(launchPath: String, arguments: [String] = [])
    {
//        let output = shell(launchPath: launchPath, arguments: arguments)
        
        let (goodOutput, goodStatus) = shell(launchPath: launchPath, arguments: arguments)
        if let out = goodOutput {
            print("`Frame rendered: \(out)\n")
        }
        
        if(goodStatus == 100 && readerAllFile){
            renderFileNum += 1
            if( renderFileNum <= xsFiles.count-1) {
                print("Print next num: ", renderFileNum)
                renderAllFiles()
            }
            else{
                renderFileNum = 0
                readerAllFile = false
                print("Render complete!")
            }
        }
        
//        print("Returned \(goodStatus)\n")
        
    }
    
    func shell(launchPath: String, arguments: [String] = []) -> (String? , Int32) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        
        task.waitUntilExit()
        return (output, task.terminationStatus)
        
//        return output
    }
    
    // MARK: - Actions
    @IBAction func browseFile(_ sender: AnyObject)
    {
        let openPanel = NSOpenPanel();
        openPanel.title = "Choose a .xstage file";
        openPanel.allowedFileTypes = ["xstage"];
        
        if (openPanel.runModal() == NSApplication.ModalResponse.OK) {
            let result = openPanel.url
            
//            let url = openPanel.directoryURL
//            let path = result!.deletingLastPathComponent().relativePath
            
            if (result != nil)
            {
                xsFile = XSFile()
                xsFile.id = rowsNum
                xsFile.fileDirPath = result!.deletingLastPathComponent().relativePath
                xsFile.fileURL = result!.path
                xsFile.fileName = String(result!.lastPathComponent.dropLast(7))
                xsFile.setData(filename: result!.path)
                
                let eName = "K" + xsFile.fileName.suffix(2)
                xsFile.exportFileName = String(eName)
                
                if(!defaultExportURL.isEmpty)
                {
                    xsFile.exportFilePath = defaultExportURL
                }
                
                xsFiles.append(xsFile)
                
                rowsNum += 1
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
                print("URL:", xsFile.fileURL, " Path:", xsFile.fileDirPath, " Name:", xsFile.fileName)
            }
        } else {
            return
        }
    }
    
    @IBAction func renderAll(_ sender: Any)
    {
        if(!readerAllFile) {
            readerAllFile = true
            renderAllFiles()
        }
        
//        print("render all files")
    }
    
    @IBAction func renderFile(_ sender: Any)
    {
        readerAllFile = false
        
        let selectedRow = tableView.row(for: sender as! NSView)
        saveXml(id: selectedRow)
        
//        print("RENDER FILE: " + self.xsFiles.map{$0.exportFilePath}[selectedRow] + "/" + xsFiles.map{$0.exportFileName}[selectedRow])
        
    }
    
    @IBAction func removeFile(_ sender: Any)
    {
        let selectedRow = tableView.row(for: sender as! NSView)
        
        xsFiles.remove(at: selectedRow)
        rowsNum -= 1
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        print("remove file \(selectedRow)")
    }
    
    @IBAction func charactersPopUpButton(_ sender: NSPopUpButton) {
        
        print("Char button selected at:", sender.titleOfSelectedItem!)
    }
    
    @IBAction func videoPopUpButton(_ sender: NSPopUpButton) {
        
        print("Video button selected at:", sender.titleOfSelectedItem!)
    }
    
    @IBAction func exportNameTextField(_ sender: NSTextField)
    {
        xsFiles.filter({$0.id == tableClickedRow}).first?.exportFileName = sender.stringValue
        
//        print("Set movie name", sender.stringValue)
    }
    
    @IBAction func browseAllFiles(_ sender: Any) {
        let openPanel = NSOpenPanel();
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        if (openPanel.runModal() == NSApplication.ModalResponse.OK) {
            let result = openPanel.url
            if (result != nil)
            {
//                let localFileManager = FileManager()
//                let dirEnum = localFileManager.enumerator(atPath: result!.path)
                
                let dirContents = FileManager.default.enumerator(at: result!.resolvingSymlinksInPath(), includingPropertiesForKeys: nil)
                
                while let url = dirContents?.nextObject() as? URL {
                    
                    let name = String(url.lastPathComponent)
                    let folderList = ["audio", "elements", "environments", "frames", "jobs", "palette-library"]
                    if folderList.contains(where: { name.contains($0) }) {
                        dirContents!.skipDescendants()
                    }
                    
                    if name.hasSuffix(".xstage") {
                        xsFile = XSFile()
                        xsFile.id = rowsNum
                        xsFile.fileDirPath = url.deletingLastPathComponent().relativePath
                        xsFile.fileURL = url.path
                        xsFile.fileName = String(url.lastPathComponent.dropLast(7))
                        xsFile.setData(filename: url.path)

                        let eName = "K" + xsFile.fileName.suffix(2)
                        xsFile.exportFileName = String(eName)

                        if(!defaultExportURL.isEmpty)
                        {
                            xsFile.exportFilePath = defaultExportURL
                        }

                        xsFiles.append(xsFile)

                        rowsNum += 1

                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }

                        print(url.path)
                    }
                }
            }
        } else {
            return
        }
    }
    
    @IBAction func setDefaultExportDir(_ sender: Any) {
        let openPanel = NSOpenPanel();
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        if (openPanel.runModal() == NSApplication.ModalResponse.OK) {
            let result = openPanel.url
            if (result != nil)
            {
                defaultExportURL = result!.path
                defaultExportDirTxtField.stringValue = defaultExportURL
                
            }
        } else {
            return
        }
    }
    
    @objc private func onItemClicked()
    {
        if(tableView.clickedColumn == 3) {
            setExportDir(id: tableView.clickedRow)
        }
        else if(tableView.clickedColumn == 4) {
            tableClickedRow = tableView.clickedRow
        }
        
        //        print("row \(tableView.clickedRow), col \(tableView.clickedColumn) clicked")
    }
    
    func setExportDir(id: Int)
    {
        let rowId = id
        let openPanel = NSOpenPanel();
        
        openPanel.title = "Choose a dir";
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        if (openPanel.runModal() == NSApplication.ModalResponse.OK) {
            let result = openPanel.url
            if (result != nil)
            {
                xsFiles.filter({$0.id == rowId}).first?.exportFilePath = result!.path
                tableView.reloadData()
                
                defaultExportURL = result!.path
                
//                print("Export render path - ", xsFiles.map{$0.exportFilePath}[tableClickedRow])
            }
        } else {
            return
        }
    }
}

// MARK: - Extensions
extension ViewController:NSTableViewDataSource
{
    func numberOfRows(in tableView: NSTableView) -> Int {
        return rowsNum
    }
}

extension ViewController:NSTableViewDelegate
{
    fileprivate enum CellIdentifiers
    {
        static let FileCell = "FileCellID"
        static let CharCell = "CharacterCellID"
        static let SettingsCell = "SettingsCellID"
        static let OutputCell = "OutputCellID"
        static let OutputNameCell = "OutputNameCellID"
        static let RenderCell = "RenderButtonCellID"
        static let RemoveCell = "RemoveButtonCellID"
    }
    
    func tableView(_ tableView:NSTableView, viewFor tableColumn:NSTableColumn?, row: Int) -> NSView?
    {
        var text: String = ""
        var cellIdentifier: String = ""
        
        if tableColumn == tableView.tableColumns[0]
        {
            text = xsFiles.map{$0.fileName}[row]
            cellIdentifier = CellIdentifiers.FileCell
        }
        else if tableColumn == tableView.tableColumns[1]
        {
            cellIdentifier = CellIdentifiers.CharCell
        }
        else if tableColumn == tableView.tableColumns[2]
        {
            cellIdentifier = CellIdentifiers.SettingsCell
        }
        else if tableColumn == tableView.tableColumns[3]
        {
            text = xsFiles.map{$0.exportFilePath}[row]
            cellIdentifier = CellIdentifiers.OutputCell
        }
        else if tableColumn == tableView.tableColumns[4]
        {
            text = xsFiles.map{$0.exportFileName}[row]
            cellIdentifier = CellIdentifiers.OutputNameCell
        }
        else if tableColumn == tableView.tableColumns[5]
        {
            cellIdentifier = CellIdentifiers.RenderCell
        }
        else if tableColumn == tableView.tableColumns[6]
        {
            cellIdentifier = CellIdentifiers.RemoveCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
//        print("Table reloaded")
//            updateStatus()
    }
    
    //override default cell color
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return MyRowView()
    }
    
}

//override default cell color
class MyRowView: NSTableRowView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if isSelected == true {
            NSColor.lightGray.set()
            dirtyRect.fill()
        }
    }
}
