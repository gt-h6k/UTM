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

import SwiftUI

struct VMWizardOSWindowsView: View {
    @ObservedObject var wizardState: VMWizardState
    @State private var isFileImporterPresented: Bool = false
    @State private var useVhdx: Bool = false
    
    var body: some View {
#if os(macOS)
        Text("Windows")
            .font(.largeTitle)
#endif
        List {
            Section {
                Toggle("Import VHDX Image", isOn: $useVhdx)
                if useVhdx {
                    Link("Download Windows 11 for ARM64 Preview VHDX", destination: URL(string: "https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewARM64")!)
                } else {
                    Link("Generate Windows Installer ISO", destination: URL(string: "https://uupdump.net/")!)
                }
            } header: {
                Text("Image File Type")
            }
            .onAppear {
                // SwiftUI bug: on macOS 11, onAppear() is called every time the check box is clicked
                if #available(iOS 15, macOS 12, *) {
                    if wizardState.windowsBootVhdx != nil {
                        useVhdx = true
                    }
                }
            }
            
            Section {
                if useVhdx {
                    FileBrowseField(url: $wizardState.windowsBootVhdx, isFileImporterPresented: $isFileImporterPresented, hasClearButton: false)
                        .disabled(wizardState.isBusy)
                } else {
                    FileBrowseField(url: $wizardState.bootImageURL, isFileImporterPresented: $isFileImporterPresented, hasClearButton: false)
                        .disabled(wizardState.isBusy)
                }
                
                if wizardState.isBusy {
                    Spinner(size: .large)
                }
            } header: {
                if useVhdx {
                    Text("Boot VHDX Image")
                } else {
                    Text("Boot ISO Image")
                }
            }
            
            DetailedSection("", description: "Some older systems do not support UEFI boot, such as Windows 7 and below.") {
                Toggle("UEFI Boot", isOn: $wizardState.systemBootUefi)
            }
            
            // Disabled on iOS 14 due to a SwiftUI layout bug
            if #available(iOS 15, *) {
                DetailedSection("", description: "Download and mount the guest support package for Windows. This is required for some features including dynamic resolution and clipboard sharing.") {
                    Toggle("Install drivers and SPICE tools", isOn: $wizardState.isGuestToolsInstallRequested)
                }
            }
        }
        #if os(iOS)
        .navigationTitle(Text("Windows"))
        #endif
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.data], onCompletion: processImage)
    }
    
    private func processImage(_ result: Result<URL, Error>) {
        wizardState.busyWorkAsync {
            let url = try result.get()
            await MainActor.run {
                if useVhdx {
                    wizardState.windowsBootVhdx = url
                    wizardState.bootImageURL = nil
                    wizardState.isSkipBootImage = true
                } else {
                    wizardState.windowsBootVhdx = nil
                    wizardState.bootImageURL = url
                    wizardState.isSkipBootImage = false
                }
            }
        }
    }
}

struct VMWizardOSWindowsView_Previews: PreviewProvider {
    @StateObject static var wizardState = VMWizardState()
    
    static var previews: some View {
        VMWizardOSWindowsView(wizardState: wizardState)
    }
}
