import SwiftUI

struct PracticeRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bpm = 96
    @State private var resultType: PracticeResultType = .stable
    @State private var durationMinutes = 10
    @State private var memo = ""
    @State private var linkLatestRecording = true

    var body: some View {
        NavigationStack {
            Form {
                Section("達成 BPM") {
                    Stepper(value: $bpm, in: 40 ... 240) {
                        Text("\(bpm) BPM")
                    }
                }

                Section("結果") {
                    Picker("結果", selection: $resultType) {
                        ForEach(PracticeResultType.allCases) { result in
                            Text(result.label).tag(result)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("練習時間") {
                    Stepper(value: $durationMinutes, in: 1 ... 120) {
                        Text("\(durationMinutes) 分")
                    }
                    Toggle("最新録音を紐付ける", isOn: $linkLatestRecording)
                }

                Section("メモ") {
                    TextField("メモ", text: $memo, axis: .vertical)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.screenGradient)
            .navigationTitle("練習記録")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        dismiss()
                    }
                }
            }
        }
    }
}
