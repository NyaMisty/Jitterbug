//
// Copyright © 2021 osy. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

class HostFinder: NSObject {
    private let browser: NetServiceBrowser
    private let resolveTimeout = TimeInterval(30)
    
    public weak var delegate: HostFinderDelegate?
    
    override init() {
        self.browser = NetServiceBrowser()
        super.init()
        self.browser.includesPeerToPeer = true
        self.browser.delegate = self
    }
    
    func startSearch() {
        browser.searchForServices(ofType: "_apple-mobdev2._tcp.", inDomain: "local.")
    }
    
    func stopSearch() {
        browser.stop()
    }
}

extension HostFinder: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind: NetService, moreComing: Bool) {
        NSLog("[HostFinder] resolving host %@", didFind.hostName ?? "(unknown)")
        didFind.resolve(withTimeout: resolveTimeout)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove: NetService, moreComing: Bool) {
        NSLog("[HostFinder] removing %@", didRemove.hostName ?? "(unknown)")
        if let hostName = didRemove.hostName {
            delegate?.hostFinderRemoveHost(hostName)
        }
    }
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        NSLog("[HostFinder] starting search")
        delegate?.hostFinderWillStart()
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        NSLog("[HostFinder] stopping search")
        delegate?.hostFinderDidStop()
    }
}

extension HostFinder: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        NSLog("[HostFinder] resolved %@", sender.hostName ?? "(unknown)")
        guard let hostName = sender.hostName else {
            return
        }
        guard let address = sender.addresses?[0] else {
            delegate?.hostFinderError(NSLocalizedString("Failed to resolve \(hostName)", comment: "HostFinder"))
            return
        }
        delegate?.hostFinderNewHost(hostName, address: address)
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        let hostName = sender.hostName ?? "(unknown)"
        NSLog("[HostFinder] resolve failed for %@", hostName)
        let errorCode = errorDict[NetService.errorCode]!
        let errorDomain = errorDict[NetService.errorDomain]!
        let error = NSLocalizedString("Resolving \(hostName) failed with the error domain \(errorDomain), code \(errorCode)", comment: "HostFinder")
        delegate?.hostFinderError(error)
    }
}