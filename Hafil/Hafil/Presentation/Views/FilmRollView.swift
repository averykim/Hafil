//
//  FilmRollView.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//
// gallery for developed photos
import SwiftUI

struct FilmRollView: View {

    //Two-way binding for Picker
    @Bindable var viewModel: FilmRollViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.completedRolls.isEmpty {
                    ContentUnavailableView("No developed film", systemImage: "film.stack", description: Text("Once you finish shooting all exposures on a roll, you can view and export them here."))
                } else {
                    rollListView
                }
            }
        }
    }

    private var rollListView: some View {
        List {
            ForEach(viewModel.completedRolls, id: \.id) { roll in
                Button {
                    viewModel.selectRoll(roll)
                } label: {
                    RollRowView(roll: roll)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteRoll(roll)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

//MARK: - ROll List View
private struct RollRowView: View {

    let roll: FilmRoll

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "film")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(roll.recipeName).font(.headline.monospaced())
                Text(roll.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(roll.capturedFrame) / \(roll.maxFrames)")
                    .font(.caption.monospaced().bold())
                Text("cuts")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

//MARK: - Roll Export Sheet
private struct RollExportSheet: View {

    @Bindable var viewModel: FilmRollViewModel
    let roll: FilmRoll

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                //Roll info
                VStack(spacing: 4) {
                    Text(roll.recipeName)
                        .font(.title3.monospaced().bold())
                    Text("\(roll.capturedFrame)shots · \(roll.capturedFrame / 2) Diptych")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                // Select Save Format (Diptych vs Single)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Save options")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Picker("Save options", selection: $viewModel.selectedExportFormat){
                        ForEach(PhotoExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Video clip export / share
                VStack(spacing: 12) {
                    if let videoURL = viewModel.exportedVideoURL {
                        ShareLink(item: videoURL) {
                            Label("Save / Share finished video", systemImage: "square.and.arrow.up")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    } else {
                        Button {
                            viewModel.exportVideo(for: roll)
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isExportingVideo {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "video.badge.plus")
                                }
                                Text(viewModel.isExportingVideo ? "Generating video..." : "Create full roll video (.mp4)")
                                    .font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isExportingVideo)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Export roll")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
