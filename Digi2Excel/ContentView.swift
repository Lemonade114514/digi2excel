import SwiftUI
import AppKit

struct ContentView: View {
    @State private var rawDataURL: URL?
    @State private var headersURL: URL?
    @State private var cmText: String = UserDefaults.standard.string(forKey: "cmValue") ?? ""
    @State private var headersPath: String = UserDefaults.standard.string(forKey: "headersPath") ?? ""
    @State private var logs: [LogEntry] = []
    @State private var processedData: [[String]]?
    @State private var isProcessing: Bool = false
    @State private var statusMessage: String = "就绪"
    @State private var statusColor: Color = .gray
    @State private var showGuide: Bool = false
    
    private let cmOptions = ["Mflex", "Flexium", "QSMC", "FXCD", "WTKM"]
    
    // macOS 10.15-safe background colors
    private var controlBg: Color { systemColor(NSColor.windowBackgroundColor) }
    private var textBg: Color { systemColor(NSColor.textBackgroundColor) }
    
    var body: some View {
        VStack(spacing: 0) {
            controlBar
            Divider()
            logArea
            Divider()
            statusBar
        }
        .frame(minWidth: 700, minHeight: 450)
        .sheet(isPresented: $showGuide) { guideSheet }
        .onAppear {
            if !headersPath.isEmpty {
                headersURL = URL(fileURLWithPath: headersPath)
            }
        }
    }
    
    // MARK: - Control Bar
    
    private var controlBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("🍋‍🟩").font(.headline)
                    Text("Digi2Excel").font(.headline).foregroundColor(.accentColor)
                }
                Divider().frame(height: 20)
                fileButton(label: "原始数据", url: rawDataURL) {
                    pickFile { rawDataURL = $0 }
                }
                fileButton(label: "标签数据", url: headersURL) {
                    pickFile { url in
                        headersURL = url
                        headersPath = url.path
                        UserDefaults.standard.set(url.path, forKey: "headersPath")
                    }
                }
                Divider().frame(height: 20)
                HStack(spacing: 4) {
                    Text("CM").font(.system(size: 13, weight: .semibold)).foregroundColor(.primary)
                    Picker("", selection: $cmText) {
                        ForEach(cmOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                        if !cmText.isEmpty && !cmOptions.contains(cmText) {
                            Text(cmText).tag(cmText)
                        }
                    }
                    .frame(width: 100)
                    TextField("自定义", text: $cmText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                Spacer()
                Button(action: { showGuide = true }) {
                    Text("?").font(.headline)
                }
            }
            
            HStack(spacing: 8) {
                Button(action: process) {
                    HStack(spacing: 4) {
                        if isProcessing {
                            ProgressIndicator()
                        } else {
                            Text("▶︎")
                        }
                        Text(isProcessing ? "处理中..." : "开始处理")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(rawDataURL == nil || headersURL == nil || cmText.isEmpty || isProcessing)
                
                Button(action: saveResult) {
                    Text("📥 导出 CSV")
                }
                .disabled(processedData == nil)
                
                Button(action: clearAll) {
                    Text("🗑 清除")
                }
                
                Spacer()
                if let data = processedData {
                    Text("输出 \(data.count)×\(data.first?.count ?? 0)")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(controlBg)
    }
    
    // MARK: - Log Area
    
    private var logArea: some View {
        Group {
            if logs.isEmpty {
                VStack(spacing: 8) {
                    Text("📋").font(.system(size: 36))
                    Text("选择文件并点击「开始处理」")
                        .font(.callout).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(logs) { log in logRow(log) }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(textBg)
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle().fill(statusColor).frame(width: 7, height: 7)
            Text(statusMessage).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text("Digi2Excel v0.9").font(.caption).foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(controlBg)
    }
    
    // MARK: - Guide Sheet
    
    private var guideSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("使用说明").font(.title).fontWeight(.semibold)
            GuideRow(number: "1", text: "点击「原始数据」选择 rawData.csv")
            GuideRow(number: "2", text: "点击「标签数据」选择 Headers.csv（路径会自动保存）")
            GuideRow(number: "3", text: "选择或输入 CM 工厂编号（会自动保存）")
            GuideRow(number: "4", text: "点击「开始处理」")
            GuideRow(number: "5", text: "完成后点击「导出 CSV」保存")
            Divider()
            Text("Headers.csv 定义需要提取的测试项名称").font(.caption).foregroundColor(.secondary)
            Text("rawData.csv 应为 osens digitalMic 导出的数据").font(.caption).foregroundColor(.secondary)
            HStack { Spacer(); Button("知道了") { showGuide = false } }
        }
        .padding(20)
        .frame(width: 400)
    }
    
    // MARK: - Helpers
    
    private func fileButton(label: String, url: URL?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(url != nil ? "📄" : "📄")
                Text(url?.lastPathComponent ?? label)
                    .lineLimit(1).truncationMode(.middle)
            }
            .frame(maxWidth: 160)
        }
    }
    
    private func pickFile(callback: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.commaSeparatedText, .plainText]
        } else {
            panel.allowedFileTypes = ["csv", "txt"]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { callback(url) }
    }
    
    private func logRow(_ log: LogEntry) -> some View {
        let (emoji, textColor): (String, Color) = {
            switch log.type {
            case .info:    return ("ℹ️", .primary)
            case .warning: return ("⚠️", .orange)
            case .error:   return ("❌", .red)
            case .success: return ("✅", .green)
            }
        }()
        return HStack(alignment: .top, spacing: 5) {
            Text(emoji).font(.system(size: 11))
            Text(log.message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(textColor)
        }
    }
}

// MARK: - macOS 10.15 Compatible: NSProgressIndicator

struct ProgressIndicator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSProgressIndicator {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.controlSize = .small
        indicator.isIndeterminate = true
        indicator.startAnimation(nil)
        return indicator
    }
    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {}
}

// MARK: - Actions

extension ContentView {
    private func process() {
        guard let rawURL = rawDataURL, let headURL = headersURL else { return }
        UserDefaults.standard.set(cmText, forKey: "cmValue")
        isProcessing = true
        statusMessage = "处理中..."
        statusColor = .orange
        logs.append(LogEntry(message: "读取文件...", type: .info))
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let rawData = try CSVParser.parse(url: rawURL)
                let headersRaw = try CSVParser.parse(url: headURL)
                let headers = headersRaw.compactMap { row -> String? in
                    let name = row.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    return name.isEmpty ? nil : name
                }
                let (data, processLogs) = DataProcessor.process(rawData: rawData, headers: headers, cm: cmText)
                DispatchQueue.main.async {
                    logs.append(contentsOf: processLogs)
                    processedData = data
                    isProcessing = false
                    statusMessage = "处理完成"
                    statusColor = .green
                    logs.append(LogEntry(message: "处理完成 ✓", type: .success))
                }
            } catch {
                DispatchQueue.main.async {
                    logs.append(LogEntry(message: "错误: \(error.localizedDescription)", type: .error))
                    isProcessing = false
                    statusMessage = "处理失败"
                    statusColor = .red
                }
            }
        }
    }
    
    private func saveResult() {
        guard let data = processedData else { return }
        let panel = NSSavePanel()
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.commaSeparatedText]
        } else {
            panel.allowedFileTypes = ["csv"]
        }
        panel.nameFieldStringValue = DataProcessor.generateFilename(cm: cmText)
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try DataProcessor.toCSVString(data).write(to: url, atomically: true, encoding: .utf8)
                logs.append(LogEntry(message: "已保存: \(url.path)", type: .success))
                statusMessage = "已保存"; statusColor = .green
            } catch {
                logs.append(LogEntry(message: "保存失败: \(error.localizedDescription)", type: .error))
            }
        }
    }
    
    private func clearAll() {
        rawDataURL = nil
        headersURL = nil
        headersPath = ""
        UserDefaults.standard.removeObject(forKey: "headersPath")
        UserDefaults.standard.removeObject(forKey: "cmValue")
        cmText = ""
        logs.removeAll()
        processedData = nil
        statusMessage = "就绪"; statusColor = .gray
    }
}

struct GuideRow: View {
    let number: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number).font(.caption).fontWeight(.bold)
                .foregroundColor(.white).frame(width: 18, height: 18)
                .background(Circle().fill(Color.accentColor))
            Text(text).font(.callout)
        }
    }
}
