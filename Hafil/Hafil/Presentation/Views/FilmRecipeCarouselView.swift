//
//  FilmRecipeCarouselView.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//
// For new roll

import SwiftUI

struct FilmRecipeCarouselView: View {
    //MARK: - Injected ViewModel  & Callback
    var viewModel: FilmRecipeCarouselViewModel
    let onLoadFilm: (FilmRoll) -> Void

    @State private var scrolledRecipeID: String?

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            //MARK: - Title
            VStack(spacing: 6) {
                Text("LOAD NEW FILM")
                    .font(.caption.monospaced().bold())
                    .tracking(2)
                    .foregroundStyle(.orange)

                Text("Select a film to load.")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("Once loaded, you cannot change the film until the roll is finished.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            // MARK: - Recipe Horizontal Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.availableRecipes) { recipe in
                        FilmCanisterCard(recipe: recipe, isSelected: viewModel.selectedRecipe == recipe)
                            .id(recipe.id)
                            .onTapGesture(perform: {
                                withAnimation(.snappy) {
                                    scrolledRecipeID = recipe.id
                                    viewModel.selectedRecipe(recipe)
                                } //animation
                            })//tap
                    } //foreach
                } //Hstack
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 48, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledRecipeID)
            .frame(height: 210)

            // MARK: - Select roll count (12 / 24 / 72)
            VStack(spacing: 10) {
                Text("ROLL CAPACITY")
                    .font(.caption2.monospaced().bold())
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 10) {
                    ForEach(RollCapacityOption.allCases) { option in
                        let isSelected = viewModel.selectedCapacity == option

                        Button {
                            withAnimation(.easeInOut(duration: 0.15), {
                                viewModel.selectedCapacity(option)
                            })
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(option.rawValue)").font(.headline.monospaced().bold())
                                Text("\(option.diptychCount) diptychs").font(.system(size:10, design: .monospaced)).opacity(0.8)
                            }
                            .foregroundStyle(isSelected ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.orange : Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            } //vstack
            .padding(.horizontal, 24)
        }

        // MARK: - Film Load Button
        Button {
            let newRoll = viewModel.loadFilmRoll()
            onLoadFilm(newRoll)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "film.fill")
                Text("\(viewModel.selectedRecipe.displayName) · \(viewModel.selectedCapacity.rawValue) shots loaded").font(.subheadline.bold())
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear(perform: {
            scrolledRecipeID = viewModel.selectedRecipe.id
        })
        .onChange(of: scrolledRecipeID, { _, newID in
            if let newID, let matched = viewModel.availableRecipes.first(where: { $0.id == newID }) {
                viewModel.selectedRecipe(matched)
            }
        })
        .sensoryFeedback(.selection, trigger: viewModel.selectedRecipe)
        .sensoryFeedback(.selection, trigger: viewModel.selectedCapacity)
    }//body
}

//MARK: - Film Card Subview
private struct FilmCanisterCard: View {
    let recipe: FilmRecipeOption
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ISO \(recipe.iso)")
                    .font(.caption2.monospaced().bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .backgroundStyle(.orange)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .orange : .white.opacity(0.3))
            }

            Spacer()

            Text(recipe.displayName)
                .font(.title2.monospaced().bold())
                .foregroundStyle(.white)

            Text(recipe.description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(2)
        }
        .padding(20)
        .frame(width: 240, height: 190)
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(Color(white: isSelected ? 0.16 : 0.1))
        )
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(isSelected ? Color.orange : Color.white.opacity(0.15), lineWidth: isSelected ? 2: 1))
        .scaleEffect(isSelected ? 1.0 : 0.94)
        .animation(.snappy, value: isSelected)
    }
}
